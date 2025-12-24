import Foundation
import AVFoundation

enum VideoVariant {
    case hevc720
    case h264360
}

final class VideoCompressor {
    static func compress(inputURL: URL, variant: VideoVariant, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: inputURL)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(NSError(domain: "VideoCompressor", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track"])))
            return
        }
        let originalSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let absSize = CGSize(width: abs(originalSize.width), height: abs(originalSize.height))
        let targetH: CGFloat = variant == .hevc720 ? 720 : 360
        let aspect = absSize.width / max(absSize.height, 1)
        var targetW = floor(aspect * targetH)
        if Int(targetW) % 2 != 0 { targetW += 1 }
        let renderSize = CGSize(width: max(targetW, 2), height: max(targetH, 2))
        let composition = AVMutableVideoComposition()
        composition.renderSize = renderSize
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(videoTrack.preferredTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        let fileName = UUID().uuidString + ".mp4"
        let outURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: outURL.path) {
            try? FileManager.default.removeItem(at: outURL)
        }
        let compatible = AVAssetExportSession.exportPresets(compatibleWith: asset)
        var preset = AVAssetExportPreset1280x720
        if variant == .hevc720, compatible.contains(AVAssetExportPresetHEVCHighestQuality) {
            preset = AVAssetExportPresetHEVCHighestQuality
        } else if variant == .h264360 {
            preset = AVAssetExportPreset640x480
        }
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
