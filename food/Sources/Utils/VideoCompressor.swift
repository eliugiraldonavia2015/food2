import Foundation
import AVFoundation

enum VideoVariant {
    case low         // Para videos < 15MB: Calidad Baja/Media (aprox 360p)
    case sd_480p     // Para videos 15-25MB: Calidad SD (640x480)
    case qhd_540p    // Para videos 25-40MB: Calidad qHD (960x540) - Balance ideal móvil
    case hd_720p_hevc // Para videos > 40MB: Calidad HD (1280x720) usando HEVC
}

final class VideoCompressor {
    
    // Configuración Maestra de Salida (Canvas TikTok)
    static let masterWidth: CGFloat = 720
    static let masterHeight: CGFloat = 1280
    static let masterSize = CGSize(width: masterWidth, height: masterHeight)
    
    static func compress(inputURL: URL, variant: VideoVariant, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: inputURL)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(NSError(domain: "VideoCompressor", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track"])))
            return
        }
        
        // 1. Analizar geometría original
        let transform = videoTrack.preferredTransform
        let originalSize = videoTrack.naturalSize.applying(transform)
        let absSize = CGSize(width: abs(originalSize.width), height: abs(originalSize.height))
        
        // 2. Crear Composición "Smart Normalize"
        let composition = AVMutableVideoComposition()
        composition.renderSize = masterSize // SIEMPRE 720x1280 (9:16)
        composition.frameDuration = CMTime(value: 1, timescale: 30) // 30 FPS
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // 3. Calcular Transformación Inteligente (Fill vs Fit)
        let finalTransform = calculateSmartTransform(
            sourceSize: absSize,
            targetSize: masterSize,
            originalTransform: transform
        )
        
        layerInstruction.setTransform(finalTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        
        // 4. Exportar
        export(asset: asset, composition: composition, completion: completion)
    }
    
    // Lógica "TikTok":
    // - Si es vertical (9:16 aprox) -> Aspect FILL (Llenar pantalla, recortar bordes mínimos)
    // - Si es cuadrado/landscape -> Aspect FIT (Encajar completo, rellenar con negro/blur)
    private static func calculateSmartTransform(sourceSize: CGSize, targetSize: CGSize, originalTransform: CGAffineTransform) -> CGAffineTransform {
        let sourceRatio = sourceSize.width / sourceSize.height
        let targetRatio = targetSize.width / targetSize.height
        
        let isVerticalSource = sourceRatio < 0.8 // Algo más vertical que cuadrado (ej: 4:5, 9:16)
        
        var scaleFactor: CGFloat
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        
        if isVerticalSource {
            // Estrategia: ASPECT FILL (Zoom para llenar)
            // Se calcula la escala necesaria para cubrir la dimensión más grande
            let widthRatio = targetSize.width / sourceSize.width
            let heightRatio = targetSize.height / sourceSize.height
            
            // Usamos max() para que ambos lados cubran el target (crop)
            scaleFactor = max(widthRatio, heightRatio)
            
            let scaledWidth = sourceSize.width * scaleFactor
            let scaledHeight = sourceSize.height * scaleFactor
            
            // Centrar
            xOffset = (targetSize.width - scaledWidth) / 2
            yOffset = (targetSize.height - scaledHeight) / 2
            
        } else {
            // Estrategia: ASPECT FIT (Encajar completo con bandas negras)
            // Usamos min() para que el video quepa entero
            let widthRatio = targetSize.width / sourceSize.width
            let heightRatio = targetSize.height / sourceSize.height
            
            scaleFactor = min(widthRatio, heightRatio)
            
            let scaledWidth = sourceSize.width * scaleFactor
            let scaledHeight = sourceSize.height * scaleFactor
            
            // Centrar en el canvas negro
            xOffset = (targetSize.width - scaledWidth) / 2
            yOffset = (targetSize.height - scaledHeight) / 2
        }
        
        // Combinar transformaciones:
        // 1. Aplicar la rotación original del video (si estaba de lado)
        // 2. Escalar
        // 3. Mover al centro
        
        // Nota: El orden de multiplicación de matrices en CoreGraphics es inverso al intuitivo.
        // T = Translation * Scale * OriginalRotation
        // Pero primero debemos corregir el origen del video original si tiene rotación.
        
        // Simplificación robusta:
        // Usamos la transformación base para corregir orientación y origen al (0,0) visual
        // Luego aplicamos nuestro Scale y Translate sobre eso.
        
        let finalTransform = originalTransform
            .concatenating(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
            .concatenating(CGAffineTransform(translationX: xOffset, y: yOffset))
            
        return finalTransform
    }
    
    private static func export(asset: AVAsset, composition: AVMutableVideoComposition, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileName = UUID().uuidString + ".mp4"
        let outURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: outURL.path) {
            try? FileManager.default.removeItem(at: outURL)
        }
        
        // Usamos un preset HD genérico porque el tamaño real lo define la composición
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
            completion(.failure(NSError(domain: "VideoCompressor", code: -4, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear ExportSession"])))
            return
        }
        
        exporter.outputURL = outURL
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = composition
        
        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                completion(.success(outURL))
            case .failed, .cancelled:
                completion(.failure(exporter.error ?? NSError(domain: "VideoCompressor", code: -5, userInfo: [NSLocalizedDescriptionKey: "Export fallido"])))
            default:
                break
            }
        }
    }
}
