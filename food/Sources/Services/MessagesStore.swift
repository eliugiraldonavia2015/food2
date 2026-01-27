import Foundation
import Combine

public class MessagesStore: ObservableObject {
    @Published public var conversations: [Conversation] = []
    
    public init() {}
    
    public func loadConversations(for role: String) {
        conversations = [
            Conversation(title: "Juan Pérez", subtitle: "¿El pedido lleva salsa extra?", timestamp: "10:30 AM", unreadCount: 2, avatarSystemName: "person.circle.fill", isOnline: true),
            Conversation(title: "María García", subtitle: "Gracias, todo excelente.", timestamp: "Ayer", unreadCount: 0, avatarSystemName: "person.circle.fill", isOnline: false),
            Conversation(title: "Soporte Técnico", subtitle: "Ticket #1234 resuelto", timestamp: "Lun", unreadCount: 1, avatarSystemName: "headphones.circle.fill", isOnline: true)
        ]
    }
    
    public func updateLastMessage(id: UUID, text: String) {
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            let old = conversations[index]
            conversations[index] = Conversation(
                id: old.id,
                title: old.title,
                subtitle: text,
                timestamp: "Ahora",
                unreadCount: old.unreadCount,
                avatarSystemName: old.avatarSystemName,
                isOnline: old.isOnline
            )
        }
    }
}
