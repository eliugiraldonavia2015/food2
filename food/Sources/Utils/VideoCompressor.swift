import Foundation
import AVFoundation

enum VideoVariant {
    case low         // Para videos < 15MB: Calidad Baja/Media (aprox 360p)
    case sd_480p     // Para videos 15-25MB: Calidad SD (640x480)
    case qhd_540p    // Para videos 25-40MB: Calidad qHD (960x540) - Balance ideal móvil
    case hd_720p_hevc // Para videos > 40MB: Calidad HD (1280x720) usando HEVC
}

final class VideoCompressor {
    static func compress(inputURL: URL, variant: VideoVariant, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: inputURL)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(NSError(domain: "VideoCompressor", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track"])))
            return
        }
        
        // Determinar altura objetivo según variante
        let targetH: CGFloat
        switch variant {
        case .low: targetH = 360
        case .sd_480p: targetH = 480
        case .qhd_540p: targetH = 540
        case .hd_720p_hevc: targetH = 720
        }
        
        // Calcular dimensiones manteniendo Aspect Ratio
        let originalSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let absSize = CGSize(width: abs(originalSize.width), height: abs(originalSize.height))
        let aspect = absSize.width / max(absSize.height, 1)
        var targetW = floor(aspect * targetH)
        if Int(targetW) % 2 != 0 { targetW += 1 } // Asegurar paridad
        let renderSize = CGSize(width: max(targetW, 2), height: max(targetH, 2))
        
        // Configurar composición de video (Scaling)
        let composition = AVMutableVideoComposition()
        composition.renderSize = renderSize
        composition.frameDuration = CMTime(value: 1, timescale: 30) // 30 FPS
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(videoTrack.preferredTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        
        // Preparar archivo de salida
        let fileName = UUID().uuidString + ".mp4"
        let outURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: outURL.path) {
            try? FileManager.default.removeItem(at: outURL)
        }
        
        // Seleccionar Preset según variante
        let compatible = AVAssetExportSession.exportPresets(compatibleWith: asset)
        var preset: String = AVAssetExportPresetMediumQuality // Default seguro
        
        switch variant {
        case .low:
            // LowQuality suele ser 144p-240p. Medium es aprox 360p-480p.
            // Para "Mini" queremos algo mejor que pixelado pero ligero.
            if compatible.contains(AVAssetExportPresetMediumQuality) {
                preset = AVAssetExportPresetMediumQuality
            } else {
                preset = AVAssetExportPresetLowQuality
            }
            
        case .sd_480p:
            if compatible.contains(AVAssetExportPreset640x480) {
                preset = AVAssetExportPreset640x480
            }
            
        case .qhd_540p:
            if compatible.contains(AVAssetExportPreset960x540) {
                preset = AVAssetExportPreset960x540
            } else if compatible.contains(AVAssetExportPresetMediumQuality) {
                preset = AVAssetExportPresetMediumQuality
            }
            
        case .hd_720p_hevc:
            // Intentar usar HEVC 720p explícitamente si existe (iOS 11+)
            let hevc720 = "AVAssetExportPresetHEVC1280x720"
            if compatible.contains(hevc720) {
                preset = hevc720
            } else if compatible.contains(AVAssetExportPresetHEVC1920x1080) {
                // Si solo hay 1080p HEVC, es mejor bajar a 720p H.264 para no inflar tamaño
                preset = AVAssetExportPreset1280x720
            } else if compatible.contains(AVAssetExportPreset1280x720) {
                preset = AVAssetExportPreset1280x720
            }
        }
        
        print("🛠 [VideoCompressor] Usando preset: \(preset) para variante: \(variant)")
        
        guard let exporter = AVAssetExportSession(asset: asset, presetName: preset) else {
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
