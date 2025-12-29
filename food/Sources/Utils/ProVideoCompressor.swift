import Foundation
import AVFoundation
import UIKit
import VideoToolbox

/// Configuración de compresión calculada dinámicamente
struct ProCompressionConfig {
    let width: Int
    let height: Int
    let bitrate: Int
    let useHEVC: Bool
    let frameRate: Float
}

/// Niveles de calidad PRO Adaptativos
enum ProQualityLevel {
    case passThrough
    case custom(ProCompressionConfig)
}

final class ProVideoCompressor {
    
    /// Analiza el video y calcula la configuración óptima de compresión basándose en su densidad real.
    /// Retorna .passThrough si ya es eficiente, o .custom con los parámetros exactos para reducir peso.
    static func calculateOptimalLayer(for inputURL: URL) async -> ProQualityLevel {
        let asset = AVAsset(url: inputURL)
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else { return .passThrough }
        
        // 1. Obtener Datos Reales y Orientación
        let resources = try? inputURL.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Double(resources?.fileSize ?? 0)
        let duration = try? await asset.load(.duration).seconds ?? 0
        let transform = try await track.load(.preferredTransform) // Vital para orientación
        
        guard duration > 0, fileSize > 0,
              let size = try? await track.load(.naturalSize),
              let frameRate = try? await track.load(.nominalFrameRate) else {
            return .passThrough // No se pudo analizar
        }
        
        let realBitrate = (fileSize * 8) / duration
        
        // Detectar dimensiones visuales reales (teniendo en cuenta rotación)
        // Si el video está rotado 90° (vertical), width/height físicos están invertidos respecto a lo que ve el ojo.
        let isPortrait = abs(transform.b) == 1.0 && abs(transform.c) == 1.0
        let renderWidth = isPortrait ? Int(abs(size.height)) : Int(abs(size.width))
        let renderHeight = isPortrait ? Int(abs(size.width)) : Int(abs(size.height))
        let fps = frameRate > 0 ? frameRate : 30.0
        
        print("🔍 [Analyzer] Input: \(renderWidth)x\(renderHeight) (Portrait: \(isPortrait)) @ \(Int(realBitrate/1000)) kbps")
        
        // 2. Definir Límites de la App
        let MAX_BITRATE = 2_500_000.0 // 2.5 Mbps
        let MIN_BITRATE = 800_000.0   // 800 kbps
        let MAX_SIDE = 1280           // 720p (Lado más largo permitido)
        
        // 3. Calcular Target
        var targetBitrate = realBitrate
        var targetWidth = renderWidth
        var targetHeight = renderHeight
        
        // A) Ajuste de Resolución Inteligente (Anti-Distorsión)
        // Reducimos solo si el lado más largo excede 1280px (720p estándar)
        if max(renderWidth, renderHeight) > MAX_SIDE {
            let ratio = Double(min(renderWidth, renderHeight)) / Double(max(renderWidth, renderHeight))
            
            if renderWidth > renderHeight {
                // Horizontal (Landscape) -> Ancho manda
                targetWidth = MAX_SIDE
                targetHeight = Int(Double(MAX_SIDE) * ratio)
            } else {
                // Vertical (Portrait) -> Alto manda
                targetHeight = MAX_SIDE
                targetWidth = Int(Double(MAX_SIDE) * ratio)
            }
            
            // Asegurar paridad (FFmpeg/Codecs odian dimensiones impares)
            if targetWidth % 2 != 0 { targetWidth += 1 }
            if targetHeight % 2 != 0 { targetHeight += 1 }
            
            print("📉 [Analyzer] Downscaling Proporcional: \(renderWidth)x\(renderHeight) -> \(targetWidth)x\(targetHeight)")
            
            // Si bajamos resolución, bajamos bitrate proporcionalmente
            targetBitrate = targetBitrate * 0.6
        }
        
        // B) Ajuste de Bitrate (Eficiencia HEVC)
        // Factor de reducción agresivo para videos pesados
        if realBitrate > MAX_BITRATE {
            targetBitrate = MAX_BITRATE
            print("✂️ [Analyzer] Recortando bitrate excesivo a \(Int(targetBitrate/1000)) kbps")
        } else {
            // Si está dentro del rango, intentamos optimizar un 30% usando HEVC
            targetBitrate = targetBitrate * 0.7
        }
        
        // C) Suelo de Calidad
        if targetBitrate < MIN_BITRATE {
            targetBitrate = MIN_BITRATE
        }
        
        // 4. Decisión Final: ¿Vale la pena comprimir?
        // Si el bitrate objetivo es casi igual al original (y no cambiamos resolución), no vale la pena.
        let savingsRatio = 1.0 - (targetBitrate / realBitrate)
        
        // Si el ahorro estimado es < 10% y la resolución es la misma -> PassThrough
        if savingsRatio < 0.10 && targetWidth == renderWidth {
            print("✅ [Analyzer] Video eficiente (Ahorro marginal \(Int(savingsRatio*100))%). Pass-through.")
            return .passThrough
        }
        
        print("🚀 [Analyzer] Target: \(targetWidth)x\(targetHeight) @ \(Int(targetBitrate/1000)) kbps (HEVC). Ahorro est: \(Int(savingsRatio*100))%")
        
        let config = ProCompressionConfig(
            width: targetWidth,
            height: targetHeight,
            bitrate: Int(targetBitrate),
            useHEVC: true,
            frameRate: min(fps, 30.0) // Cap a 30fps
        )
        
        return .custom(config)
    }

    static func compress(inputURL: URL, level: ProQualityLevel, completion: @escaping (Result<URL, Error>) -> Void) {
        
        // Extraer configuración o salir
        let config: ProCompressionConfig
        switch level {
        case .passThrough:
            completion(.success(inputURL))
            return
        case .custom(let c):
            config = c
        }
        
        let asset = AVAsset(url: inputURL)
        
        Task {
            do {
                guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                    throw NSError(domain: "ProCompressor", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track"])
                }
                
                // --- 1. CONFIGURACIÓN DEL LECTOR (READER) ---
                let reader = try AVAssetReader(asset: asset)
                let readerOutputSettings: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                ]
                let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
                readerOutput.alwaysCopiesSampleData = false 
                
                if reader.canAdd(readerOutput) { reader.add(readerOutput) } else { throw NSError(domain: "ProCompressor", code: -2) }
                
                // Audio Reader
                var audioReaderOutput: AVAssetReaderTrackOutput?
                if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                    let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
                    if reader.canAdd(audioOutput) {
                        reader.add(audioOutput)
                        audioReaderOutput = audioOutput
                    }
                }
                
                // --- 2. CONFIGURACIÓN DEL ESCRITOR (WRITER) ---
                let outFilename = UUID().uuidString + ".mp4"
                let outURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outFilename)
                if FileManager.default.fileExists(atPath: outURL.path) { try FileManager.default.removeItem(at: outURL) }
                
                let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
                writer.shouldOptimizeForNetworkUse = true 
                
                // --- 3. CONFIGURACIÓN DINÁMICA (ADAPTATIVA) ---
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: config.useHEVC ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
                    AVVideoWidthKey: config.width,
                    AVVideoHeightKey: config.height,
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: config.bitrate,
                        AVVideoProfileLevelKey: config.useHEVC ? (kVTProfileLevel_HEVC_Main_AutoLevel as String) : AVVideoProfileLevelH264HighAutoLevel,
                        AVVideoMaxKeyFrameIntervalKey: 60,
                        AVVideoExpectedSourceFrameRateKey: config.frameRate
                    ]
                ]
                
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                writerInput.expectsMediaDataInRealTime = false 
                writerInput.transform = try await videoTrack.load(.preferredTransform)
                
                if writer.canAdd(writerInput) { writer.add(writerInput) }
                
                // Audio Writer
                var audioInput: AVAssetWriterInput?
                if audioReaderOutput != nil {
                    let audioSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVNumberOfChannelsKey: 2,
                        AVSampleRateKey: 44100,
                        AVEncoderBitRateKey: 128000
                    ]
                    let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                    aInput.expectsMediaDataInRealTime = false
                    if writer.canAdd(aInput) {
                        writer.add(aInput)
                        audioInput = aInput
                    }
                }
                
                // --- 4. INICIO DEL PROCESO ---
                if !reader.startReading() {
                    throw reader.error ?? NSError(domain: "ProCompressor", code: -6, userInfo: [NSLocalizedDescriptionKey: "StartReading falló"])
                }
                if !writer.startWriting() {
                     throw writer.error ?? NSError(domain: "ProCompressor", code: -7, userInfo: [NSLocalizedDescriptionKey: "StartWriting falló"])
                }
                writer.startSession(atSourceTime: .zero)
                
                let videoQueue = DispatchQueue(label: "videoQueue")
                let audioQueue = DispatchQueue(label: "audioQueue")
                let group = DispatchGroup()
                
                // Video Loop
                group.enter()
                writerInput.requestMediaDataWhenReady(on: videoQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if reader.status == .failed {
                            writerInput.markAsFinished()
                            group.leave()
                            return
                        }
                        
                        if let buffer = readerOutput.copyNextSampleBuffer() {
                            if writerInput.isReadyForMoreMediaData {
                                writerInput.append(buffer)
                            }
                        } else {
                            writerInput.markAsFinished()
                            group.leave()
                            break
                        }
                    }
                }
                
                // Audio Loop
                if let aInput = audioInput, let aOutput = audioReaderOutput {
                    group.enter()
                    aInput.requestMediaDataWhenReady(on: audioQueue) {
                        while aInput.isReadyForMoreMediaData {
                            if reader.status == .failed {
                                aInput.markAsFinished()
                                group.leave()
                                return
                            }
                            
                            if let buffer = aOutput.copyNextSampleBuffer() {
                                if aInput.isReadyForMoreMediaData {
                                    aInput.append(buffer)
                                }
                            } else {
                                aInput.markAsFinished()
                                group.leave()
                                break
                            }
                        }
                    }
                }
                
                // --- 5. FINALIZACIÓN ---
                group.notify(queue: .global()) {
                    writer.finishWriting {
                        if writer.status == .completed {
                            completion(.success(outURL))
                        } else {
                            completion(.failure(writer.error ?? NSError(domain: "ProCompressor", code: -3)))
                        }
                    }
                }
                
            } catch {
                completion(.failure(error))
            }
        }
    }
}
