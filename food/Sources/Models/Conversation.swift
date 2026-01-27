import Foundation

public struct Conversation: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let timestamp: String
    public let unreadCount: Int?
    public let avatarSystemName: String
    public let isOnline: Bool
    
    public init(id: UUID = UUID(), title: String, subtitle: String, timestamp: String, unreadCount: Int? = nil, avatarSystemName: String, isOnline: Bool) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.unreadCount = unreadCount
        self.avatarSystemName = avatarSystemName
        self.isOnline = isOnline
    }
}
