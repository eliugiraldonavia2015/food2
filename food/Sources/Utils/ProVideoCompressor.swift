import Foundation
import AVFoundation
import UIKit
import VideoToolbox

/// Niveles de calidad PRO ajustados para Food App (mínimo 540p, cero pixelación).
/// Cada nivel define una resolución y un bitrate objetivo para balancear peso vs calidad.
enum ProQualityLevel {
    /// No tocar el archivo. Se usa para videos < 10 MB donde recomprimir sería contraproducente.
    case passThrough
    
    /// Nivel Nano (Smart Check): Intenta comprimir videos pequeños con HEVC muy eficiente.
    /// Si el resultado pesa más que el original, se descarta.
    case nano
    
    /// Calidad qHD (960x540) @ 1.5 Mbps.
    /// Ideal para móviles. Se ve nítido en pantallas verticales sin gastar datos de HD.
    /// Usamos H.264 aquí para máxima compatibilidad en resoluciones bajas.
    case qhd_540p
    
    /// Calidad HD Estándar (1280x720) @ 2.0 Mbps.
    /// Usamos HEVC (H.265) para lograr calidad HD con la mitad del peso de H.264.
    case hd_720p
    
    /// Calidad HD Premium (1280x720) @ 2.5 Mbps.
    /// Para videos grandes (> 60 MB) donde queremos preservar textura y detalle fino.
    case hd_720p_hq
    
    /// Devuelve la configuración técnica (Ancho, Alto, Bitrate, Códec) para cada nivel.
    var config: (width: Int, height: Int, bitrate: Int, useHEVC: Bool) {
        switch self {
        case .passThrough: return (0, 0, 0, false) // Dummy
        case .nano:        return (1280, 720, 1_000_000, true) // HEVC 1 Mbps
        case .qhd_540p:    return (960, 540, 1_500_000, false) // H.264
        case .hd_720p:     return (1280, 720, 2_000_000, true) // HEVC
        case .hd_720p_hq:  return (1280, 720, 2_500_000, true) // HEVC
        }
    }
}

/// Motor de compresión de video profesional basado en AVAssetWriter.
/// A diferencia de AVAssetExportSession (presets), este motor permite control total sobre el bitrate.
final class ProVideoCompressor {
    
    static func compress(inputURL: URL, level: ProQualityLevel, completion: @escaping (Result<URL, Error>) -> Void) {
        // 1. Pass-through: Retornar original inmediatamente.
        if case .passThrough = level {
            completion(.success(inputURL))
            return
        }
        
        let config = level.config
        let asset = AVAsset(url: inputURL)
        
        // Cargar tracks asíncronamente para evitar bloquear el hilo principal.
        Task {
            do {
                guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                    throw NSError(domain: "ProCompressor", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track"])
                }
                
                // --- 1. CONFIGURACIÓN DEL LECTOR (READER) ---
                // Lee los frames descomprimidos del archivo original.
                let reader = try AVAssetReader(asset: asset)
                let readerOutputSettings: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA // Formato estándar para procesamiento
                ]
                let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
                if reader.canAdd(readerOutput) { reader.add(readerOutput) } else { throw NSError(domain: "ProCompressor", code: -2) }
                
                // Configurar Audio Reader (si existe audio).
                // Es vital mantener el audio sincronizado.
                var audioReaderOutput: AVAssetReaderTrackOutput?
                if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                    let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
                    if reader.canAdd(audioOutput) {
                        reader.add(audioOutput)
                        audioReaderOutput = audioOutput
                    }
                }
                
                // --- 2. CONFIGURACIÓN DEL ESCRITOR (WRITER) ---
                // Escribe el nuevo archivo comprimido frame por frame.
                let outFilename = UUID().uuidString + ".mp4"
                let outURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outFilename)
                if FileManager.default.fileExists(atPath: outURL.path) { try FileManager.default.removeItem(at: outURL) }
                
                let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
                writer.shouldOptimizeForNetworkUse = true // Mueve metadatos al inicio (Fast Start)
                
                // --- 3. CONFIGURACIÓN DE COMPRESIÓN DE VIDEO (EL CORAZÓN DEL SISTEMA) ---
                // Aquí definimos manualmente los parámetros que los Presets de Apple ocultan.
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: config.useHEVC ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
                    AVVideoWidthKey: config.width,
                    AVVideoHeightKey: config.height,
                    AVVideoCompressionPropertiesKey: [
                        // Bitrate Promedio (ABR): El factor más importante para el peso final.
                        AVVideoAverageBitRateKey: config.bitrate,
                        
                        // Perfil: Usamos Main/High para mejor eficiencia.
                        AVVideoProfileLevelKey: config.useHEVC ? kVTProfileLevel_HEVC_Main_AutoLevel : AVVideoProfileLevelH264HighAutoLevel,
                        
                        // Keyframe Interval (GOP): Forzamos un keyframe cada 2 segundos (60 frames @ 30fps).
                        // Esto es CRÍTICO para HLS y streaming adaptativo.
                        AVVideoMaxKeyFrameIntervalKey: 60,
                        
                        // Frame Rate: Estandarizamos a 30fps para consistencia.
                        AVVideoExpectedSourceFrameRateKey: 30
                    ]
                ]
                
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                writerInput.expectsMediaDataInRealTime = false // Permite procesar más rápido que tiempo real
                
                // Transformación: Asegurar que la orientación (vertical/horizontal) se respete.
                writerInput.transform = try await videoTrack.load(.preferredTransform)
                
                if writer.canAdd(writerInput) { writer.add(writerInput) }
                
                // Configuración Audio: Estandarizamos a AAC 128kbps Estéreo.
                var audioInput: AVAssetWriterInput?
                if audioReaderOutput != nil {
                    let audioSettings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVNumberOfChannelsKey: 2,
                        AVSampleRateKey: 44100,
                        AVEncoderBitRateKey: 128000 // 128 kbps es suficiente para voz/ambiente
                    ]
                    let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                    aInput.expectsMediaDataInRealTime = false
                    if writer.canAdd(aInput) {
                        writer.add(aInput)
                        audioInput = aInput
                    }
                }
                
                // --- 4. INICIO DEL PROCESO DE TRANSCODIFICACIÓN ---
                reader.startReading()
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                
                // Colas seriales para procesar buffers en orden.
                let videoQueue = DispatchQueue(label: "videoQueue")
                let audioQueue = DispatchQueue(label: "audioQueue")
                let group = DispatchGroup()
                
                // Procesamiento de Video
                group.enter()
                writerInput.requestMediaDataWhenReady(on: videoQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if let buffer = readerOutput.copyNextSampleBuffer() {
                            writerInput.append(buffer)
                        } else {
                            writerInput.markAsFinished()
                            group.leave()
                            break
                        }
                    }
                }
                
                // Procesamiento de Audio
                if let aInput = audioInput, let aOutput = audioReaderOutput {
                    group.enter()
                    aInput.requestMediaDataWhenReady(on: audioQueue) {
                        while aInput.isReadyForMoreMediaData {
                            if let buffer = aOutput.copyNextSampleBuffer() {
                                aInput.append(buffer)
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
