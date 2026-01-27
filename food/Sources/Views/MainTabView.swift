import SwiftUI
import SDWebImageSwiftUI

struct MainTabView: View {
    enum Tab {
        case feed, notifications, store, messages, profile
    }

    @ObservedObject private var auth = AuthService.shared
    @State private var selected: Tab = .feed
    @State private var showShopLoading = false
    @State private var showShop = false
    @State private var inDiscoveryMode = false
    private let tabBarHeight: CGFloat = 52
    @State private var showCommentsOverlay = false
    @State private var commentsCount: Int = 0
    @State private var currentFeedImageUrl: String = ""
    @State private var showUploadPicker = false
    @State private var showUploadVideo = false
    @State private var showUploadDish = false

    var body: some View {
        GeometryReader { geo in
        ZStack(alignment: .bottom) {
            // CONTENIDO PRINCIPAL
            Group {
                switch selected {
                case .feed:
                    if (auth.user?.role ?? "client") == "restaurant" {
                        RestaurantDashboardView(bottomInset: tabBarHeight)
                    } else {
                        FeedView(bottomInset: tabBarHeight, onGlobalShowComments: { count, url in
                            commentsCount = count
                            currentFeedImageUrl = url
                            withAnimation(.easeOut(duration: 0.25)) { showCommentsOverlay = true }
                        }, isCommentsOverlayActive: showCommentsOverlay)
                    }
                case .notifications: NotificationsScreen()
                case .store: StoreScreen()
                case .messages: MessagesListView()
                case .profile:
                    if (auth.user?.role ?? "client") == "restaurant" {
                        ProfileScreen()
                    } else {
                        InternalProfileScreen()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .padding(.bottom, tabBarHeight) // ← ESPACIO FIJO para el tab bar
            

            if showShop {
                FoodDiscoveryView(onClose: { showShop = false })
                    .zIndex(2)
            }

            // TAB BAR
            if inDiscoveryMode {
                bottomBarDiscovery
                    .background(Color.black)
                    .zIndex(4)
            } else {
                bottomBar
                    .background(Color.black)
                    .zIndex(4)
            }

            // Overlay de comentarios por encima del tab bar
            if selected == .feed, showCommentsOverlay {
                CommentsOverlayView(
                    count: commentsCount,
                    onClose: { withAnimation(.easeOut(duration: 0.25)) { showCommentsOverlay = false } },
                    videoId: nil // En el contexto global no tenemos el ID, se pasa solo para cerrar o mostrar
                )
                    .zIndex(6)
            }
            if showUploadPicker {
                uploadPickerOverlay
                    .zIndex(7)
            }
            

        }
        
        .animation(.easeOut(duration: 0.25), value: showCommentsOverlay)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showUploadVideo) {
            UploadVideoView(onClose: { showUploadVideo = false })
        }
        .fullScreenCover(isPresented: $showUploadDish) {
            UploadDishView(onClose: { showUploadDish = false })
        }
    }

    private var bottomBar: some View {
        ZStack(alignment: .top) {
            HStack(spacing: -2) {
                navButton(icon: "house", title: "Inicio", tab: .feed)
                navButton(icon: "bell", title: "Notif", tab: .notifications)
                centerRoleButton
                navButton(icon: "message", title: "Mensajes", tab: .messages)
                navButton(icon: "person", title: "Perfil", tab: .profile)
            }
            .padding(.horizontal, 6)
            .padding(.top, 6)
            .padding(.bottom, 0)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 0.5), alignment: .top
        )
        .frame(height: tabBarHeight)
    }

    private var bottomBarDiscovery: some View {
        ZStack(alignment: .top) {
            HStack(spacing: -2) {
                backButtonDiscovery
                navButtonDiscovery(icon: "bell", title: "Notif", tab: .notifications)
                fireButton
                navButtonDiscovery(icon: "message", title: "Mensajes", tab: .messages)
                navButtonDiscovery(icon: "person", title: "Perfil", tab: .profile)
            }
            .padding(.horizontal, 6)
            .padding(.top, 6)
            .padding(.bottom, 0)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 0.5), alignment: .top
        )
        .frame(height: tabBarHeight)
    }

    private var cartButton: some View {
        centerAccentButton(icon: "cart.fill", title: "Carrito", color: .green) {
            showShopLoading = false
            showShop = true
            inDiscoveryMode = true
        }
        .frame(maxWidth: .infinity)
    }

    private var plusButton: some View {
        centerAccentButton(icon: "plus", title: "Crear", color: Color(red: 244/255, green: 37/255, blue: 123/255)) {
            withAnimation(.easeOut(duration: 0.25)) { showUploadPicker = true }
        }
        .frame(maxWidth: .infinity)
    }

    private var riderButton: some View {
        centerAccentButton(icon: "cart.fill", title: "Carrito", color: .green) {
            showShopLoading = false
            showShop = true
            inDiscoveryMode = true
        }
        .frame(maxWidth: .infinity)
    }

    private var centerRoleButton: some View {
        let role = auth.user?.role ?? "client"
        if role == "restaurant" {
            return AnyView(plusButton)
        } else if role == "rider" {
            return AnyView(riderButton)
        } else {
            return AnyView(cartButton)
        }
    }

    private var backButtonDiscovery: some View {
        VStack(spacing: 1) {
            Button {
                withAnimation {
                    showShop = true
                }
            } label: {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(Color(red: 109/255, green: 94/255, blue: 117/255))
                    .scaleEffect(1.0)
            }
            Text("Regresar")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Color(red: 109/255, green: 94/255, blue: 117/255))
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .cornerRadius(6)
    }

    private var fireButton: some View {
        centerAccentButton(icon: "flame.fill", title: "Fuego", color: .orange) {
            withAnimation {
                showShop = false
                selected = .feed
                inDiscoveryMode = false
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func navButton(icon: String, title: String, tab: Tab) -> some View {
        let isSelected = selected == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 244/255, green: 37/255, blue: 123/255) : Color(red: 109/255, green: 94/255, blue: 117/255))
                    .symbolVariant(isSelected ? .fill : .none)
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                
                Text(title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 244/255, green: 37/255, blue: 123/255) : Color(red: 109/255, green: 94/255, blue: 117/255))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(isSelected ? Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
    }

    private func navButtonDiscovery(icon: String, title: String, tab: Tab) -> some View {
        let isSelected = !showShop && selected == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = tab
                showShop = false
                inDiscoveryMode = true
            }
        } label: {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 244/255, green: 37/255, blue: 123/255) : Color(red: 109/255, green: 94/255, blue: 117/255))
                    .symbolVariant(isSelected ? .fill : .none)
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                
                Text(title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 244/255, green: 37/255, blue: 123/255) : Color(red: 109/255, green: 94/255, blue: 117/255))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(isSelected ? Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
    }

    private func centerAccentButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [color.opacity(0.9), color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -6)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(red: 109/255, green: 94/255, blue: 117/255))
        }
        .padding(.vertical, 2)
    }

    private var uploadPickerOverlay: some View {
        VStack(spacing: 12) {
            Capsule().fill(Color.white.opacity(0.2)).frame(width: 48, height: 5).padding(.top, 8)
            Text("Crear contenido")
                .foregroundColor(.white)
                .font(.headline.bold())
            VStack(spacing: 12) {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showUploadPicker = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showUploadVideo = true }
                } label: {
                    HStack(spacing: 12) {
                        Circle().fill(Color.green.opacity(0.2)).frame(width: 40, height: 40).overlay(Image(systemName: "video.fill").foregroundColor(.green))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Subir Video").foregroundColor(.white).font(.subheadline.bold())
                            Text("Promociona platos y tu marca").foregroundColor(.white.opacity(0.8)).font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showUploadPicker = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showUploadDish = true }
                } label: {
                    HStack(spacing: 12) {
                        Circle().fill(Color.green.opacity(0.2)).frame(width: 40, height: 40).overlay(Image(systemName: "fork.knife").foregroundColor(.green))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Publicar Plato").foregroundColor(.white).font(.subheadline.bold())
                            Text("Fotos, precio y disponibilidad").foregroundColor(.white.opacity(0.8)).font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            Button {
                withAnimation(.easeOut(duration: 0.25)) { showUploadPicker = false }
            } label: {
                Text("Cerrar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.black.opacity(0.6).ignoresSafeArea())
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Placeholder Screens (sin lógica por ahora)
private struct NotificationsScreen: View {
    enum Kind { case like, follow, comment, order }
    struct Item: Identifiable { let id = UUID(); let kind: Kind; let user: String; let message: String; let time: String; let thumbnail: String?; let unread: Bool }
    private var items: [Item] = [
        .init(kind: .like, user: "pizzalovers", message: "le gustó tu publicación", time: "Hace 5 min", thumbnail: "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445", unread: true),
        .init(kind: .follow, user: "sushimaster", message: "comenzó a seguirte", time: "Hace 15 min", thumbnail: nil, unread: true),
        .init(kind: .comment, user: "burgerhouse", message: "comentó: '¡Se ve delicioso! 😋'", time: "Hace 1 hora", thumbnail: "https://images.unsplash.com/photo-1550547660-d9450f859349", unread: false),
        .init(kind: .order, user: "Pedido confirmado", message: "Tu pedido está en camino", time: "Hace 2 horas", thumbnail: nil, unread: false),
        .init(kind: .like, user: "tacoselrey", message: "le gustó tu publicación", time: "Hace 3 horas", thumbnail: "https://images.unsplash.com/photo-1601924582971-b0d4b3a2c0ba", unread: false)
    ]

    private func icon(for kind: Kind) -> (name: String, color: Color) {
        switch kind {
        case .like: return ("heart.fill", .orange)
        case .follow: return ("person.badge.plus", .green)
        case .comment: return ("bubble.left.fill", .green)
        case .order: return ("checkmark.circle.fill", .blue)
        }
    }

    private func row(_ item: Item) -> some View {
        HStack(spacing: 12) {
            let ic = icon(for: item.kind)
            Circle()
                .fill(ic.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: ic.name).foregroundColor(ic.color))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.user.hasPrefix("@") ? item.user : "@\(item.user)")
                    .foregroundColor(.white)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(item.message)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(item.time)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .lineLimit(1)
            }
            Spacer()
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Group {
                            if let thumb = item.thumbnail, let url = URL(string: thumb) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    )
                if item.unread {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .padding()
        .frame(height: 76)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sectionHeader("Notificaciones")
                ForEach(items) { item in
                    row(item)
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct StoreScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sectionHeader("Store")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(0..<8) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.2))
                                .frame(height: 120)
                                .overlay(Image(systemName: "bag.fill").foregroundColor(.green))
                            Text("Combo Especial")
                                .foregroundColor(.white).font(.subheadline.bold())
                            Text("$9.99")
                                .foregroundColor(.green).font(.footnote.bold())
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}


private struct InternalProfileScreen: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var selectedSegment: Int = 0
    @State private var showSettings: Bool = false
    @State private var showEditProfile: Bool = false
    @State private var showEditMenu: Bool = false

    private let imageUrls: [String] = [
        "https://images.unsplash.com/photo-1601924582971-b0d4b3a2c0ba",
        "https://images.unsplash.com/photo-1581185642208-9ce0c0a3d1c1",
        "https://images.unsplash.com/photo-1546069901-ba9599a7e63c",
        "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
        "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
        "https://images.unsplash.com/photo-1600891963932-6bafce2b9063",
        "https://images.unsplash.com/photo-1612874741265-96b8f6f84cae",
        "https://images.unsplash.com/photo-1519681393784-d120267933ba",
        "https://images.unsplash.com/photo-1551183053-bf91a1d81139"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topBar()

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        avatarRing()
                VStack(alignment: .leading, spacing: 6) {
                    Text("@\(auth.user?.username ?? "usuario")")
                        .foregroundColor(.white)
                        .font(.title2.bold())
                    Text(auth.user?.bio ?? "")
                        .foregroundColor(.white)
                        .font(.body)
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.white)
                        Text(auth.user?.location ?? "")
                            .foregroundColor(.white)
                            .font(.footnote)
                    }
                }
                        Spacer()
                    }
                    Divider().background(Color.white.opacity(0.1))
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 12) {
                    pillStat(number: "124", label: "Posts")
                    pillStat(number: "2.5K", label: "Seguidores")
                    pillStat(number: "892", label: "Siguiendo")
                }

                HStack(spacing: 12) {
                    primaryFilledButton(title: "Editar Perfil")
                    primaryOutlinedButton(title: (auth.user?.role ?? "client") == "restaurant" ? "Editar Menú" : "Compartir Perfil")
                }

                segmentedControl()

                galleryGrid()
                Spacer(minLength: 0)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(Color.black)
        .fullScreenCover(isPresented: $showSettings) {
            SettingsScreen(onClose: { showSettings = false })
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView(onClose: { showEditProfile = false })
        }
        .fullScreenCover(isPresented: $showEditMenu) {
            RestaurantEditMenuView(
                restaurantId: auth.user?.uid ?? (auth.user?.username ?? "rest").replacingOccurrences(of: " ", with: "").lowercased(),
                restaurantName: auth.user?.username ?? "Mi Restaurante",
                coverUrl: "https://images.unsplash.com/photo-1601924582971-b0d4b3a2c0ba",
                avatarUrl: auth.user?.photoURL?.absoluteString ?? "https://images.unsplash.com/photo-1546069901-ba9599a7e63c",
                location: auth.user?.location ?? "CDMX, México",
                branchName: nil,
                distanceKm: 2.3
            )
        }
    }

    private func topBar() -> some View {
        HStack {
            Spacer()
            Text("Mi Perfil")
                .foregroundColor(.white)
                .font(.headline.bold())
            Spacer()
            Button { showSettings = true } label: {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "gearshape").foregroundColor(.white))
            }
        }
    }

    private func avatarRing() -> some View {
        ZStack {
            Circle()
                .strokeBorder(Color.green, lineWidth: 4)
                .frame(width: 80, height: 80)
            Circle()
                .strokeBorder(Color.orange.opacity(0.6), lineWidth: 4)
                .frame(width: 70, height: 70)
            Circle()
                .fill(Color.clear)
                .frame(width: 60, height: 60)
                .overlay(
                    Group {
                        if let url = auth.user?.photoURL {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Circle().fill(Color.pink).frame(width: 60, height: 60)
                        }
                    }
                )
        }
    }

    private func pillStat(number: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(number)
                .foregroundColor(.white)
                .font(.title3.bold())
            Text(label)
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func primaryFilledButton(title: String) -> some View {
        Button(action: {
            if title == "Editar Perfil" {
                showEditProfile = true
            }
        }) {
            Text(title)
                .foregroundColor(.white)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .background(
            LinearGradient(colors: [Color.green.opacity(0.95), Color.green.opacity(0.75)], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(Capsule())
        .shadow(color: .green.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private func primaryOutlinedButton(title: String) -> some View {
        Button(action: {
            let isRestaurant = (auth.user?.role ?? "client") == "restaurant"
            if isRestaurant, title == "Editar Menú" {
                showEditMenu = true
            }
        }) {
            Text(title)
                .foregroundColor(.white)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .background(Color.clear)
        .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
        .clipShape(Capsule())
    }

    private func segmentedControl() -> some View {
        HStack(spacing: 12) {
            segmentButton(icon: "square.grid.2x2", index: 0)
            segmentButton(icon: "heart", index: 1)
            segmentButton(icon: "bookmark", index: 2)
        }
        .padding(8)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func segmentButton(icon: String, index: Int) -> some View {
        let isSelected = selectedSegment == index
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedSegment = index }
        } label: {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 36, height: 28)
                .background(isSelected ? Color.green.opacity(0.35) : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func galleryGrid() -> some View {
        let side = floor((UIScreen.main.bounds.width - 32 - 4) / 3)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
            ForEach(imageUrls, id: \.self) { urlStr in
                ZStack {
                    if let url = URL(string: urlStr) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .overlay(Rectangle().fill(Color.black.opacity(0.08)))
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                    }
                }
                .frame(width: side, height: side)
                .clipped()
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func avatarDrawing() -> some View {
        ZStack {
            Circle()
                .fill(Color(red: 1.0, green: 0.92, blue: 0.85))
                .frame(width: 48, height: 48)
                .offset(y: 3)
            HStack(spacing: 8) {
                Circle().fill(Color.black).frame(width: 5, height: 5)
                Circle().fill(Color.black).frame(width: 5, height: 5)
            }
            .offset(y: -6)
            Capsule()
                .fill(Color.green)
                .frame(width: 18, height: 5)
                .offset(y: 8)
        }
    }
}

private struct SettingsScreen: View {
    let onClose: () -> Void
    @State private var pushEnabled: Bool = true
    @State private var darkModeEnabled: Bool = true
    @State private var showSub: Subscreen? = nil

    enum Subscreen { case notifications, privacy, language, payments, security, help }

    private func header() -> some View {
        HStack {
            Button(action: onClose) {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
            }
            Spacer()
            Text("Configuración")
                .foregroundColor(.white)
                .font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func iconCircle(_ name: String) -> some View {
        Circle()
            .fill(Color.green.opacity(0.2))
            .frame(width: 36, height: 36)
            .overlay(Image(systemName: name).foregroundColor(.green))
    }

    private func toggleRow(icon: String, title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconCircle(icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.white).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.white.opacity(0.8)).font(.caption)
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(.green)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func navRowButton(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconCircle(icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).foregroundColor(.white).font(.subheadline.bold())
                    Text(subtitle).foregroundColor(.white.opacity(0.8)).font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    toggleRow(icon: "bell", title: "Notificaciones", subtitle: "Recibir notificaciones push", binding: $pushEnabled)
                    toggleRow(icon: "moon", title: "Modo Oscuro", subtitle: "Tema de la aplicación", binding: $darkModeEnabled)
                    navRowButton(icon: "bell", title: "Notificaciones", subtitle: "Configura tus preferencias") { showSub = .notifications }
                    navRowButton(icon: "lock", title: "Privacidad", subtitle: "Controla tu privacidad") { showSub = .privacy }
                    navRowButton(icon: "globe", title: "Idioma", subtitle: "Español") { showSub = .language }
                    navRowButton(icon: "creditcard", title: "Pagos", subtitle: "Métodos de pago") { showSub = .payments }
                    navRowButton(icon: "shield", title: "Seguridad", subtitle: "Contraseña y autenticación") { showSub = .security }
                    navRowButton(icon: "questionmark.circle", title: "Ayuda", subtitle: "Centro de ayuda y soporte") { showSub = .help }

                    VStack(spacing: 6) {
                        Text("Versión de la aplicación").foregroundColor(.white.opacity(0.8)).font(.caption).multilineTextAlignment(.center)
                        Text("Foodtook v1.0.0").foregroundColor(.white).font(.subheadline.bold()).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button(action: { AuthService.shared.signOut() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .foregroundColor(.red)
                            Text("Cerrar Sesión")
                                .foregroundColor(.red)
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(isPresented: Binding(get: { showSub != nil }, set: { if !$0 { showSub = nil } })) {
            switch showSub {
            case .notifications:
                NotificationsSettingsView(onClose: { showSub = nil })
            case .privacy:
                PrivacySettingsView(onClose: { showSub = nil })
            case .language:
                LanguageSettingsView(onClose: { showSub = nil })
            case .payments:
                PaymentMethodsView(onClose: { showSub = nil })
            case .security:
                SecuritySettingsView(onClose: { showSub = nil })
            case .help:
                HelpSupportView(onClose: { showSub = nil })
            case .none:
                EmptyView()
            }
        }
    }
}

private struct NotificationsSettingsView: View {
    let onClose: () -> Void
    @State private var pushOn = true
    @State private var emailOn = true
    @State private var smsOn = false
    @State private var ordersOn = true
    @State private var promosOn = true
    @State private var newRestaurantsOn = false
    @State private var recommendationsOn = true

    private func sectionTitle(_ text: String) -> some View {
        HStack { Text(text).foregroundColor(.white).font(.subheadline.bold()); Spacer() }
    }

    private func cardToggle(title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.white).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.white.opacity(0.8)).font(.caption)
            }
            Spacer()
            Toggle("", isOn: binding).labelsHidden().tint(.green)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.white)) }
            Spacer()
            Text("Notificaciones").foregroundColor(.white).font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    sectionTitle("General")
                    cardToggle(title: "Notificaciones Push", subtitle: "Recibir notificaciones en tu dispositivo", binding: $pushOn)
                    cardToggle(title: "Email", subtitle: "Recibir notificaciones por correo", binding: $emailOn)
                    cardToggle(title: "SMS", subtitle: "Recibir notificaciones por mensaje", binding: $smsOn)
                    sectionTitle("Pedidos")
                    cardToggle(title: "Actualizaciones de pedidos", subtitle: "Estado de tus pedidos", binding: $ordersOn)
                    sectionTitle("Marketing")
                    cardToggle(title: "Promociones", subtitle: "Ofertas y descuentos especiales", binding: $promosOn)
                    cardToggle(title: "Nuevos restaurantes", subtitle: "Cuando se agregan nuevos lugares", binding: $newRestaurantsOn)
                    cardToggle(title: "Recomendaciones", subtitle: "Sugerencias personalizadas", binding: $recommendationsOn)
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct PrivacySettingsView: View {
    let onClose: () -> Void
    @State private var profileVisible = true
    @State private var showLocation = true
    @State private var showActivity = false
    @State private var allowMessages = true
    @State private var onlineStatus = true

    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.white)) }
            Spacer()
            Text("Privacidad").foregroundColor(.white).font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func cardToggle(title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.white).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.white.opacity(0.8)).font(.caption)
            }
            Spacer()
            Toggle("", isOn: binding).labelsHidden().tint(.green)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    cardToggle(title: "Perfil visible", subtitle: "Permitir que otros vean tu perfil", binding: $profileVisible)
                    cardToggle(title: "Mostrar ubicación", subtitle: "Compartir tu ubicación actual", binding: $showLocation)
                    cardToggle(title: "Mostrar actividad", subtitle: "Permitir ver tu actividad reciente", binding: $showActivity)
                    cardToggle(title: "Permitir mensajes", subtitle: "Recibir mensajes de otros usuarios", binding: $allowMessages)
                    cardToggle(title: "Estado en línea", subtitle: "Mostrar cuando estás activo", binding: $onlineStatus)
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct LanguageSettingsView: View {
    let onClose: () -> Void
    @State private var selected: String = "Español"
    private let items: [(String, String)] = [
        ("Español", "Español"),
        ("English", "English"),
        ("Français", "French"),
        ("Deutsch", "German"),
        ("Italiano", "Italian"),
        ("Português", "Portuguese"),
        ("中文", "Chinese"),
        ("日本語", "Japanese"),
        ("한국어", "Korean")
    ]

    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.white)) }
            Spacer()
            Text("Idioma").foregroundColor(.white).font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func row(primary: String, secondary: String) -> some View {
        let isSelected = selected == primary
        return Button {
            selected = primary
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(primary).foregroundColor(.white).font(.subheadline.bold())
                    Text(secondary).foregroundColor(.white.opacity(0.8)).font(.caption)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark").foregroundColor(.green) }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.18) : Color.white.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.green : Color.clear, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(items, id: \.0) { item in
                        row(primary: item.0, secondary: item.1)
                    }
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct PaymentMethodsView: View {
    let onClose: () -> Void
    @State private var methods: [(String, String)] = [
        ("Visa •••• 4242", "Expira 12/25"),
        ("Mastercard •••• 5555", "Expira 06/26")
    ]

    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.white)) }
            Spacer()
            Text("Métodos de Pago").foregroundColor(.white).font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func methodRow(title: String, subtitle: String, onDelete: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.green.opacity(0.2)).frame(width: 36, height: 36).overlay(Image(systemName: "creditcard").foregroundColor(.green))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.white).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.white.opacity(0.8)).font(.caption)
            }
            Spacer()
            Button("Eliminar", action: onDelete)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func addButton() -> some View {
        Button(action: { methods.append(("Nueva tarjeta •••• 0000", "Expira 01/27")) }) {
            HStack(spacing: 8) {
                Image(systemName: "plus").foregroundColor(.white)
                Text("Agregar método de pago").foregroundColor(.white).font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(style: StrokeStyle(lineWidth: 1, dash: [4])).foregroundColor(.white.opacity(0.6)))
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(methods.enumerated()), id: \.offset) { idx, m in
                        methodRow(title: m.0, subtitle: m.1) {
                            methods.remove(at: idx)
                        }
                    }
                    addButton()
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct SecuritySettingsView: View {
    let onClose: () -> Void
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var twoFAEnabled: Bool = false

    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.white)) }
            Spacer()
            Text("Seguridad").foregroundColor(.white).font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack { Text(text).foregroundColor(.white).font(.subheadline.bold()); Spacer() }
    }

    private func field(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).foregroundColor(.white.opacity(0.8)).font(.caption)
            SecureField("", text: text)
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func deviceRow(title: String, time: String, location: String, trailing: AnyView) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.white).font(.subheadline.bold())
                Text("Última actividad: \(time)").foregroundColor(.white.opacity(0.8)).font(.caption)
                Text(location).foregroundColor(.white.opacity(0.8)).font(.caption)
            }
            Spacer()
            trailing
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    sectionTitle("Cambiar contraseña")
                    field(label: "Contraseña actual", text: $currentPassword)
                    field(label: "Nueva contraseña", text: $newPassword)
                    field(label: "Confirmar contraseña", text: $confirmPassword)
                    Button(action: {}) {
                        Text("Actualizar contraseña").foregroundColor(.black).font(.subheadline.bold()).frame(maxWidth: .infinity).padding()
                    }
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    sectionTitle("Autenticación de dos factores")
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("2FA").foregroundColor(.white).font(.subheadline.bold())
                            Text("Mayor seguridad para tu cuenta").foregroundColor(.white.opacity(0.8)).font(.caption)
                        }
                        Spacer()
                        Toggle("", isOn: $twoFAEnabled).labelsHidden().tint(.green)
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    sectionTitle("Sesiones activas")
                    deviceRow(title: "iPhone 15 Pro", time: "Ahora", location: "Ciudad de México, México", trailing: AnyView(Text("Actual").foregroundColor(.white).font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 4).background(Color.green).clipShape(Capsule())))
                    deviceRow(title: "MacBook Pro", time: "Hace 2 horas", location: "Ciudad de México, México", trailing: AnyView(Button("Cerrar sesión", action: {}).foregroundColor(.red)))
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct HelpSupportView: View {
    let onClose: () -> Void

    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.white)) }
            Spacer()
            Text("Ayuda y Soporte").foregroundColor(.white).font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func iconCircle(_ name: String) -> some View {
        Circle().fill(Color.green.opacity(0.2)).frame(width: 36, height: 36).overlay(Image(systemName: name).foregroundColor(.green))
    }

    private func navRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            iconCircle(icon)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.white).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.white.opacity(0.8)).font(.caption)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    navRow(title: "Preguntas frecuentes", subtitle: "Encuentra respuestas rápidas", icon: "questionmark.circle")
                    navRow(title: "Chat en vivo", subtitle: "Habla con soporte", icon: "message")
                    navRow(title: "Contactar por email", subtitle: "support@foodtook.com", icon: "envelope")
                    navRow(title: "Términos de servicio", subtitle: "Lee nuestros términos", icon: "doc.text")
                    navRow(title: "Política de privacidad", subtitle: "Cómo protegemos tus datos", icon: "lock.doc")

                    VStack(spacing: 6) {
                        Text("Versión de la aplicación").foregroundColor(.white.opacity(0.8)).font(.caption).multilineTextAlignment(.center)
                        Text("Foodtook v1.0.0").foregroundColor(.white).font(.subheadline.bold()).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private func sectionHeader(_ title: String) -> some View {
    HStack {
        Text(title).foregroundColor(.white).font(.title3.bold())
        Spacer()
    }
}
