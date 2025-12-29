import Foundation

public struct BunnyConfig {
    public static var cdnBaseURLString: String {
        (Bundle.main.object(forInfoDictionaryKey: "BUNNY_CDN_BASE_URL") as? String) ?? ""
    }
    public static var storageZoneName: String {
        (Bundle.main.object(forInfoDictionaryKey: "BUNNY_STORAGE_ZONE_NAME") as? String) ?? ""
    }
    public static var storageHost: String {
        ((Bundle.main.object(forInfoDictionaryKey: "BUNNY_STORAGE_HOST") as? String) ?? "storage.bunnycdn.com").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// URL pública del video optimizado (MP4) para streaming progresivo.
    public static func videoURL(for ulid: String) -> URL? {
        guard !cdnBaseURLString.isEmpty else { return nil }
        return URL(string: "\(cdnBaseURLString)/raw/\(ulid).mp4")
    }
    
    public static func thumbnailURL(for ulid: String) -> URL? {
        guard !cdnBaseURLString.isEmpty else { return nil }
        // Nota: Si no usamos worker, no hay thumbnails generados por servidor.
        // La app deberá subir el thumbnail o generarlo al vuelo si es posible.
        // Por ahora mantenemos la ruta por si implementamos subida de thumbs desde la app.
        return URL(string: "\(cdnBaseURLString)/thumbs/\(ulid).jpg")
    }
    
    public static func rawStoragePath(for ulid: String) -> String {
        "raw/\(ulid).mp4"
    }
}
