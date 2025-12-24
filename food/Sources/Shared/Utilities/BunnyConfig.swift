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
    public static func hlsMasterURL(for ulid: String) -> URL? {
        guard !cdnBaseURLString.isEmpty else { return nil }
        return URL(string: "\(cdnBaseURLString)/encoded/hls/\(ulid)/index.m3u8")
    }
    public static func thumbnailURL(for ulid: String) -> URL? {
        guard !cdnBaseURLString.isEmpty else { return nil }
        return URL(string: "\(cdnBaseURLString)/thumbs/\(ulid).jpg")
    }
    public static func spriteVTTURL(for ulid: String) -> URL? {
        guard !cdnBaseURLString.isEmpty else { return nil }
        return URL(string: "\(cdnBaseURLString)/sprites/\(ulid).vtt")
    }
    public static func rawStoragePath(for ulid: String) -> String {
        "raw/\(ulid).mp4"
    }
}
