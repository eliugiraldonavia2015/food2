import Foundation

public final class BunnyUploader {
    public static func upload(fileURL: URL, ulid: String, accessKey: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let zone = BunnyConfig.storageZoneName
        guard !zone.isEmpty else {
            completion(.failure(NSError(domain: "BunnyUploader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage zone vacío"])))
            return
        }
        let path = BunnyConfig.rawStoragePath(for: ulid)
        func attempt(host: String, fallback: Bool) {
            guard let url = URL(string: "https://\(host)/\(zone)/\(path)") else {
                completion(.failure(NSError(domain: "BunnyUploader", code: -2, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
                return
            }
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue(accessKey, forHTTPHeaderField: "AccessKey")
            req.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
            URLSession.shared.uploadTask(with: req, fromFile: fileURL) { data, resp, err in
                if let e = err as? URLError, e.code == .cannotFindHost, !fallback {
                    attempt(host: "storage.bunnycdn.com", fallback: true)
                    return
                }
                if let err = err {
                    completion(.failure(err))
                    return
                }
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? -3
                    let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    completion(.failure(NSError(domain: "BunnyUploader", code: code, userInfo: [NSLocalizedDescriptionKey: "Respuesta \(code) \(body)"])))
                    return
                }
                let cdn = BunnyConfig.cdnBaseURLString
                if !cdn.isEmpty, let final = URL(string: "\(cdn)/\(path)") {
                    completion(.success(final))
                } else {
                    completion(.success(url))
                }
            }.resume()
        }
        attempt(host: BunnyConfig.storageHost, fallback: false)
    }
}
