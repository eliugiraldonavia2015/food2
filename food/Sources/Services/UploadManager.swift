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
    private var currentVideoDuration: Double = 60.0 // Valor por defecto seguro
    
    // Updated: 2026-02-06 (Force Refresh)
    
    // Pesos relativos para la barra de progreso
    private let compressionWeight = 0.4 // 40% del tiempo
    private let uploadWeight = 0.6      // 60% del tiempo
    
    private var compressionProgress: Double = 0.0
    private var uploadProgress: Double = 0.0
    
    // Simulación de Progreso (Smart Fake Adaptativo)
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
        
        // Obtener duración para estimación de progreso
        let asset = AVAsset(url: inputURL)
        Task {
            if let duration = try? await asset.load(.duration).seconds, duration > 0 {
                self.currentVideoDuration = duration
                print("⏱ [UploadManager] Duración detectada: \(Int(duration))s")
            }
        }
        
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
        
        // Iniciar simulación visual adaptativa
        startSimulation()
        
        Task {
            // 1. Esperar o recuperar resultado de compresión
            let videoToUpload = await compressionTask.value
            
            // Compresión terminada (real o simulada llegó al tope de su peso)
            self.compressionProgress = 1.0
            self.updateTotalProgress()
            
            // 2. Subida a Bunny
            self.statusMessage = "Subiendo video..."
            
            // Nueva estrategia de nombrado: {environment}_v_{ulid}
            // Ej: prod_v_01H8X7Z...
            let envPrefix = "prod" // Podrías cambiar esto a "dev" o leerlo de config
            let uniqueId = ULID.new().lowercased()
            let fileId = "\(envPrefix)_v_\(uniqueId)"
            
            let accessKey = "b88d331e-2e97-442c-ab81e2a15c30-d313-4fd2" // Hardcoded by user request for immediate fix
            
            guard !accessKey.isEmpty else {
                DispatchQueue.main.async { self.error = "Falta AccessKey"; self.stopSimulation(); self.isProcessing = false }
                return
            }
            
            BunnyUploader.upload(fileURL: videoToUpload, ulid: fileId, accessKey: accessKey, onProgress: { p in
                DispatchQueue.main.async {
                    self.uploadProgress = p
                    self.updateTotalProgress()
                }
            }) { result in
                DispatchQueue.main.async {
                    self.stopSimulation()
                    
                    switch result {
                    case .success(let videoUrl):
                        self.uploadProgress = 1.0
                        self.updateTotalProgress()
                        
                        // Generar y subir thumbnail
                        self.handleThumbnail(videoURL: videoToUpload, ulid: fileId, accessKey: accessKey) { thumbUrl in
                            Task {
                                let asset = AVAsset(url: videoToUpload)
                                var width: Int? = nil
                                var height: Int? = nil
                                var orientation: String = "portrait" // Default
                                
                                if let track = try? await asset.loadTracks(withMediaType: .video).first {
                                    let size = try? await track.load(.naturalSize)
                                    // Considerar transform para dimensiones visuales
                                    // Pero para metadatos de archivo, a veces queremos lo físico. 
                                    // Guardemos lo visual (render size) que es lo que importa al player.
                                    let t = try? await track.load(.preferredTransform)
                                    let transform = t ?? .identity
                                    let s = size ?? .zero
                                    let isPortrait = abs(transform.b) == 1.0 && abs(transform.c) == 1.0
                                    width = isPortrait ? Int(s.height) : Int(s.width)
                                    height = isPortrait ? Int(s.width) : Int(s.height)
                                    
                                    // Determinar etiqueta de orientación
                                    if let w = width, let h = height {
                                        if w > h { orientation = "landscape" }
                                        else if w < h { orientation = "portrait" }
                                        else { orientation = "square" }
                                    }
                                }
                                
                                // Guardar en Firestore con dimensiones y orientación
                                self.saveToFirestore(
                                    fileId: fileId,
                                    title: title,
                                    description: description,
                                    videoUrl: videoUrl.absoluteString,
                                    thumbnailUrl: thumbUrl?.absoluteString ?? "",
                                    width: width,
                                    height: height,
                                    orientation: orientation
                                )
                            }
                        }
                        
                    case .failure(let err):
                        self.error = "Error: \(err.localizedDescription)"
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    private func saveToFirestore(fileId: String, title: String, description: String, videoUrl: String, thumbnailUrl: String, width: Int? = nil, height: Int? = nil, orientation: String? = nil) {
        guard let userId = AuthService.shared.user?.uid else {
            self.error = "Usuario no autenticado"
            self.isProcessing = false
            return
        }
        
        let newVideo = Video(
            id: fileId,
            userId: userId,
            title: title,
            description: description,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
            duration: self.currentVideoDuration,
            width: width,
            height: height,
            orientation: orientation
        )
        
        DatabaseService.shared.createVideoDocument(video: newVideo) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = "Error guardando datos: \(error.localizedDescription)"
                    self.isProcessing = false
                } else {
                    self.statusMessage = "¡Publicado!"
                    self.isCompleted = true
                    self.progress = 1.0
                    
                    // Ocultar overlay después de unos segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    private func startSimulation() {
        stopSimulation()
        simulatedProgress = 0.0
        
        // Cálculo de Tiempo Estimado Total (Compresión + Subida)
        // Estimamos: Compresión = 50% de duración real, Subida = 20% de duración real
        // Ejemplo: Video 60s -> Estimado 30s + 12s = 42s totales.
        let estimatedTotalSeconds = max(currentVideoDuration * 0.7, 5.0) // Mínimo 5s
        
        // Queremos llegar al 99% en ese tiempo estimado
        // Incremento por segundo = 0.99 / estimatedTotalSeconds
        // El timer corre cada 0.1s para suavidad
        let updateInterval = 0.1
        let incrementPerTick = (0.99 / estimatedTotalSeconds) * updateInterval
        
        print("⏳ [UploadManager] Simulación iniciada. Duración Video: \(Int(currentVideoDuration))s. ETA: \(Int(estimatedTotalSeconds))s")
        
        DispatchQueue.main.async {
            self.progressTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                // Si aún no llegamos al tope de simulación (99%)
                if self.simulatedProgress < 0.99 {
                    // Factor de desaceleración al acercarse al final (Easing Out)
                    // Si estamos cerca del 99%, avanzamos más lento
                    let remaining = 0.99 - self.simulatedProgress
                    let factor = remaining < 0.1 ? 0.5 : 1.0
                    
                    self.simulatedProgress += (incrementPerTick * factor)
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
    
    private func handleThumbnail(videoURL: URL, ulid: String, accessKey: String, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: videoURL)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true

            guard let cgImage = try? gen.copyCGImage(at: CMTime.zero, actualTime: nil) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let uiImage = UIImage(cgImage: cgImage)
            BunnyUploader.uploadThumbnail(image: uiImage, ulid: ulid, accessKey: accessKey) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url): completion(url)
                    case .failure: completion(nil)
                    }
                }
            }
        }
    }
}
