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

    // Modern Theme Colors
    private let primaryColor = Color.green 
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let backgroundColor = Color.white
    
    private var filteredConversations: [Conversation] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = store.conversations
        if q.isEmpty { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.subtitle.localizedCaseInsensitiveContains(q) }
    }
    
    // Active users (mocked from conversations for now)
    private var activeUsers: [Conversation] {
        store.conversations.filter { $0.isOnline }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                headerView
                
                // Search Bar
                searchBar
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Active Stories Section
                        if !activeUsers.isEmpty {
                            activeStoriesSection
                            Divider()
                                .padding(.vertical, 10)
                        }
                        
                        // Messages List
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredConversations.enumerated()), id: \.element.id) { index, convo in
                                NavigationLink(value: convo) {
                                    ConversationRow(convo: convo, primaryColor: primaryColor)
                                }
                                .buttonStyle(MessagesScaleButtonStyle())
                                .opacity(animateList ? 1 : 0)
                                .offset(y: animateList ? 0 : 20)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateList)
                                
                                // Separator
                                if index < filteredConversations.count - 1 {
                                    Divider()
                                        .padding(.leading, 88) // Align with text start
                                }
                            }
                        }
                        .padding(.bottom, 100) // Tab bar space
                    }
                }
                .refreshable {
                    // Pull to refresh logic
                    let role = auth.user?.role ?? "client"
                    store.loadConversations(for: role)
                }
            }
            .background(backgroundColor)
            .navigationBarHidden(true)
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateList = true
            }
        }
    }

    // MARK: - Components

    private var headerView: some View {
        HStack {
            Text("Mensajes")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                // New Message Action
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(brandPink)
                    .frame(width: 40, height: 40)
                    .background(brandPink.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(backgroundColor)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 18))
            
            TextField("Buscar...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.black)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var activeStoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                // Add Story Button
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .systemGray6))
                            .frame(width: 64, height: 64)
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    Text("Tu historia")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.leading, 20)
                
                // Active Users
                ForEach(activeUsers) { user in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: user.avatarSystemName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(14)
                                        .foregroundColor(.gray)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(brandPink, lineWidth: 2)
                                        .padding(-4)
                                        .opacity(user.unreadCount ?? 0 > 0 ? 1 : 0)
                                )
                            
                            if user.isOnline {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            }
                        }
                        
                        Text(user.title.components(separatedBy: " ").first ?? user.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .frame(width: 70)
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.top, 10) // Fix cutoff
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
        let convo: Conversation
        let primaryColor: Color
        private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
        
        var body: some View {
            HStack(spacing: 16) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color(uiColor: .systemGray6))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: convo.avatarSystemName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(14)
                                .foregroundColor(.gray)
                        )
                    
                    if convo.isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(convo.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                        Spacer()
                        Text(convo.timestamp)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(convo.unreadCount ?? 0 > 0 ? brandPink : .gray)
                    }
                    
                    HStack(alignment: .center) {
                        Text(convo.subtitle)
                            .font(.system(size: 15, weight: convo.unreadCount ?? 0 > 0 ? .medium : .regular))
                            .foregroundColor(convo.unreadCount ?? 0 > 0 ? .black : .gray)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if let unread = convo.unreadCount, unread > 0 {
                            Text("\(unread)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 22, minHeight: 22)
                                .padding(.horizontal, 6)
                                .background(brandPink)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }

// MARK: - Chat View (Redesigned)

struct ChatView: View {
        let conversation: Conversation
        @ObservedObject var store: MessagesStore
        @Environment(\.dismiss) private var dismiss
        @State private var composerText: String = ""
        @State private var messages: [Message] = []
        @State private var isTyping = false
        
        private let primaryColor = Color.green
        private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    
        var body: some View {
            VStack(spacing: 0) {
                chatHeader
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            Spacer().frame(height: 16)
                            ForEach(messages) { msg in
                                MessageBubble(message: msg, primaryColor: brandPink)
                                    .id(msg.id)
                                    .transition(.scale(scale: 0.9, anchor: msg.isMe ? .bottomTrailing : .bottomLeading).combined(with: .opacity))
                            }
                            
                            if isTyping {
                                HStack {
                                    TypingIndicator(color: brandPink)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .id("typing")
                                .transition(.opacity)
                            }
                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                    }
                    .background(Color.white)
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
            .toolbar(.hidden, for: .tabBar) // Ensure tab bar is hidden to avoid layout issues
            .environment(\.colorScheme, .light)
            .onAppear {
                // Mock messages
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color(uiColor: .systemGray6))
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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    Text(conversation.isOnline ? "En línea" : "Desconectado")
                        .font(.system(size: 12))
                        .foregroundColor(conversation.isOnline ? primaryColor : .gray)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "phone")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
            
            Button(action: {}) {
                Image(systemName: "video")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider().opacity(0.5), alignment: .bottom)
    }

    private var composer: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(Color(uiColor: .systemGray3))
            }
            
            HStack {
                TextField("Escribe un mensaje...", text: $composerText)
                    .font(.system(size: 16))
                
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 24))
                        .foregroundColor(Color(uiColor: .systemGray3))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(24)
            
            if !composerText.isEmpty {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(brandPink)
                }
                .transition(.scale)
            } else {
                Button(action: {}) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(uiColor: .systemGray3))
                }
                .transition(.scale)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider().opacity(0.5), alignment: .top)
    }
    
    private func sendMessage() {
        let txt = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !txt.isEmpty else { return }
        
        let newMsg = Message(text: txt, isMe: true, time: "Ahora", status: .sent)
        withAnimation {
            messages.append(newMsg)
        }
        store.updateLastMessage(id: conversation.id, text: txt)
        composerText = ""
        
        // Simulation logic
        simulateReply(to: newMsg)
    }
    
    private func simulateReply(to msg: Message) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let index = messages.firstIndex(where: { $0.id == msg.id }) {
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
            
            if let index = messages.firstIndex(where: { $0.id == msg.id }) {
                withAnimation {
                    let updated = messages[index]
                    messages[index] = Message(id: updated.id, text: updated.text, isMe: updated.isMe, time: updated.time, status: .read)
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let primaryColor: Color
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isMe { Spacer() }
            
            VStack(alignment: message.isMe ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(message.isMe ? .white : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isMe ? primaryColor : Color(uiColor: .systemGray6))
                    .clipShape(BubbleShape(myMessage: message.isMe))
                
                HStack(spacing: 4) {
                    if message.isMe, let status = message.status {
                        Image(systemName: statusIcon(for: status))
                            .font(.system(size: 10))
                            .foregroundColor(statusColor(for: status))
                    }
                    Text(message.time)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
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
        case .read: return primaryColor
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
            cornerRadii: CGSize(width: 20, height: 20)
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
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(18)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                numberOfDots = 3
            }
        }
    }
}

// MARK: - Styles

struct MessagesScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .background(configuration.isPressed ? Color.gray.opacity(0.05) : Color.clear)
    }
}

// MARK: - Models (Local if not available)
// Message and MessageStatus are defined in this file to ensure self-containment for the view

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
