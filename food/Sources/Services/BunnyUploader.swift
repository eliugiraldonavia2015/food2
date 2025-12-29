import Foundation
import UIKit // Necesario para UIImage

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
        case dataConversionFailed
        
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
            case .dataConversionFailed: return "No se pudo convertir la imagen a datos"
            }
        }
    }

    /// Sube un video a la carpeta raw/
    public static func upload(fileURL: URL, ulid: String, accessKey: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let path = BunnyConfig.rawStoragePath(for: ulid)
        
        // Convertir URL a Data (Streamed request sería mejor, pero para simplificar reusamos la lógica)
        // Nota: URLSession.uploadTask(with:fromFile:) es más eficiente que cargar Data en memoria.
        // Por eso mantenemos una implementación específica para archivos grandes (Videos).
        
        let zone = BunnyConfig.storageZoneName
        let host = BunnyConfig.storageHost
        
        guard !zone.isEmpty else {
            completion(.failure(UploadError.invalidURL("Storage Zone Name está vacío")))
            return
        }
        
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
        
        print("\n🚀 [BunnyUploader] Subiendo VIDEO...")
        print("🌐 Destino: \(url.absoluteString)")
        
        let task = URLSession.shared.uploadTask(with: request, fromFile: fileURL) { data, response, error in
            handleResponse(data: data, response: response, error: error, path: path, originalURL: url, completion: completion)
        }
        task.resume()
    }
    
    /// Sube una miniatura (JPG) a la carpeta thumbs/
    public static func uploadThumbnail(image: UIImage, ulid: String, accessKey: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(UploadError.dataConversionFailed))
            return
        }
        
        let path = "thumbs/\(ulid).jpg"
        let zone = BunnyConfig.storageZoneName
        let host = BunnyConfig.storageHost
        
        let urlString = "https://\(host)/\(zone)/\(path)"
        guard let url = URL(string: urlString) else {
            completion(.failure(UploadError.invalidURL(urlString)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(accessKey, forHTTPHeaderField: "AccessKey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("FoodTook-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        print("\n🖼 [BunnyUploader] Subiendo THUMBNAIL...")
        
        let task = URLSession.shared.uploadTask(with: request, from: imageData) { data, response, error in
            handleResponse(data: data, response: response, error: error, path: path, originalURL: url, completion: completion)
        }
        task.resume()
    }
    
    // Helper privado para manejar respuestas comunes
    private static func handleResponse(data: Data?, response: URLResponse?, error: Error?, path: String, originalURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
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
        
        switch httpResponse.statusCode {
        case 200...299:
            print("✅ [BunnyUploader] Subida exitosa: \(path)")
            let cdn = BunnyConfig.cdnBaseURLString
            if !cdn.isEmpty, let finalURL = URL(string: "\(cdn)/\(path)") {
                completion(.success(finalURL))
            } else {
                completion(.success(originalURL))
            }
        case 401: completion(.failure(UploadError.unauthorized))
        case 403: completion(.failure(UploadError.forbidden))
        case 404: completion(.failure(UploadError.notFound))
        case 500...599: completion(.failure(UploadError.serverError(httpResponse.statusCode, body)))
        default: completion(.failure(UploadError.unknown(httpResponse.statusCode, body)))
        }
    }
}
