import SwiftUI
import SDWebImageSwiftUI
import Combine

final class MessagesStore: ObservableObject {
    @Published var conversations: [Conversation] = []
    func loadConversations(for role: String) {
        conversations = role == "restaurant" ? Conversation.restaurantSample : Conversation.sample
    }
    func updateLastMessage(id: UUID, text: String) {
        if let idx = conversations.firstIndex(where: { $0.id == id }) {
            conversations[idx].subtitle = text
            conversations[idx].timestamp = "Ahora"
        }
    }
}

struct MessagesListView: View {
    @ObservedObject private var auth = AuthService.shared
    @StateObject private var store = MessagesStore()
    @State private var searchText: String = ""

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
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationDestination(for: Conversation.self) { convo in
                ChatView(conversation: convo, store: store)
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            let role = auth.user?.role ?? "client"
            store.loadConversations(for: role)
        }
        .onChange(of: auth.user?.role) { _ in
            let role = auth.user?.role ?? "client"
            store.loadConversations(for: role)
        }
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
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button { } label: { Image(systemName: "pin.fill") }.tint(.orange)
            Button { } label: { Image(systemName: "envelope.open.fill") }.tint(.green)
            Button(role: .destructive) { } label: { Image(systemName: "trash") }
        }
    }
}

struct ChatView: View {
    let conversation: Conversation
    @ObservedObject var store: MessagesStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var auth = AuthService.shared
    @State private var composerText: String = ""
    @State private var messages: [Message] = []
    @State private var showOrderSheet: Bool = false
    @State private var orderTitle: String = "Pizza Margherita"
    @State private var orderImageUrl: String = "https://images.unsplash.com/photo-1546069901-5ec6a79120b0"
    @State private var orderPrice: String = "$15.99"
    @State private var orderSubtitle: String = "Mozzarella fresca, albahaca y tomate"
    @State private var orderTrackingCode: String = "TRK-84721"
    @State private var chosenSides: [(String, String)] = [("Papas Fritas", "$2.5"), ("Aros de Cebolla", "$3.0")]
    @State private var chosenDrinks: [String] = ["Limonada 500ml", "Coca-Cola"]
    @State private var shippingTo: String = "Av. Michoacán 78, Condesa"
    @State private var orderElapsed: String = "Hace 12 min"

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                chatHeader
                if (auth.user?.role ?? "client") == "restaurant" {
                    orderAnchor
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
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
            .blur(radius: showOrderSheet ? 8 : 0)
            .allowsHitTesting(!showOrderSheet)

            if showOrderSheet {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .transition(.opacity)
                orderBottomSheet
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            messages = [
                Message(text: "Hola, ¿mi pedido #84721 sigue en preparación?", isMe: true, time: "Hace 14 min", status: .delivered),
                Message(text: "Sí, estará listo en 10 minutos.", isMe: false, time: "Hace 12 min", status: nil),
                Message(text: conversation.subtitle, isMe: false, time: "Hace 3 min", status: nil)
            ]
        }
    }

    private var chatHeader: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .semibold))
                }
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: conversation.avatarSystemName).foregroundColor(.white))
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    Circle()
                        .fill(conversation.isOnline ? Color.green : Color.gray)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.title)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                    Text(conversation.subtitle)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
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
                messages.append(Message(text: txt, isMe: true, time: "Ahora", status: .sent))
                store.updateLastMessage(id: conversation.id, text: txt)
                composerText = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.green)
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

    private var orderAnchor: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) { showOrderSheet = true }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [Color.green.opacity(0.25), Color.green.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    WebImage(url: URL(string: orderImageUrl))
                        .resizable()
                        .indicator(.activity)
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .frame(width: 33, height: 50)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.green.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Orden Activa")
                            .foregroundColor(.white)
                            .font(.subheadline.bold())
                        Text("•")
                            .foregroundColor(.gray)
                        Text(orderTitle)
                            .foregroundColor(.white.opacity(0.9))
                            .font(.footnote)
                            .lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.green)
                        Text("Seguimiento \(orderTrackingCode)")
                            .foregroundColor(.green)
                            .font(.caption.bold())
                    }
                }
                Spacer()
                Image(systemName: "chevron.up")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
            .background(
                LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(LinearGradient(colors: [Color.white.opacity(0.14), Color.green.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var orderBottomSheet: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    orderTopBlock
                    orderInfoPanel
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detalles del plato")
                            .foregroundColor(.white)
                            .font(.headline)
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 100)
                            .overlay(
                                Text("Mozzarella fresca, albahaca, salsa de tomate. Masa delgada.")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.footnote)
                                    .padding(12), alignment: .topLeading
                            )
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Acompañamientos")
                                .foregroundColor(.white)
                                .font(.subheadline.bold())
                            ForEach(chosenSides, id: \.0) { side in
                                HStack {
                                    Text(side.0).foregroundColor(.white).font(.footnote)
                                    Spacer()
                                    Text("+ \(side.1)").foregroundColor(.green).font(.footnote.bold())
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bebidas")
                                .foregroundColor(.white)
                                .font(.subheadline.bold())
                            WrapTags(items: chosenDrinks)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Envío")
                                .foregroundColor(.white)
                                .font(.subheadline.bold())
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.and.ellipse").foregroundColor(.green)
                                Text(shippingTo).foregroundColor(.white).font(.footnote)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pedido")
                                .foregroundColor(.white)
                                .font(.subheadline.bold())
                            HStack(spacing: 10) {
                                Image(systemName: "clock").foregroundColor(.green)
                                Text("Realizado \(orderElapsed)").foregroundColor(.white).font(.footnote)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 56)
                }
            }
            .overlay(alignment: .topTrailing) { sheetCloseButton.padding(10) }
            .safeAreaInset(edge: .bottom) {
                sheetActionBar.padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 0)
                    .background(Color.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.7)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: -4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var orderTopBlock: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color.green.opacity(0.25), Color.green.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 180)
            HStack {
                Spacer()
                WebImage(url: URL(string: orderImageUrl))
                    .resizable()
                    .indicator(.activity)
                    .scaledToFill()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Spacer()
            }
        }
        .zIndex(0)
        .padding(.horizontal, 12)
    }

    private var orderInfoPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(orderTitle).foregroundColor(.white).font(.system(size: 22, weight: .bold))
            Text(orderSubtitle).foregroundColor(.white.opacity(0.9)).font(.system(size: 14))
            Text(orderPrice).foregroundColor(.green).font(.system(size: 20, weight: .bold))
            HStack(spacing: 6) {
                Image(systemName: "barcode.viewfinder").foregroundColor(.green)
                Text("Código \(orderTrackingCode)").foregroundColor(.green).font(.caption.bold())
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .offset(y: -18)
        .zIndex(1)
        .padding(.horizontal, 12)
    }

    private var sheetCloseButton: some View {
        Button(action: { withAnimation(.easeOut(duration: 0.25)) { showOrderSheet = false } }) {
            Circle().fill(Color.black.opacity(0.6)).frame(width: 32, height: 32)
                .overlay(Image(systemName: "xmark").foregroundColor(.white))
        }
    }

    private var sheetActionBar: some View {
        Button(action: { withAnimation(.easeOut(duration: 0.25)) { showOrderSheet = false } }) {
            Text("Cerrar")
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct WrapTags: View {
    let items: [String]
    private let spacing: CGFloat = 8
    var body: some View {
        var totalWidth: CGFloat = 0
        var rows: [[String]] = [[]]
        for item in items {
            let itemWidth = (item.count > 0 ? CGFloat(item.count) * 7.5 : 40) + 24
            if totalWidth + itemWidth + spacing > UIScreen.main.bounds.width - 32 {
                rows.append([item])
                totalWidth = itemWidth + spacing
            } else {
                rows[rows.count - 1].append(item)
                totalWidth += itemWidth + spacing
            }
        }
        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: spacing) {
                    ForEach(rows[r], id: \.self) { label in
                        Text(label)
                            .foregroundColor(.white)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
            }
        }
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
                            if message.isMe { Color.green } else { Color.white.opacity(0.12) }
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
                if message.isMe, let status = message.status {
                    HStack(spacing: 4) {
                        Image(systemName: status == .seen ? "checkmark.circle.fill" : (status == .delivered ? "checkmark.circle" : "paperplane"))
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(status.label)
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption2)
                    }
                }
            }
            if !message.isMe { Spacer() }
        }
    }
}


struct Conversation: Identifiable, Hashable {
    let id = UUID()
    let title: String
    var subtitle: String
    var timestamp: String
    let unreadCount: Int?
    let avatarSystemName: String
    let isOnline: Bool

    static let sample: [Conversation] = [
        Conversation(title: "Tacos El Rey", subtitle: "¡Tu pedido está listo!", timestamp: "Hace 5 min", unreadCount: 2, avatarSystemName: "person.crop.circle.fill", isOnline: true),
        Conversation(title: "Pizza Lovers", subtitle: "Gracias por tu preferencia", timestamp: "Hace 1 hora", unreadCount: nil, avatarSystemName: "person.crop.circle", isOnline: false),
        Conversation(title: "Sushi House", subtitle: "Promo 2x1 hoy", timestamp: "Ayer", unreadCount: 1, avatarSystemName: "leaf.circle", isOnline: false)
    ]

    static let restaurantSample: [Conversation] = [
        Conversation(title: "Juan Pérez", subtitle: "¿Sigue disponible la promo?", timestamp: "Hace 3 min", unreadCount: 1, avatarSystemName: "person.crop.circle.fill", isOnline: true),
        Conversation(title: "María López", subtitle: "Gracias por la atención", timestamp: "Hace 12 min", unreadCount: nil, avatarSystemName: "person.crop.circle.fill", isOnline: true),
        Conversation(title: "Carlos Gómez", subtitle: "Confirmo el pedido #84721", timestamp: "Hace 28 min", unreadCount: 2, avatarSystemName: "person.crop.circle", isOnline: false),
        Conversation(title: "Ana Rodríguez", subtitle: "¿Tiempo estimado de entrega?", timestamp: "Hace 1 hora", unreadCount: nil, avatarSystemName: "person.crop.circle.fill", isOnline: true),
        Conversation(title: "Luis Hernández", subtitle: "Sin cebolla por favor", timestamp: "Ayer", unreadCount: nil, avatarSystemName: "person.crop.circle", isOnline: false),
        Conversation(title: "Sofía Martínez", subtitle: "Excelente servicio 🙌", timestamp: "Ayer", unreadCount: 3, avatarSystemName: "person.crop.circle.fill", isOnline: true),
        Conversation(title: "Miguel Torres", subtitle: "¿Aceptan pago en efectivo?", timestamp: "Ayer", unreadCount: nil, avatarSystemName: "person.crop.circle", isOnline: false),
        Conversation(title: "Paula Sánchez", subtitle: "Necesito factura", timestamp: "Hace 2 días", unreadCount: nil, avatarSystemName: "person.crop.circle.fill", isOnline: true),
        Conversation(title: "Diego Ramírez", subtitle: "Agreguen salsa extra", timestamp: "Hace 2 días", unreadCount: 1, avatarSystemName: "person.crop.circle", isOnline: false),
        Conversation(title: "Lucía Fernández", subtitle: "¿Tienen opción sin gluten?", timestamp: "Hace 3 días", unreadCount: nil, avatarSystemName: "person.crop.circle.fill", isOnline: true)
    ]
}

enum MessageStatus { case sent, delivered, seen }

extension MessageStatus {
    var label: String { switch self { case .sent: return "Enviado"; case .delivered: return "Entregado"; case .seen: return "Visto" } }
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isMe: Bool
    let time: String
    var status: MessageStatus?

    static let sample: [Message] = [
        Message(text: "Hola, ¿el pedido #123 está listo?", isMe: true, time: "Hace 10 min", status: .delivered),
        Message(text: "Sí, ya está en mostrador.", isMe: false, time: "Hace 9 min", status: nil),
        Message(text: "Perfecto, paso en 5.", isMe: true, time: "Hace 8 min", status: .seen)
    ]
}

