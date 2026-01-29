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
    @State private var showFeed = false // New state for Feed side-navigation
    @State private var feedDragOffset: CGFloat = 0
    @State private var showFeedTrigger = false

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
                        // USER ROLE: Show FoodDiscoveryView as "Inicio"
                        FoodDiscoveryView(onClose: { })
                            .overlay(
                                // Feed Trigger (Left Side)
                                Group {
                                    if !showFeed {
                                        feedTriggerView
                                            .transition(.move(edge: .leading).combined(with: .opacity))
                                    }
                                }
                            )
                    }
                case .notifications: NotificationsScreen()
                case .store: StoreScreen()
                case .messages: MessagesListView()
                case .profile:
                    if (auth.user?.role ?? "client") == "restaurant" {
                        OwnProfileRestaurantView(
                            userId: auth.user?.uid ?? "",
                            initialCoverUrl: nil,
                            initialAvatarUrl: auth.user?.photoURL?.absoluteString,
                            initialName: auth.user?.name ?? auth.user?.username,
                            showBackButton: false
                        )
                    } else {
                        OwnProfileView(
                            userId: auth.user?.uid ?? "",
                            initialCoverUrl: nil,
                            initialAvatarUrl: auth.user?.photoURL?.absoluteString,
                            initialName: auth.user?.name ?? auth.user?.username,
                            showBackButton: false
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .padding(.bottom, tabBarHeight) // ← ESPACIO FIJO para el tab bar
            

            if showShop {
                // Legacy support or remove if completely replaced
                FoodDiscoveryView(onClose: { 
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showShop = false 
                    }
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }

            // TAB BAR
            bottomBar
                .background(Color(uiColor: .systemBackground))
                .zIndex(4)
                .offset(y: showFeed ? tabBarHeight + 50 : 0) // Hide when Feed is shown
                .animation(.easeOut(duration: 0.3), value: showFeed)

            // FEED VIEW OVERLAY (For User Role)
            if showFeed {
                FeedView(bottomInset: 0, onGlobalShowComments: { count, url in
                    commentsCount = count
                    currentFeedImageUrl = url
                    withAnimation(.easeOut(duration: 0.25)) { showCommentsOverlay = true }
                }, isCommentsOverlayActive: showCommentsOverlay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .zIndex(10) // Higher than everything
                .transition(.move(edge: .leading))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 { // Dragging left to close
                                feedDragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -100 { // Threshold to close
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showFeed = false
                                }
                            }
                            feedDragOffset = 0
                        }
                )
                .offset(x: feedDragOffset)
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
        // Removed forced preferredColorScheme to support both Light and Dark modes
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
        .background(Color(uiColor: .systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.05))
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
        .background(Color(uiColor: .systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.05))
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
            return AnyView(searchButton)
        }
    }
    
    private var searchButton: some View {
        centerAccentButton(icon: "magnifyingglass", title: "Buscar", color: Color(red: 244/255, green: 37/255, blue: 123/255)) {
            // No logic for now
        }
        .frame(maxWidth: .infinity)
    }

    private var feedTriggerView: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Invisible gesture area extended for easier grabbing
                Color.clear
                    .frame(width: 60, height: 300)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width > 20 { // Low threshold for ease
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        showFeed = true
                                    }
                                }
                            }
                    )
                
                // Visual Indicator (Pill)
                ZStack {
                    Capsule()
                        .fill(Color(red: 244/255, green: 37/255, blue: 123/255))
                        .frame(width: 16, height: 60)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                        .offset(x: 1)
                }
                .offset(x: -8) // Half hidden
                .shadow(color: Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.4), radius: 6, x: 2, y: 0)
                .scaleEffect(showFeedTrigger ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showFeedTrigger)
                .onAppear { showFeedTrigger = true }
            }
            .frame(width: 60, height: 300)
            .position(x: 30, y: geo.size.height * 0.45) // Slightly above middle
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
            // Eliminar animación de transición para usuarios normales
            let role = auth.user?.role ?? "client"
            if role == "restaurant" {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selected = tab
                }
            } else {
                // Transición instantánea para evitar doble animación
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
                                .foregroundColor(.primary).font(.subheadline.bold())
                            Text("$9.99")
                                .foregroundColor(.green).font(.footnote.bold())
                        }
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
        }
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
                        .foregroundColor(.primary)
                        .font(.title2.bold())
                    Text(auth.user?.bio ?? "")
                        .foregroundColor(.primary)
                        .font(.body)
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.primary)
                        Text(auth.user?.location ?? "")
                            .foregroundColor(.primary)
                            .font(.footnote)
                    }
                }
                        Spacer()
                    }
                    Divider().background(Color.primary.opacity(0.1))
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
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
        .background(Color(uiColor: .systemBackground))
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
                .foregroundColor(.primary)
                .font(.headline.bold())
            Spacer()
            Button { showSettings = true } label: {
                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "gearshape").foregroundColor(.primary))
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
                .foregroundColor(.primary)
                .font(.title3.bold())
            Text(label)
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
                .foregroundColor(.primary)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .background(Color.clear)
        .overlay(Capsule().stroke(Color.primary.opacity(0.6), lineWidth: 1))
        .clipShape(Capsule())
    }

    private func segmentedControl() -> some View {
        HStack(spacing: 12) {
            segmentButton(icon: "square.grid.2x2", index: 0)
            segmentButton(icon: "heart", index: 1)
            segmentButton(icon: "bookmark", index: 2)
        }
        .padding(8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func segmentButton(icon: String, index: Int) -> some View {
        let isSelected = selectedSegment == index
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedSegment = index }
        } label: {
            Image(systemName: icon)
                .foregroundColor(.primary)
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
                            .fill(Color.primary.opacity(0.06))
                    }
                }
                .frame(width: side, height: side)
                .clipped()
            }
        }
        .padding(2)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
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
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "arrow.backward").foregroundColor(.primary))
            }
            Spacer()
            Text("Configuración")
                .foregroundColor(.primary)
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
                Text(title).foregroundColor(.primary).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.secondary).font(.caption)
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(.green)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func navRowButton(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconCircle(icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).foregroundColor(.primary).font(.subheadline.bold())
                    Text(subtitle).foregroundColor(.secondary).font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
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
                        Text("Versión de la aplicación").foregroundColor(.secondary).font(.caption).multilineTextAlignment(.center)
                        Text("Foodtook v1.0.0").foregroundColor(.primary).font(.subheadline.bold()).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
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
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
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
        HStack { Text(text).foregroundColor(.primary).font(.subheadline.bold()); Spacer() }
    }

    private func cardToggle(title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.primary).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.secondary).font(.caption)
            }
            Spacer()
            Toggle("", isOn: binding).labelsHidden().tint(.green)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.primary.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.primary)) }
            Spacer()
            Text("Notificaciones").foregroundColor(.primary).font(.title3.bold())
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
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
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
            Button(action: onClose) { Circle().fill(Color.primary.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.primary)) }
            Spacer()
            Text("Privacidad").foregroundColor(.primary).font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func cardToggle(title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.primary).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.secondary).font(.caption)
            }
            Spacer()
            Toggle("", isOn: binding).labelsHidden().tint(.green)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
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
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
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
            Button(action: onClose) { Circle().fill(Color.primary.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.primary)) }
            Spacer()
            Text("Idioma").foregroundColor(.primary).font(.title3.bold())
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
                    Text(primary).foregroundColor(.primary).font(.subheadline.bold())
                    Text(secondary).foregroundColor(.secondary).font(.caption)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark").foregroundColor(.green) }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.18) : Color(uiColor: .secondarySystemGroupedBackground))
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
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
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
            Button(action: onClose) { Circle().fill(Color.primary.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.primary)) }
            Spacer()
            Text("Métodos de Pago").foregroundColor(.primary).font(.title3.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func methodRow(title: String, subtitle: String, onDelete: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.green.opacity(0.2)).frame(width: 36, height: 36).overlay(Image(systemName: "creditcard").foregroundColor(.green))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundColor(.primary).font(.subheadline.bold())
                Text(subtitle).foregroundColor(.secondary).font(.caption)
            }
            Spacer()
            Button("Eliminar", action: onDelete)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(methods, id: \.0) { method in
                        methodRow(title: method.0, subtitle: method.1) {
                            // Delete logic
                        }
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Agregar método de pago")
                        }
                        .foregroundColor(.green)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}

private struct SecuritySettingsView: View {
    let onClose: () -> Void
    
    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.primary.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.primary)) }
            Spacer()
            Text("Seguridad").foregroundColor(.primary).font(.title3.bold())
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
                    Text("Opciones de seguridad").foregroundColor(.secondary).font(.caption)
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}

private struct HelpSupportView: View {
    let onClose: () -> Void
    
    private func header() -> some View {
        HStack {
            Button(action: onClose) { Circle().fill(Color.primary.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.primary)) }
            Spacer()
            Text("Ayuda y Soporte").foregroundColor(.primary).font(.title3.bold())
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
                    Text("Centro de ayuda").foregroundColor(.secondary).font(.caption)
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}
