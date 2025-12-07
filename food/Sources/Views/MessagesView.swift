import SwiftUI
import UIKit

struct MessagesListView: View {
    @State private var searchText: String = ""

    private var filteredConversations: [Conversation] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return Conversation.sample }
        return Conversation.sample.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.subtitle.localizedCaseInsensitiveContains(q) }
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
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationDestination(for: Conversation.self) { convo in
                ChatView(conversation: convo)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Mensajes")
                .foregroundColor(.white)
                .font(.system(size: 28, weight: .bold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Buscar conversaciones...", text: $searchText)
                .foregroundColor(.white)
                .font(.callout)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 8, x: 0, y: 2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

struct ConversationRow: View {
    let convo: Conversation

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 52, height: 52)
                    .overlay(Image(systemName: convo.avatarSystemName).foregroundColor(.white))
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                if convo.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(convo.title)
                    .foregroundColor(.white)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(convo.subtitle)
                    .foregroundColor(.gray)
                    .font(.callout)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(convo.timestamp)
                    .foregroundColor(.gray)
                    .font(.caption2)
                if let unread = convo.unreadCount, unread > 0 {
                    ZStack {
                        Circle().fill(Color.green)
                        Text("\(unread)")
                            .foregroundColor(.white)
                            .font(.caption.bold())
                    }
                    .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.6) }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button { } label: { Image(systemName: "pin.fill") }.tint(.orange)
            Button { } label: { Image(systemName: "envelope.open.fill") }.tint(.green)
            Button(role: .destructive) { } label: { Image(systemName: "trash") }
        }
    }
}

struct ChatView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @State private var composerText: String = ""
    @State private var messages: [Message] = Message.sample

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            composer
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .semibold))
            }
            Text(conversation.title)
                .foregroundColor(.white)
                .font(.system(size: 22, weight: .bold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            Button {} label: {
                Image(systemName: "paperclip")
                    .foregroundColor(.gray)
                    .font(.system(size: 18))
            }
            TextField("Escribe un mensaje...", text: $composerText, axis: .vertical)
                .lineLimit(1...5)
                .foregroundColor(.white)
                .textInputAutocapitalization(.sentences)
            Button {
                let txt = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !txt.isEmpty else { return }
                messages.append(Message(text: txt, isMe: true, time: "Ahora"))
                composerText = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(Color(UIColor.systemBlue))
                    .font(.system(size: 20))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom) {
            if message.isMe { Spacer() }
            VStack(alignment: message.isMe ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if message.isMe { Color(UIColor.systemBlue) } else { Color.white.opacity(0.12) }
                        }
                    )
                    .overlay(
                        RoundedCorner(radius: 20, corners: message.isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                            .stroke(message.isMe ? Color.clear : Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .clipShape(RoundedCorner(radius: 20, corners: message.isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]))
                Text(message.time)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }
            if !message.isMe { Spacer() }
        }
    }
}


struct Conversation: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let timestamp: String
    let unreadCount: Int?
    let avatarSystemName: String
    let isOnline: Bool

    static let sample: [Conversation] = [
        Conversation(title: "Tacos El Rey", subtitle: "¡Tu pedido está listo!", timestamp: "Hace 5 min", unreadCount: 2, avatarSystemName: "person.crop.circle.fill", isOnline: true),
        Conversation(title: "Pizza Lovers", subtitle: "Gracias por tu preferencia", timestamp: "Hace 1 hora", unreadCount: nil, avatarSystemName: "person.crop.circle", isOnline: false),
        Conversation(title: "Sushi House", subtitle: "Promo 2x1 hoy", timestamp: "Ayer", unreadCount: 1, avatarSystemName: "leaf.circle", isOnline: false)
    ]
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isMe: Bool
    let time: String

    static let sample: [Message] = [
        Message(text: "Hola, ¿el pedido #123 está listo?", isMe: true, time: "Hace 10 min"),
        Message(text: "Sí, ya está en mostrador.", isMe: false, time: "Hace 9 min"),
        Message(text: "Perfecto, paso en 5.", isMe: true, time: "Hace 8 min")
    ]
}

