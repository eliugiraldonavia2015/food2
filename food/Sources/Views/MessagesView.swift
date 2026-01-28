import SwiftUI
import SDWebImageSwiftUI
import Combine

struct MessagesListView: View {
    var onMenuTap: (() -> Void)? = nil
    @ObservedObject private var auth = AuthService.shared
    @StateObject private var store = MessagesStore()
    @State private var searchText: String = ""
    @State private var animateList = false
    @State private var showScreen = false
    @Environment(\.dismiss) private var dismiss

    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    private var filteredConversations: [Conversation] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = store.conversations
        if q.isEmpty { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.subtitle.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Solid background (Apple style)
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    searchBar
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Spacer().frame(height: 10)
                            
                            ForEach(Array(filteredConversations.enumerated()), id: \.element.id) { index, convo in
                                NavigationLink(value: convo) {
                                    ConversationRow(convo: convo)
                                }
                                .buttonStyle(ScaleButtonStyle()) // Apply custom scale button style
                                .opacity(animateList ? 1 : 0)
                                .offset(y: animateList ? 0 : 20)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateList)
                                
                                if index < filteredConversations.count - 1 {
                                    Divider()
                                        .padding(.leading, 80)
                                        .opacity(animateList ? 1 : 0)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 100) // Tab bar space
                    }
                }
            }
            .opacity(showScreen ? 1 : 0)
            .offset(y: showScreen ? 0 : 15)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showScreen)
            .navigationDestination(for: Conversation.self) { convo in
                ChatView(conversation: convo, store: store)
            }
        }
        .environment(\.colorScheme, .light)
        .preferredColorScheme(.light)
        .onAppear {
            showScreen = true
            let role = auth.user?.role ?? "client"
            store.loadConversations(for: role)
            
            // Stagger list animation slightly for a premium feel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateList = true
            }
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
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            Text("Mensajes")
                .font(.system(size: 28, weight: .bold)) // Large title style
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(brandPink)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Buscar...", text: $searchText)
                .foregroundColor(.black)
                .font(.system(size: 16))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white) // Use white instead of grey for cleaner look
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}

struct ConversationRow: View {
    let convo: Conversation
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay(Image(systemName: convo.avatarSystemName).foregroundColor(.gray))
                
                if convo.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(convo.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Text(convo.timestamp)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                HStack(alignment: .center) {
                    Text(convo.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(convo.unreadCount ?? 0 > 0 ? .black : .gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let unread = convo.unreadCount, unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(.horizontal, 4)
                            .background(Color(red: 244/255, green: 37/255, blue: 123/255))
                            .clipShape(Capsule())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle()) // Important for tap gesture
    }
}

// Reuse ChatView but ensure it follows the theme
struct ChatView: View {
    let conversation: Conversation
    @ObservedObject var store: MessagesStore
    @Environment(\.dismiss) private var dismiss
    @State private var composerText: String = ""
    @State private var messages: [Message] = []
    @State private var isTyping = false
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Spacer().frame(height: 10)
                        ForEach(messages) { msg in
                            MessageBubble(message: msg, brandPink: brandPink)
                                .id(msg.id)
                                .transition(.scale(scale: 0.8, anchor: msg.isMe ? .bottomTrailing : .bottomLeading).combined(with: .opacity))
                        }
                        
                        if isTyping {
                            HStack {
                                TypingIndicator(color: brandPink)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .id("typing")
                            .transition(.opacity)
                        }
                        Spacer().frame(height: 10)
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color(uiColor: .systemGroupedBackground)) // Clean background
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
        .environment(\.colorScheme, .light)
        .onAppear {
            messages = [
                Message(text: "Hola, ¿mi pedido #84721 sigue en preparación?", isMe: false, time: "Hace 14 min", status: nil),
                Message(text: "Sí, estará listo en 10 minutos.", isMe: true, time: "Hace 12 min", status: .delivered),
                Message(text: conversation.subtitle, isMe: false, time: "Hace 3 min", status: nil)
            ]
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left") // Apple style back button
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(.trailing, 4)
            
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                Text(conversation.isOnline ? "En línea" : "Desconectado")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(brandPink)
                    .padding(8)
                    .background(brandPink.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 22))
                    .foregroundColor(.blue) // Apple style
            }
            
            TextField("iMessage", text: $composerText) // iMessage style placeholder
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.3), lineWidth: 1))
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
                    if let index = messages.firstIndex(where: { $0.id == newMsg.id }) {
                        withAnimation {
                            var updated = messages[index]
                            messages[index] = Message(id: updated.id, text: updated.text, isMe: updated.isMe, time: updated.time, status: .delivered)
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
                    
                    if let index = messages.firstIndex(where: { $0.id == newMsg.id }) {
                        withAnimation {
                            let updated = messages[index]
                            messages[index] = Message(id: updated.id, text: updated.text, isMe: updated.isMe, time: updated.time, status: .read)
                        }
                    }
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(brandPink)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct MessageBubble: View {
    let message: Message
    let brandPink: Color
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isMe { Spacer() }
            
            VStack(alignment: message.isMe ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(message.isMe ? .white : .black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isMe ? brandPink : Color.white)
                    .clipShape(BubbleShape(myMessage: message.isMe))
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                
                HStack(spacing: 4) {
                    Text(message.time)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)

                    if message.isMe, let status = message.status {
                        Image(systemName: statusIcon(for: status))
                            .font(.system(size: 10))
                            .foregroundColor(statusColor(for: status))
                            .transition(.opacity)
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
        }
    }
    
    private func statusColor(for status: MessageStatus) -> Color {
        switch status {
        case .read: return brandPink
        default: return .gray
        }
    }
}

struct BubbleShape: Shape {
    var myMessage: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                myMessage ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 18, height: 18)
        )
        return Path(path.cgPath)
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
        .cornerRadius(18)
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
    let id: UUID
    let text: String
    let isMe: Bool
    let time: String
    let status: MessageStatus?
    
    init(id: UUID = UUID(), text: String, isMe: Bool, time: String, status: MessageStatus?) {
        self.id = id
        self.text = text
        self.isMe = isMe
        self.time = time
        self.status = status
    }
}
