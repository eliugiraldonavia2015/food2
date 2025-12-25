import Foundation

public final class BunnyUploader {
    
    public enum UploadError: LocalizedError {
        case invalidURL(String)
        case networkError(Error)
        case unauthorized // 401
        case forbidden // 403
        case notFound // 404
        case serverError(Int, String) // 5xx
        case unknown(Int, String)
        case invalidResponse
        
        public var errorDescription: String? {
            switch self {
            case .invalidURL(let url): return "URL inválida generada: \(url)"
            case .networkError(let err): return "Error de red: \(err.localizedDescription)"
            case .unauthorized: return "⛔️ Error 401: No autorizado. Verifica tu AccessKey."
            case .forbidden: return "⛔️ Error 403: Prohibido. Verifica permisos de escritura."
            case .notFound: return "⛔️ Error 404: Ruta no encontrada. Verifica Host y Zone."
            case .serverError(let code, let msg): return "🔥 Error Servidor \(code): \(msg)"
            case .unknown(let code, let msg): return "Error desconocido (\(code)): \(msg)"
            case .invalidResponse: return "Respuesta inválida del servidor"
            }
        }
    }

    public static func upload(fileURL: URL, ulid: String, accessKey: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let zone = BunnyConfig.storageZoneName
        let host = BunnyConfig.storageHost
        let path = BunnyConfig.rawStoragePath(for: ulid)
        
        // Validación previa de configuración
        guard !zone.isEmpty else {
            completion(.failure(UploadError.invalidURL("Storage Zone Name está vacío")))
            return
        }
        
        // Construcción directa
        let urlString = "https://\(host)/\(zone)/\(path)"
        guard let url = URL(string: urlString) else {
            completion(.failure(UploadError.invalidURL(urlString)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(accessKey, forHTTPHeaderField: "AccessKey")
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        request.setValue("FoodTook-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        print("\n� [BunnyUploader] --- INICIO DEBUG ---")
        print("📂 Archivo local: \(fileURL.path)")
        print("📦 Tamaño: \(try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] ?? 0) bytes")
        print("� AccessKey (primeros 5): \(accessKey.prefix(5))...")
        print("🌐 URL Destino: \(url.absoluteString)")
        print("📋 CURL DEBUG:\ncurl -v -X PUT -H \"AccessKey: \(accessKey)\" -H \"Content-Type: video/mp4\" --upload-file \"\(fileURL.path)\" \"\(url.absoluteString)\"")
        print("---------------------------------------\n")
        
        let task = URLSession.shared.uploadTask(with: request, fromFile: fileURL) { data, response, error in
            if let error = error {
                print("❌ [BunnyUploader] Error de transporte: \(error)")
                completion(.failure(UploadError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(UploadError.invalidResponse))
                return
            }
            
            let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
            print("📡 [BunnyUploader] Status: \(httpResponse.statusCode)")
            print("📄 [BunnyUploader] Body: \(body)")
            
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ [BunnyUploader] Subida exitosa!")
                let cdn = BunnyConfig.cdnBaseURLString
                if !cdn.isEmpty, let finalURL = URL(string: "\(cdn)/\(path)") {
                    completion(.success(finalURL))
                } else {
                    completion(.success(url))
                }
            case 401:
                completion(.failure(UploadError.unauthorized))
            case 403:
                completion(.failure(UploadError.forbidden))
            case 404:
                completion(.failure(UploadError.notFound))
            case 500...599:
                completion(.failure(UploadError.serverError(httpResponse.statusCode, body)))
            default:
                completion(.failure(UploadError.unknown(httpResponse.statusCode, body)))
            }
        }
        task.resume()
    }
}
