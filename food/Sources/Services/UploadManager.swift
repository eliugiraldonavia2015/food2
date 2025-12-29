import SwiftUI
import Combine
import AVFoundation
import CoreMedia

final class UploadManager: ObservableObject {
    static let shared = UploadManager()
    
    // Estado Visible (Overlay)
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var isCompleted: Bool = false
    @Published var error: String? = nil
    
    // Estado Interno (Background Preparation)
    private var pendingCompressionTask: Task<URL, Never>?
    private var preparedVideoURL: URL?
    
    // Pesos relativos para la barra de progreso
    private let compressionWeight = 0.4 // 40% del tiempo
    private let uploadWeight = 0.6      // 60% del tiempo
    
    private var compressionProgress: Double = 0.0
    private var uploadProgress: Double = 0.0
    
    // Simulación de Progreso (Smart Fake)
    private var progressTimer: Timer?
    private var simulatedProgress: Double = 0.0
    
    private init() {}
    
    /// Inicia la optimización en background silenciosamente (al seleccionar el video)
    func prepareVideo(inputURL: URL) {
        // Cancelar tarea anterior si existía
        pendingCompressionTask?.cancel()
        preparedVideoURL = nil
        compressionProgress = 0.0
        
        print("🎬 [UploadManager] Iniciando preparación en background...")
        
        pendingCompressionTask = Task {
            let optimalLayer = await ProVideoCompressor.calculateOptimalLayer(for: inputURL)
            
            switch optimalLayer {
            case .passThrough:
                print("⚡️ [UploadManager] Video eficiente. Preparación lista.")
                self.compressionProgress = 1.0
                return inputURL
                
            case .custom(let config):
                print("🔄 [UploadManager] Comprimiendo a \(config.height)p en background...")
                var resultURL = inputURL
                
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    ProVideoCompressor.compress(inputURL: inputURL, level: optimalLayer, onProgress: { p in
                        self.compressionProgress = p
                        // No actualizamos UI aquí (silencioso)
                    }) { result in
                        switch result {
                        case .success(let url):
                            print("✅ [UploadManager] Compresión background terminada.")
                            resultURL = url
                        case .failure(let error):
                            print("⚠️ [UploadManager] Falló compresión background: \(error)")
                            resultURL = inputURL
                        }
                        continuation.resume()
                    }
                }
                return resultURL
            }
        }
    }
    
    /// Inicia la subida visible (al tocar Publicar)
    func commitUpload(title: String, description: String) {
        guard let compressionTask = pendingCompressionTask else {
            print("❌ [UploadManager] No hay video preparado.")
            return
        }
        
        resetState()
        self.isProcessing = true
        self.statusMessage = "Procesando video..."
        
        // Iniciar simulación visual para evitar que se quede en 0%
        startSimulation()
        
        Task {
            // 1. Esperar o recuperar resultado de compresión
            let videoToUpload = await compressionTask.value
            
            // Compresión terminada (real o simulada llegó al tope de su peso)
            self.compressionProgress = 1.0
            self.updateTotalProgress()
            
            // 2. Subida a Bunny
            self.statusMessage = "Subiendo video..."
            let ulid = UUID().uuidString.lowercased()
            let accessKey = ProcessInfo.processInfo.environment["BUNNY_STORAGE_ACCESS_KEY"] ?? ""
            
            guard !accessKey.isEmpty else {
                DispatchQueue.main.async { self.error = "Falta AccessKey"; self.stopSimulation(); self.isProcessing = false }
                return
            }
            
            BunnyUploader.upload(fileURL: videoToUpload, ulid: ulid, accessKey: accessKey, onProgress: { p in
                DispatchQueue.main.async {
                    self.uploadProgress = p
                    self.updateTotalProgress()
                }
            }) { result in
                DispatchQueue.main.async {
                    self.stopSimulation()
                    
                    switch result {
                    case .success(_):
                        self.uploadProgress = 1.0
                        self.updateTotalProgress()
                        self.statusMessage = "¡Publicado!"
                        self.isCompleted = true
                        
                        // Forzar 100% visual
                        self.progress = 1.0
                        
                        // Generar y subir thumbnail
                        self.handleThumbnail(videoURL: videoToUpload, ulid: ulid, accessKey: accessKey)
                        
                        // Ocultar overlay después de unos segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.isProcessing = false
                        }
                        
                    case .failure(let err):
                        self.error = "Error: \(err.localizedDescription)"
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    private func startSimulation() {
        stopSimulation()
        simulatedProgress = 0.0
        // Timer en hilo principal
        DispatchQueue.main.async {
            self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                // Incremento logarítmico simulado hasta 85%
                if self.simulatedProgress < 0.85 {
                    // Más rápido al principio, más lento al final
                    let increment = (0.9 - self.simulatedProgress) * 0.05
                    self.simulatedProgress += increment
                    self.updateTotalProgress()
                }
            }
        }
    }
    
    private func stopSimulation() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateTotalProgress() {
        // Cálculo Real
        let realTotal = (compressionProgress * compressionWeight) + (uploadProgress * uploadWeight)
        
        // Híbrido: El mayor entre Real y Simulado
        // Esto garantiza que nunca retroceda y que siempre avance algo
        let hybridProgress = max(realTotal, simulatedProgress)
        
        // Cap en 99% hasta que isCompleted sea true
        if isCompleted {
            self.progress = 1.0
        } else {
            self.progress = min(hybridProgress, 0.99)
        }
    }
    
    private func resetState() {
        isProcessing = false
        progress = 0.0
        statusMessage = ""
        isCompleted = false
        error = nil
        uploadProgress = 0.0
        stopSimulation()
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
