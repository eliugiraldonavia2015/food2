import Foundation

public final class FollowingStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    private func key(for uid: String) -> String { "following.\(uid)" }
    public func load(for uid: String) -> [String] {
        return defaults.stringArray(forKey: key(for: uid)) ?? []
    }
    public func save(for uid: String, uids: [String]) {
        defaults.set(uids, forKey: key(for: uid))
    }
    public func add(for uid: String, followedUid: String, cap: Int = 1024) {
        var list = load(for: uid)
        if let idx = list.firstIndex(of: followedUid) {
            list.remove(at: idx)
        }
        list.insert(followedUid, at: 0)
        if list.count > cap { list = Array(list.prefix(cap)) }
        save(for: uid, uids: list)
    }
    public func contains(for uid: String, followedUid: String) -> Bool {
        return load(for: uid).contains(followedUid)
    }
}
