import SwiftUI
import SDWebImageSwiftUI
import Combine

// MARK: - Shared Models & Store
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

struct MessagesListView: View {
    var onMenuTap: (() -> Void)? = nil
    @ObservedObject private var auth = AuthService.shared
    @StateObject private var store = MessagesStore()
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss

    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)

    private var filteredConversations: [Conversation] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = store.conversations
        if q.isEmpty { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.subtitle.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                searchBar
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredConversations) { convo in
                            NavigationLink(value: convo) {
                                ConversationRow(convo: convo)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider().padding(.leading, 80)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                    .padding(16)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationDestination(for: Conversation.self) { convo in
                ChatView(conversation: convo, store: store)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            let role = auth.user?.role ?? "client"
            store.loadConversations(for: role)
        }
    }

    private var header: some View {
        HStack {
            if let onMenuTap = onMenuTap {
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
            } else {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            Text("Mensajes")
                .font(.title3.bold())
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                    .foregroundColor(brandPink)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Buscar conversaciones...", text: $searchText)
                .foregroundColor(.black)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ConversationRow: View {
    let convo: Conversation
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: convo.avatarSystemName).foregroundColor(.gray))
                
                if convo.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(convo.title)
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    Spacer()
                    Text(convo.timestamp)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(convo.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let unread = convo.unreadCount, unread > 0 {
                        Text("\(unread)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color(red: 244/255, green: 37/255, blue: 123/255))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
    }
}

struct ChatView: View {
    let conversation: Conversation
    @ObservedObject var store: MessagesStore
    @Environment(\.dismiss) private var dismiss
    @State private var composerText: String = ""
    @State private var messages: [Message] = []
    @State private var isTyping = false
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { msg in
                            MessageBubble(message: msg, brandPink: brandPink)
                                .id(msg.id)
                                .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                        
                        if isTyping {
                            HStack {
                                TypingIndicator(color: brandPink)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .id("typing")
                        }
                    }
                    .padding(20)
                }
                .background(bgGray)
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: isTyping) { typing in
                    if typing {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
            
            composer
        }
        .navigationBarHidden(true)
        .onAppear {
            messages = [
                Message(text: "Hola, ¿mi pedido #84721 sigue en preparación?", isMe: false, time: "Hace 14 min", status: nil),
                Message(text: "Sí, estará listo en 10 minutos.", isMe: true, time: "Hace 12 min", status: .delivered),
                Message(text: conversation.subtitle, isMe: false, time: "Hace 3 min", status: nil)
            ]
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: conversation.avatarSystemName).foregroundColor(.gray))
                
                if conversation.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Text(conversation.isOnline ? "En línea" : "Desconectado")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "phone.fill")
                    .foregroundColor(brandPink)
                    .padding(8)
                    .background(brandPink.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var composer: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            
            TextField("Escribe un mensaje...", text: $composerText)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                .foregroundColor(.black)
            
            Button(action: {
                let txt = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !txt.isEmpty else { return }
                
                // Add user message
                let newMsg = Message(text: txt, isMe: true, time: "Ahora", status: .sent)
                withAnimation {
                    messages.append(newMsg)
                }
                store.updateLastMessage(id: conversation.id, text: txt)
                composerText = ""
                
                // Simulate reply sequence
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Update status to delivered
                    if let index = messages.firstIndex(where: { $0.id == newMsg.id }) {
                        withAnimation {
                            var updated = messages[index]
                            // Assuming Message is a struct and we can modify it or replace it
                            // If it's a let property, we might need to recreate it. 
                            // Since I don't see the struct, I'll replace it.
                            messages[index] = Message(text: updated.text, isMe: updated.isMe, time: updated.time, status: .delivered)
                        }
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                     withAnimation { isTyping = true }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation { isTyping = false }
                    let reply = Message(text: "¡Entendido! Lo revisaré enseguida.", isMe: false, time: "Ahora", status: nil)
                    withAnimation {
                        messages.append(reply)
                    }
                    
                    // Mark user message as read
                    if let index = messages.firstIndex(where: { $0.id == newMsg.id }) {
                        withAnimation {
                            let updated = messages[index]
                            messages[index] = Message(text: updated.text, isMe: updated.isMe, time: updated.time, status: .read)
                        }
                    }
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(brandPink)
            }
        }
        .padding()
        .background(Color.white)
    }
}

struct MessageBubble: View {
    let message: Message
    let brandPink: Color
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isMe { Spacer() }
            
            VStack(alignment: message.isMe ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(message.isMe ? .white : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isMe ? brandPink : Color.white)
                    .clipShape(RoundedCorner(radius: 20, corners: message.isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 4) {
                    Text(message.time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if message.isMe {
                        if let status = message.status {
                            Image(systemName: statusIcon(for: status))
                                .font(.caption2)
                                .foregroundColor(statusColor(for: status))
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !message.isMe { Spacer() }
        }
    }
    
    private func statusIcon(for status: MessageStatus) -> String {
        switch status {
        case .sent: return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read: return "checkmark.circle.fill"
        default: return "checkmark"
        }
    }
    
    private func statusColor(for status: MessageStatus) -> Color {
        switch status {
        case .read: return brandPink
        default: return .gray
        }
    }
}

struct TypingIndicator: View {
    let color: Color
    @State private var numberOfDots = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color.opacity(numberOfDots > index ? 1 : 0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                numberOfDots = 3
            }
        }
    }
}

// Ensure MessageStatus and Message exist or extend functionality
enum MessageStatus: String, Codable {
    case sent
    case delivered
    case read
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isMe: Bool
    let time: String
    let status: MessageStatus?
}
