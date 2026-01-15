import Foundation

final class LikeCacheService {
    static let shared = LikeCacheService()

    private let queue = DispatchQueue(label: "LikeCacheService.queue", attributes: .concurrent)
    private var cache: [String: Bool] = [:]

    private init() {}

    func get(userId: String, videoId: String) -> Bool? {
        let key = makeKey(userId: userId, videoId: videoId)
        var value: Bool?
        queue.sync {
            value = cache[key]
        }
        return value
    }

    func set(userId: String, videoId: String, liked: Bool) {
        let key = makeKey(userId: userId, videoId: videoId)
        queue.async(flags: .barrier) {
            self.cache[key] = liked
        }
    }

    func remove(userId: String, videoId: String) {
        let key = makeKey(userId: userId, videoId: videoId)
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }

    func clearAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }

    private func makeKey(userId: String, videoId: String) -> String {
        "\(userId)|\(videoId)"
    }
}

