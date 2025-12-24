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
        let audioTrack = asset.tracks(withMediaType: .audio).first
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
        do {
            let reader = try AVAssetReader(asset: asset)
            let videoOutput = AVAssetReaderVideoCompositionOutput(videoTracks: [videoTrack], videoSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            ])
            videoOutput.videoComposition = composition
            videoOutput.alwaysCopiesSampleData = false
            reader.add(videoOutput)
            var audioOutput: AVAssetReaderTrackOutput?
            if let a = audioTrack {
                let out = AVAssetReaderTrackOutput(track: a, outputSettings: nil)
                if reader.canAdd(out) {
                    reader.add(out)
                    audioOutput = out
                }
            }
            let fileName = UUID().uuidString + ".mp4"
            let outURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: outURL.path) {
                try? FileManager.default.removeItem(at: outURL)
            }
            let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
            let hevcProfile = "HEVC_Main_AutoLevel"
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: variant == .hevc720 ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
                AVVideoWidthKey: Int(renderSize.width),
                AVVideoHeightKey: Int(renderSize.height),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: variant == .hevc720 ? 1_500_000 : 700_000,
                    AVVideoMaxKeyFrameIntervalKey: 90,
                    AVVideoProfileLevelKey: variant == .hevc720 ? hevcProfile : AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput.expectsMediaDataInRealTime = false
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: nil)
            writer.add(videoInput)
            var audioInput: AVAssetWriterInput?
            if audioTrack != nil {
                let audioSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVEncoderBitRateKey: 96_000,
                    AVNumberOfChannelsKey: 1,
                    AVSampleRateKey: 44_100
                ]
                let ai = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                ai.expectsMediaDataInRealTime = false
                if writer.canAdd(ai) { writer.add(ai); audioInput = ai }
            }
            if !reader.startReading() {
                completion(.failure(NSError(domain: "VideoCompressor", code: -3, userInfo: [NSLocalizedDescriptionKey: "No se pudo iniciar lectura"])))
                return
            }
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)
            let queue = DispatchQueue(label: "vc.write")
            let group = DispatchGroup()
            group.enter()
            videoInput.requestMediaDataWhenReady(on: queue) {
                while videoInput.isReadyForMoreMediaData {
                    if let sample = videoOutput.copyNextSampleBuffer() {
                        let pts = CMSampleBufferGetPresentationTimeStamp(sample)
                        if let pb = CMSampleBufferGetImageBuffer(sample) {
                            if adaptor.append(pb, withPresentationTime: pts) { } else { }
                        }
                    } else {
                        videoInput.markAsFinished()
                        break
                    }
                }
                if audioInput == nil { group.leave() }
            }
            if let ai = audioInput, let ao = audioOutput {
                group.enter()
                ai.requestMediaDataWhenReady(on: queue) {
                    while ai.isReadyForMoreMediaData {
                        if let sample = ao.copyNextSampleBuffer() {
                            ai.append(sample)
                        } else {
                            ai.markAsFinished()
                            break
                        }
                    }
                    group.leave()
                }
            }
            group.notify(queue: queue) {
                writer.finishWriting {
                    if writer.status == .completed {
                        completion(.success(outURL))
                    } else {
                        completion(.failure(writer.error ?? NSError(domain: "VideoCompressor", code: -2, userInfo: nil)))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
