import SwiftUI
import Combine
import AVFoundation
import CoreMedia

final class UploadManager: ObservableObject {
    static let shared = UploadManager()
    
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var isCompleted: Bool = false
    @Published var error: String? = nil
    
    // Pesos relativos para la barra de progreso
    private let compressionWeight = 0.4 // 40% del tiempo
    private let uploadWeight = 0.6      // 60% del tiempo
    
    private var compressionProgress: Double = 0.0
    private var uploadProgress: Double = 0.0
    
    private init() {}
    
    func startUploadProcess(inputURL: URL, title: String, description: String) {
        resetState()
        self.isProcessing = true
        self.statusMessage = "Analizando video..."
        
        Task {
            // 1. Análisis y Compresión
            let optimalLayer = await ProVideoCompressor.calculateOptimalLayer(for: inputURL)
            
            var videoToUpload: URL
            
            switch optimalLayer {
            case .passThrough:
                print("⚡️ [UploadManager] Video eficiente. Saltando compresión.")
                videoToUpload = inputURL
                self.compressionProgress = 1.0
                self.updateTotalProgress()
                
            case .custom(let config):
                self.statusMessage = "Optimizando video (\(config.height)p)..."
                
                // Variable local para capturar el resultado de la continuación
                var compressedURL: URL = inputURL
                
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    ProVideoCompressor.compress(inputURL: inputURL, level: optimalLayer, onProgress: { p in
                        DispatchQueue.main.async {
                            self.compressionProgress = p
                            self.updateTotalProgress()
                        }
                    }) { result in
                        switch result {
                        case .success(let url):
                            compressedURL = url
                        case .failure(let error):
                            print("⚠️ Falló compresión, usando original: \(error)")
                            compressedURL = inputURL
                        }
                        continuation.resume()
                    }
                }
                videoToUpload = compressedURL
            }
            
            // 2. Subida a Bunny
            self.statusMessage = "Subiendo a la nube..."
            let ulid = UUID().uuidString.lowercased()
            let accessKey = ProcessInfo.processInfo.environment["BUNNY_STORAGE_ACCESS_KEY"] ?? ""
            
            guard !accessKey.isEmpty else {
                DispatchQueue.main.async { self.error = "Falta AccessKey"; self.isProcessing = false }
                return
            }
            
            BunnyUploader.upload(fileURL: videoToUpload, ulid: ulid, accessKey: accessKey, onProgress: { p in
                DispatchQueue.main.async {
                    self.uploadProgress = p
                    self.updateTotalProgress()
                }
            }) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self.uploadProgress = 1.0
                        self.updateTotalProgress()
                        self.statusMessage = "¡Publicado con éxito!"
                        self.isCompleted = true
                        
                        // Generar y subir thumbnail (background, no bloqueante)
                        self.handleThumbnail(videoURL: videoToUpload, ulid: ulid, accessKey: accessKey)
                        
                        // Ocultar overlay después de unos segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.isProcessing = false
                        }
                        
                    case .failure(let err):
                        self.error = "Error al subir: \(err.localizedDescription)"
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    private func updateTotalProgress() {
        let total = (compressionProgress * compressionWeight) + (uploadProgress * uploadWeight)
        self.progress = min(total, 0.99) // 1.0 solo al finalizar
    }
    
    private func resetState() {
        isProcessing = false
        progress = 0.0
        statusMessage = ""
        isCompleted = false
        error = nil
        compressionProgress = 0.0
        uploadProgress = 0.0
    }
    
    private func handleThumbnail(videoURL: URL, ulid: String, accessKey: String) {
        let asset = AVAsset(url: videoURL)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        if let cgImage = try? gen.copyCGImage(at: CMTime.zero, actualTime: nil) {
            let uiImage = UIImage(cgImage: cgImage)
            BunnyUploader.uploadThumbnail(image: uiImage, ulid: ulid, accessKey: accessKey) { _ in }
        }
    }
}
