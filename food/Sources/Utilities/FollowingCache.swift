import Foundation

public final class FollowingCache {
    private var store: [String: Bool] = [:]
    private var order: [String] = []
    private let capacity: Int
    
    public init(capacity: Int = 512) {
        self.capacity = max(8, capacity)
    }
    
    public func get(_ key: String) -> Bool? {
        guard let value = store[key] else { return nil }
        if let idx = order.firstIndex(of: key) {
            order.remove(at: idx)
            order.append(key)
        }
        return value
    }
    
    public func set(_ key: String, value: Bool) {
        if store[key] == nil {
            order.append(key)
            if order.count > capacity, let first = order.first {
                order.removeFirst()
                store.removeValue(forKey: first)
            }
        } else {
            if let idx = order.firstIndex(of: key) {
                order.remove(at: idx)
                order.append(key)
            }
        }
        store[key] = value
    }
    
    public func containsTrue(_ key: String) -> Bool {
        return store[key] == true
    }
}
