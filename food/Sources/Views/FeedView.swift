import SwiftUI
import SDWebImageSwiftUI
import AVKit

struct FeedView: View {
    let bottomInset: CGFloat
    let onGlobalShowComments: ((Int, String) -> Void)?
    let isCommentsOverlayActive: Bool
    // MARK: - Propiedades Computadas para el Feed Híbrido
    // Combina los datos mockeados (legacy) con los videos reales de Firestore
    private var forYouItems: [FeedItem] {
        // Si hay videos reales cargados, los mostramos PRIMERO
        if !forYouVM.videos.isEmpty {
            return forYouVM.videos + legacyForYouItems
        }
        return legacyForYouItems
    }

    // Renombramos la lista estática original para no perderla (útil para demos)
    private let legacyForYouItems: [FeedItem] = [
        // 1. Foodie Review con historias (círculo verde)
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1",
            username: "Burger Master",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
            title: "🔥 Smash Burger Deluxe",
            description: "Juicy double patty with special sauce, crispy onions, and melted cheese. The perfect burger experience!",
            soundTitle: "Grill Beats • Burger Jam",
            likes: 12400,
            comments: 342,
            shares: 120
        ),
        // 2. Sponsored sin historias
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
            username: "Pizza Palace",
            label: .sponsored,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1568602471122-7832951cc4c5",
            title: "🍕 Pepperoni Feast",
            description: "Loaded with extra pepperoni, mozzarella, and our signature tomato sauce. Order now!",
            soundTitle: "Pizza Groove • Delivery Beat",
            likes: 8500,
            comments: 156,
            shares: 45
        ),
        // 3. Normal con historias (círculo verde)
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445",
            username: "Sushi Sensation",
            label: .none,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
            title: "🎌 Dragon Roll Supreme",
            description: "Fresh salmon, avocado, and cucumber wrapped in nori. Topped with eel sauce and sesame seeds.",
            soundTitle: "Tokyo Vibes • Sushi Flow",
            likes: 23100,
            comments: 890,
            shares: 430,
            videoUrl: "https://vz-eb3c7132-8b5.b-cdn.net/0f36fe06-1355-4596-a707-5bbf19b9e08c/playlist.m3u8",
            posterUrl: "https://vz-eb3c7132-8b5.b-cdn.net/0f36fe06-1355-4596-a707-5bbf19b9e08c/thumbnail_76c09eff.jpg"
        ),
        // 4. Foodie Review sin historias
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47",
            username: "Pasta Paradise",
            label: .foodieReview,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1547425260-76bcadfb4f2c",
            title: "🍝 Truffle Mushroom Pasta",
            description: "Creamy truffle sauce with wild mushrooms and parmesan. A gourmet experience!",
            soundTitle: "Italian Beats • Pasta Jam",
            likes: 15600,
            comments: 420,
            shares: 210
        ),
        // 5. Sponsored con historias (círculo verde)
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1559715745-e1b33a271c8f",
            username: "Dessert Heaven",
            label: .sponsored,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
            title: "🍰 Chocolate Lava Cake",
            description: "Warm chocolate cake with molten center. Served with vanilla ice cream.",
            soundTitle: "Sweet Melody • Dessert Mix",
            likes: 45000,
            comments: 1200,
            shares: 3500
        ),
        // 6. Normal sin historias
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1565958011703-44f9829ba187",
            username: "Salad Bar",
            label: .none,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
            title: "🥗 Superfood Bowl",
            description: "Quinoa, kale, avocado, nuts, and seeds with citrus vinaigrette. Healthy and delicious!",
            soundTitle: "Fresh Beats • Green Mix",
            likes: 5600,
            comments: 89,
            shares: 23
        ),
        // 7. Foodie Review con historias (círculo verde) - Mix completo
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1565299507177-b0ac66763828",
            username: "Taco Fiesta",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
            title: "🌮 Street Tacos Pack",
            description: "Authentic street-style tacos with your choice of meat, cilantro, onions, and lime.",
            soundTitle: "Fiesta Rhythm • Taco Beat",
            likes: 18900,
            comments: 670,
            shares: 890
        )
    ]
    
    private let followingItems: [FeedItem] = [
        // 1. Restaurante con historias (círculo verde)
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
            username: "BBQ Kingdom",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1560250097-0b93528c311a",
            title: "🔥 Smoked Brisket Plate",
            description: "14-hour smoked brisket with peppery bark, house pickles, and cornbread. Authentic Texas style!",
            soundTitle: "Smokehouse Beats • BBQ Jam",
            likes: 32100,
            comments: 1500,
            shares: 2100
        ),
        // 2. Sponsored sin historias
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1572802419224-296b0aeee0d9",
            username: "Green Delight",
            label: .sponsored,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61",
            title: "🥗 Power Bowl",
            description: "Superfood salad with quinoa, roasted vegetables, and tahini dressing. Fuel your day!",
            soundTitle: "Healthy Vibes • Green Mix",
            likes: 4200,
            comments: 120,
            shares: 45
        ),
        // 3. Normal con historias (círculo verde)
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1551504734-b464e32a163a",
            username: "Taco Express",
            label: .none,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1519244703995-f4e0f30006d5",
            title: "🌮 Street Taco Box",
            description: "Authentic street tacos with your choice of meat, fresh cilantro, onions, and lime wedges.",
            soundTitle: "Street Beats • Taco Flow",
            likes: 14500,
            comments: 340,
            shares: 180
        ),
        // 4. Foodie Review sin historias
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e",
            username: "Sandwich Artisans",
            label: .foodieReview,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
            title: "🥪 Ultimate Club",
            description: "Triple-decker with turkey, bacon, avocado, tomato, and special sauce. Served with chips.",
            soundTitle: "Delicious Beats • Sandwich Jam",
            likes: 9800,
            comments: 230,
            shares: 120
        ),
        // 5. Sponsored con historias (círculo verde)
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1559715745-e1b33a271c8f",
            username: "Sweet Corner",
            label: .sponsored,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1544725176-7c40e5a71c5e",
            title: "🍩 Donut Variety",
            description: "Freshly baked donuts with various glazes and toppings. Perfect with coffee!",
            soundTitle: "Sweet Melody • Donut Mix",
            likes: 28900,
            comments: 980,
            shares: 1500
        ),
        // 6. Normal sin historias
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591",
            username: "Pizza Corner",
            label: .none,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
            title: "🍕 Margherita Classic",
            description: "Traditional pizza with fresh mozzarella, tomato sauce, and basil. Simple and delicious!",
            soundTitle: "Italian Beats • Pizza Flow",
            likes: 11200,
            comments: 450,
            shares: 320
        ),
        // 7. Foodie Review con historias (círculo verde) - Mix completo
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
            username: "Gourmet Burgers",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
            title: "🍔 Signature Burger",
            description: "Gourmet beef patty with aged cheddar, caramelized onions, and truffle aioli. Served with fries.",
            soundTitle: "Gourmet Beats • Burger Mix",
            likes: 34500,
            comments: 1100,
            shares: 2300
        )
    ]
    
    private var currentItems: [FeedItem] { activeTab == .foryou ? forYouItems : followingItems }

    @State private var activeTab: ActiveTab = .foryou
    private enum ActiveTab { case following, foryou }

    @StateObject private var forYouVM = FeedViewModel(storageKey: "feed.forYou.index")
    @StateObject private var followingVM = FeedViewModel(storageKey: "feed.following.index")
    private var selectedVM: FeedViewModel { activeTab == .foryou ? forYouVM : followingVM }
    private var selectedIndexBinding: Binding<Int> {
        Binding(
            get: { 
                // Asegurar que el índice no exceda el count actual para evitar crash de rango
                let idx = activeTab == .foryou ? forYouVM.currentIndex : followingVM.currentIndex
                let maxIdx = max(0, currentItems.count - 1)
                return min(idx, maxIdx)
            },
            set: { newValue in
                if activeTab == .foryou {
                    forYouVM.currentIndex = newValue
                } else {
                    followingVM.currentIndex = newValue
                }
            }
        )
    }

    @State private var showRestaurantProfile = false
    @State private var showUserProfile = false
    @State private var selectedUserId: String? = nil // Nuevo estado para navegación dinámica
    @State private var showMenu = false
    @State private var showComments = false
    @State private var showShare = false
    @State private var showMusic = false
    @State private var expandedDescriptions: Set<UUID> = []

    init(bottomInset: CGFloat, onGlobalShowComments: ((Int, String) -> Void)? = nil, isCommentsOverlayActive: Bool = false) {
        self.bottomInset = bottomInset
        self.onGlobalShowComments = onGlobalShowComments
        self.isCommentsOverlayActive = isCommentsOverlayActive
    }

    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            
            ZStack {
                // PAGER PRINCIPAL
                VerticalPager(
                    count: currentItems.count,
                    index: selectedIndexBinding,
                    pageHeight: totalHeight,
                    onPullToRefresh: {
                        // Acción de refresco
                        selectedVM.loadRecentVideos(reset: true)
                    }
                ) { size, idx in
                    let item = currentItems[idx]
                    FeedItemView(
                        item: item,
                        size: size,
                        bottomInset: bottomInset,
                        expandedDescriptions: $expandedDescriptions,
                        isCommentsOverlayActive: isCommentsOverlayActive,
                        isActive: idx == selectedVM.currentIndex,
                        isScreenActive: !(showRestaurantProfile || showUserProfile || showMenu),
                        onShowProfile: {
                            // Lógica de navegación a perfiles
                            if let authorId = item.authorId {
                                // 🚀 Usuario Real: Navegar al perfil público dinámico
                                selectedUserId = authorId
                                showUserProfile = true
                            } else if item.label == .foodieReview {
                                // Legacy: Foodie Mock
                                selectedUserId = nil // Indicador de mock
                                showUserProfile = true
                            } else {
                                // Legacy: Restaurant Mock
                                showRestaurantProfile = true
                            }
                        },
                        onShowMenu: { showMenu = true },
                        onShowComments: { onGlobalShowComments?(item.comments, item.backgroundUrl) },
                        onShowShare: { withAnimation(.easeOut(duration: 0.25)) { showShare = true } },
                        onShowMusic: { showMusic = true }
                    )
                }
                .frame(height: totalHeight)
                .ignoresSafeArea()
                
                // OVERLAYS MODALES
                overlays
                topTabs
                    .frame(maxWidth: .infinity)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.15)
            }
            .background(Color.black.ignoresSafeArea())
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            selectedVM.currentIndex = min(selectedVM.currentIndex, max(currentItems.count - 1, 0))
            selectedVM.prefetch(urls: currentItems.map { $0.backgroundUrl })
        }
        .onDisappear {
            forYouVM.cancelPrefetch()
            followingVM.cancelPrefetch()
        }
        .onChange(of: activeTab) { _, _ in
            // 🛑 DETENER TODO EL AUDIO AL CAMBIAR DE TAB
            VideoPlayerCoordinator.shared.pauseAll()
            
            withAnimation(.easeInOut(duration: 0.2)) { }
            selectedVM.currentIndex = min(selectedVM.currentIndex, max(currentItems.count - 1, 0))
            selectedVM.prefetch(urls: currentItems.map { $0.backgroundUrl })
        }
        // 🚀 PRECARGA INTELIGENTE DE VIDEO
        // Cuando cambia el índice (scroll), iniciamos la carga del SIGUIENTE video
        .onChange(of: selectedIndexBinding.wrappedValue) { oldValue, newValue in
            let idx = newValue
            let items = currentItems
            guard idx >= 0 && idx < items.count else { return }
            
            // 1. Limpiar memoria (borrar videos lejanos)
            let currentUrl = items[idx].videoUrl
            let nextIdx = idx + 1
            let nextUrl = (nextIdx < items.count) ? items[nextIdx].videoUrl : nil
            
            if let c = currentUrl {
                VideoPrefetchService.shared.cleanup(currentItemUrl: c, nextItemUrl: nextUrl)
            }
            
            // 2. Precargar el SIGUIENTE video (buffer ~4 seg)
            if let n = nextUrl {
                VideoPrefetchService.shared.prefetch(url: n)
            }
        }
        .fullScreenCover(isPresented: $showRestaurantProfile) {
            let item = currentItems[min(selectedVM.currentIndex, max(currentItems.count - 1, 0))]
            let photos: [RestaurantProfileView.PhotoItem] = [
                .init(url: "https://images.unsplash.com/photo-1604908176997-431199f7c209", title: "Salsas mexicanas"),
                .init(url: "https://images.unsplash.com/photo-1612197528228-7d9d7e9db2e8", title: "Tacos variados"),
                .init(url: "https://images.unsplash.com/photo-1617191519200-3d5d4b8c9a27", title: "Quesadillas")
            ]
            RestaurantProfileView(
                data: .init(
                    coverUrl: item.backgroundUrl,
                    avatarUrl: item.avatarUrl,
                    name: item.username,
                    username: item.username.replacingOccurrences(of: " ", with: "").lowercased(),
                    location: "CDMX, México",
                    rating: 4.8,
                    category: "Comida Mexicana",
                    followers: 45200,
                    description: "Los auténticos tacos al pastor de la ciudad. Receta familiar desde 1985. Disfruta de la tradición en cada bocado 🌮✨",
                    branch: "Sucursal Condesa",
                    photos: photos
                ),
                onRefresh: {
                    try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
                    let newPhotos: [RestaurantProfileView.PhotoItem] = [
                        .init(url: "https://images.unsplash.com/photo-1600891964599-f61ba0e24092", title: "Guacamole fresco"),
                        .init(url: "https://images.unsplash.com/photo-1605475121025-6520df4cf73e", title: "Enchiladas verdes"),
                        .init(url: "https://images.unsplash.com/photo-1589308078053-02051b89c1a3", title: "Pozole tradicional")
                    ]
                    return .init(
                        coverUrl: item.backgroundUrl,
                        avatarUrl: item.avatarUrl,
                        name: item.username,
                        username: item.username.replacingOccurrences(of: " ", with: "").lowercased(),
                        location: "CDMX, México",
                        rating: 4.8,
                        category: "Comida Mexicana",
                        followers: 45200,
                        description: "Los auténticos tacos al pastor de la ciudad. Receta familiar desde 1985. Disfruta de la tradición en cada bocado 🌮✨",
                        branch: "Sucursal Condesa",
                        photos: newPhotos
                    )
                }
            )
        }
        .fullScreenCover(isPresented: $showUserProfile) {
            // Decidir qué perfil mostrar (Real vs Mock)
            if let uid = selectedUserId {
                // ✅ Perfil Real Conectado
                UserProfileView(userId: uid)
            } else {
                // ⚠️ Legacy Mock Profile (Mantenemos para demos)
                let item = currentItems[min(selectedVM.currentIndex, max(currentItems.count - 1, 0))]
                // ... (código legacy mock se mantiene pero inaccesible si hay selectedUserId)
                // Para simplificar y evitar duplicar lógica de mock compleja aquí,
                // si es mock, usamos una versión "dummy" del UserProfileView nuevo o el viejo si pudiéramos
                // Pero como UserProfileView cambió su init, necesitamos un adaptador si queremos mantener mocks.
                // Por ahora, asumiremos que si es mock, no cargará datos reales y mostrará loading o error,
                // OJO: El UserProfileView nuevo REQUIERE un ID real.
                
                // FIX: Para no romper los mocks existentes, pasamos un ID falso "mock_user"
                // y el ViewModel debería manejarlo (o simplemente fallar gracefuly).
                // Lo ideal sería migrar los mocks a datos reales en Firebase, pero por tiempo:
                UserProfileView(userId: "mock_user") 
            }
        }
        .fullScreenCover(isPresented: $showMenu) {
            let item = currentItems[min(selectedVM.currentIndex, max(currentItems.count - 1, 0))]
            let rid = item.username.replacingOccurrences(of: " ", with: "").lowercased()
            FullMenuView(
                restaurantId: rid,
                restaurantName: item.username,
                coverUrl: item.backgroundUrl,
                avatarUrl: item.avatarUrl,
                location: "CDMX, México",
                branchName: "CDMX, México",
                distanceKm: 2.3
            )
        }
    }

    private var topTabs: some View {
        HStack(spacing: 12) {
            tabButton(icon: "person.2", title: "Siguiendo", isActive: activeTab == .following, indicatorColor: .red) {
                withAnimation(.easeInOut(duration: 0.2)) { activeTab = .following }
            }
            tabButton(icon: "flame", title: "Para Ti", isActive: activeTab == .foryou, indicatorColor: .green) {
                withAnimation(.easeInOut(duration: 0.2)) { activeTab = .foryou }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }

    private func tabButton(icon: String, title: String, isActive: Bool, indicatorColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(0.6))
                
                Text(title)
                    .foregroundColor(isActive ? .white : .white.opacity(0.7))
                    .font(.system(size: 14, weight: .semibold))
                    .scaleEffect(isActive ? 1.08 : 1.0)
                
                if isActive {
                    Capsule()
                    .fill(indicatorColor)
                    .frame(width: 24, height: 3)
                    .shadow(color: indicatorColor.opacity(0.9), radius: 6, x: 0, y: 1)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 24, height: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
    }

    private var overlays: some View {
        ZStack {
            if showComments {
                let idx = min(selectedVM.currentIndex, max(currentItems.count - 1, 0))
                let item = currentItems[idx]
                CommentsOverlayView(
                    count: item.comments,
                    onClose: { showComments = false },
                    videoId: item.videoId // ✅ Pasamos el ID real
                )
            }
            if showShare {
                ShareOverlayView(onClose: { withAnimation(.easeOut(duration: 0.25)) { showShare = false } })
            }
            if showMusic { SaveFoldersOverlayView(onClose: { withAnimation(.easeOut(duration: 0.25)) { showMusic = false } }, onSelect: { _ in
                withAnimation(.easeOut(duration: 0.25)) { showMusic = false }
            }) }
        }
        .animation(.easeInOut, value: showRestaurantProfile || showMenu || showComments || showShare || showMusic)
    }

    private func modalCard(title: String, onClose: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Capsule().fill(Color.white.opacity(0.2)).frame(width: 48, height: 5).padding(.top, 8)
            Text(title).foregroundColor(.white).font(.headline.bold())
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .frame(height: 200)
                .overlay(Text("Contenido visual").foregroundColor(.secondary))
            Button(action: onClose) {
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
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
    
    // MARK: - FeedItemView Unificado
    private struct FeedItemView: View {
        let item: FeedItem
        let size: CGSize
        let bottomInset: CGFloat
        @Binding var expandedDescriptions: Set<UUID>
        let isCommentsOverlayActive: Bool
        let isActive: Bool
        let isScreenActive: Bool
        
        // Callbacks
        let onShowProfile: () -> Void
        let onShowMenu: () -> Void
        let onShowComments: () -> Void
        let onShowShare: () -> Void
        let onShowMusic: () -> Void
        
        // State
        @State private var isLiked = false
        @State private var likesCount: Int
        @State private var isFollowing = false
        @State private var bottomSectionHeight: CGFloat = 0
        @State private var hapticLight = UIImpactFeedbackGenerator(style: .light)
        @State private var hapticMedium = UIImpactFeedbackGenerator(style: .medium)
        @State private var hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)
        
        // Coordinator
        @ObservedObject private var coordinator = VideoPlayerCoordinator.shared
        
        // Animation State
        @State private var showLikeHeart = false
        @State private var heartScale: CGFloat = 0.5
        @State private var heartOpacity: Double = 0
        @State private var heartAngle: Double = 0
        @State private var player: AVPlayer? = nil
        @State private var isPaused: Bool = false
        @State private var isMuted: Bool = false
        @State private var loadingTask: Task<Void, Never>? = nil // 🔴 Track loading task
        @State private var isVideoReady = false // 🔴 Track if video is actually rendering frames
        @State private var loopCancellable: AnyCancellable? = nil // 🔴 Fix Memory Leak

        // Quick Share
        struct QuickPerson: Identifiable { let id = UUID(); let name: String; let emoji: String }
        @State private var showQuickShare = false
        @State private var quickHighlighted: UUID? = nil
        @State private var quickSent: Set<UUID> = []
        @State private var isPressingShare = false
        @State private var quickShareWork: DispatchWorkItem? = nil
        @State private var isBookmarked = false
        @State private var showSavedToast = false
        private enum SavedToastMode { case saved, removed }
        @State private var toastMode: SavedToastMode = .saved
        @State private var lastSavedFolder: String = "Favoritos"
        @State private var toastWork: DispatchWorkItem? = nil
        private let bookmarkOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
        private let quickPeople: [QuickPerson] = [
            .init(name: "María", emoji: "👩"),
            .init(name: "Juan", emoji: "👨"),
            .init(name: "Laura", emoji: "👩")
        ]
        
        init(item: FeedItem, size: CGSize, bottomInset: CGFloat, expandedDescriptions: Binding<Set<UUID>>, isCommentsOverlayActive: Bool, isActive: Bool, isScreenActive: Bool, onShowProfile: @escaping () -> Void, onShowMenu: @escaping () -> Void, onShowComments: @escaping () -> Void, onShowShare: @escaping () -> Void, onShowMusic: @escaping () -> Void) {
            self.item = item
            self.size = size
            self.bottomInset = bottomInset
            self._expandedDescriptions = expandedDescriptions
            self.isCommentsOverlayActive = isCommentsOverlayActive
            self.isActive = isActive
            self.isScreenActive = isScreenActive
            self.onShowProfile = onShowProfile
            self.onShowMenu = onShowMenu
            self.onShowComments = onShowComments
            self.onShowShare = onShowShare
            self.onShowMusic = onShowMusic
            _likesCount = State(initialValue: item.likes)
        }
        
        var body: some View {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    mediaView
                        .frame(width: size.width, height: isCommentsOverlayActive ? size.height * 0.35 : size.height)
                        .clipped()
                        .onTapGesture(count: 2) { handleDoubleTap() }
                        .onTapGesture {
                            guard item.videoUrl != nil else { return }
                            // 1. Toggle local state immediately for UI feedback
                            let willPause = !isPaused
                            withAnimation(.easeInOut(duration: 0.08)) { isPaused = willPause }
                            
                            // 2. Direct player control (bypass coordinator for pause)
                            if let p = player {
                                if willPause {
                                    p.pause()
                                } else {
                                    // Resume only if we are the active video
                                    if coordinator.activeVideoId == item.id {
                                        p.play()
                                    } else {
                                        // If we weren't active, become active
                                        coordinator.setActive(item.id)
                                        // Coordinator change will trigger updatePlayback -> play
                                    }
                                }
                            }
                        }
                    Spacer(minLength: 0)
                }
                .frame(width: size.width, height: size.height)

                if !isCommentsOverlayActive {
                    LinearGradient(colors: [.black.opacity(0.2), .clear], startPoint: .bottom, endPoint: .top)
                        .allowsHitTesting(false)
                }

                if showLikeHeart && !isCommentsOverlayActive {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 100))
                        .shadow(color: .black.opacity(0.3), radius: 10)
                        .scaleEffect(heartScale)
                        .opacity(heartOpacity)
                        .rotationEffect(.degrees(heartAngle))
                        .frame(width: size.width, height: size.height, alignment: .center)
                        .allowsHitTesting(false)
                }

                if !isCommentsOverlayActive { leftColumn }
                if !isCommentsOverlayActive { rightColumn }
            }
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.25), value: isCommentsOverlayActive)
            .onAppear {
                hapticLight.prepare()
                hapticMedium.prepare()
                hapticHeavy.prepare()
                
                // Verificar si ya le di like
                checkLikeStatus()
                
                // 🚀 CARGA ASÍNCRONA OPTIMIZADA
                // No bloqueamos el hilo principal creando el AVPlayer inmediatamente
                if let u = item.videoUrl, let url = URL(string: u) {
                    
                    // 1. REVISAR CACHÉ (PRECARGA)
                    if let cachedItem = VideoPrefetchService.shared.getItem(for: u) {
                        // ¡Bingo! Ya tenemos el video precargado
                        setupPlayer(with: cachedItem)
                    } else {
                        // 2. Si no está en caché, cargar desde cero (Fallback)
                        loadingTask?.cancel() // Cancelar anterior
                        loadingTask = Task {
                            let asset = AVURLAsset(url: url)
                            // Cargar propiedades clave en background
                            let keys = ["playable", "duration", "tracks"]
                            try? await asset.loadValues(forKeys: keys)
                            
                            // Verificar cancelación
                            if Task.isCancelled { return }
                            
                            await MainActor.run {
                                // Verificar cancelación de nuevo por si acaso
                                if Task.isCancelled { return }
                                
                                let item = AVPlayerItem(asset: asset)
                                setupPlayer(with: item)
                            }
                        }
                    }
                }
            }
            .onDisappear {
                loadingTask?.cancel() // 🔴 STOP ZOMBIE LOAD
                loadingTask = nil
                
                // 🗑️ MEMORY NUKE: Destruir player inmediatamente al salir de pantalla
                if let p = player {
                    p.pause()
                    p.replaceCurrentItem(with: nil) // Liberar recursos del item
                }
                player = nil
                isVideoReady = false 
                
                // Si éramos el activo, soltamos el control
                if coordinator.activeVideoId == item.id {
                   // Opcional: coordinator.stop(item.id) 
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    // Nos volvimos activos -> Reclamar el audio
                    coordinator.setActive(item.id)
                    isPaused = false
                } else {
                    // Dejamos de ser activos -> Pausar localmente y resetear
                    if let p = player {
                        p.pause()
                        p.seek(to: .zero)
                    }
                    isPaused = false
                }
                // No llamamos updatePlayback aquí, reaccionaremos al cambio del coordinator
            }
            .onChange(of: coordinator.activeVideoId) { _, _ in updatePlayback() }
            .onChange(of: isScreenActive) { _, _ in updatePlayback() }
            .onChange(of: isPaused) { _, _ in updatePlayback() }
            .onChange(of: isMuted) { _, _ in updatePlayback() }
        }

        private func setupPlayer(with item: AVPlayerItem) {
            let p = AVPlayer(playerItem: item)
            p.automaticallyWaitsToMinimizeStalling = true
            p.isMuted = true
            
            // 🛑 MEMORY LEAK FIX: Use Combine for looping instead of block-based NotificationCenter
            // This ensures the observer is released when the view/cancellable is deallocated.
            loopCancellable = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: p.currentItem)
                .sink { [weak p] _ in
                    p?.seek(to: .zero)
                    p?.play()
                }
            
            self.player = p
            
            // Simular "ready" tras un breve delay si el status es bueno, 
            // o esperar a que el observer de timeControlStatus nos diga que fluye.
            // Para feedback instantáneo mejoramos la percepción visual:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { isVideoReady = true }
            }
            
            if isActive && isScreenActive {
                coordinator.setActive(self.item.id)
            }
        }

        private func checkLikeStatus() {
            guard let videoId = item.videoId, let userId = AuthService.shared.user?.uid else { return }
            DatabaseService.shared.checkIfUserLiked(videoId: videoId, userId: userId) { liked in
                DispatchQueue.main.async {
                    self.isLiked = liked
                }
            }
        }

        private func handleDoubleTap() {
            guard !isCommentsOverlayActive else { return }
            hapticHeavy.prepare()
            hapticHeavy.impactOccurred()

            // Configurar animación aleatoria
            heartAngle = Double.random(in: -15...15)
            heartScale = 0.5
            heartOpacity = 0
            showLikeHeart = true
            
            // Actualizar estado de like si es necesario
            if !isLiked {
                toggleLike()
            }
            
            // Secuencia de animación
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                heartScale = 1.3
                heartOpacity = 1
            }
            
            // Desvanecer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    heartScale = 0.8
                    heartOpacity = 0
                }
            }
            
            // Limpiar vista
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showLikeHeart = false
            }
        }
        
        private func toggleLike() {
            guard let videoId = item.videoId, let userId = AuthService.shared.user?.uid else {
                // Si no hay sesión o video ID real, solo hacemos toggle visual local
                isLiked.toggle()
                likesCount += isLiked ? 1 : -1
                return
            }
            
            // Optimistic update
            isLiked.toggle()
            likesCount += isLiked ? 1 : -1
            
            if isLiked {
                DatabaseService.shared.likeVideo(videoId: videoId, userId: userId) { _ in }
            } else {
                DatabaseService.shared.unlikeVideo(videoId: videoId, userId: userId) { _ in }
            }
        }
        
        private var leftColumn: some View {
            let hasRing = item.label == .foodieReview || item.hasStories
            let ringColor: Color = item.label == .foodieReview ? .yellow : .green
            let labelText: String? = {
                switch item.label {
                case .sponsored: return "SPONSORED"
                case .foodieReview: return "FOODIE REVIEW"
                case .none: return nil
                }
            }()
            let labelColor: Color = item.label == .foodieReview ? .yellow : .gray
            let isExpanded = expandedDescriptions.contains(item.id)
            
            return VStack {
                Spacer()
                ZStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                                    WebImage(url: URL(string: item.avatarUrl))
                                        .resizable()
                                        .scaledToFill()
                                }
                                .frame(width: 53, height: 53)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(hasRing ? ringColor : .clear, lineWidth: hasRing ? 2 : 0)
                                )
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 8) {
                                        Button(action: onShowProfile) {
                                            Text(item.username)
                                                .foregroundColor(.white)
                                                .font(.system(size: 20, weight: .bold))
                                        }
                                        Button(action: { isFollowing.toggle() }) {
                                            Capsule()
                                                .fill(isFollowing ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                                                .frame(width: 90, height: 32)
                                                .overlay(Text(isFollowing ? "Siguiendo" : "Seguir").foregroundColor(.white).font(.footnote.bold()))
                                        }
                                    }
                                    if let labelText = labelText {
                                        Text(labelText)
                                            .foregroundColor(labelColor)
                                            .font(.footnote)
                                            .fontWeight(.heavy)
                                    }
                                }
                            }
                            
                            Text(item.title)
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                            
                            Text(item.description)
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 14))
                                .lineLimit(isExpanded ? nil : 2)
                                .truncationMode(.tail)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: size.width * 0.5, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isExpanded { expandedDescriptions.remove(item.id) } else { expandedDescriptions.insert(item.id) }
                                }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "music.note")
                                    .foregroundColor(.white)
                                Text(item.soundTitle)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                    .lineLimit(1)
                            }
                            
                            HStack(spacing: 10) {
                                Button(action: onShowMenu) {
                                    Capsule()
                                        .fill(Color.green)
                                        .frame(width: 216, height: 48)
                                        .overlay(Text("Ordenar Ahora").foregroundColor(.white).font(.system(size: 14, weight: .bold)))
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, bottomInset - 24)
            }
        }
        
        private var rightColumn: some View {
            VStack(spacing: 24) {
                // Eliminado: controles de pausa/audio en columna derecha para no afectar el layout
                // Like button
                VStack(spacing: 6) {
                    ZStack {
                        Button(action: {
                            toggleLike()
                            hapticLight.prepare()
                            hapticLight.impactOccurred()
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .foregroundColor(isLiked ? .red : .white)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                                .scaleEffect(isLiked ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)
                        }
                        Color.clear
                            .frame(width: 48, height: 48)
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture().onEnded {
                                    toggleLike()
                                    hapticLight.prepare()
                                    hapticLight.impactOccurred()
                                }
                            )
                    }
                    Text(formatCount(likesCount))
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .medium))
                }
                
                // Comment button
                VStack(spacing: 6) {
                    ZStack {
                        Button(action: onShowComments) {
                            Image(systemName: "bubble.left")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                        }
                        Color.clear
                            .frame(width: 48, height: 48)
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture().onEnded {
                                    onShowComments()
                                }
                            )
                    }
                    Text(formatCount(item.comments))
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .medium))
                }
                
                // Bookmark button
                ZStack {
                    Button(action: {
                        isBookmarked.toggle()
                        hapticMedium.prepare()
                        hapticMedium.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { }
                        presentToast(isBookmarked ? .saved : .removed)
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 28)
                            .foregroundColor(isBookmarked ? bookmarkOrange : .white)
                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                            .scaleEffect(isBookmarked ? 1.06 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isBookmarked)
                    }
                    Color.clear
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            TapGesture().onEnded {
                                isBookmarked.toggle()
                                hapticMedium.prepare()
                                hapticMedium.impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { }
                                presentToast(isBookmarked ? .saved : .removed)
                            }
                        )
                }
                
                // Share button
                VStack(spacing: 6) {
                    ZStack {
                        Button(action: onShowShare) {
                            Image(systemName: "paperplane")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                        }
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .center) { if showQuickShare { quickShareRadial } }
                        Color.clear
                            .frame(width: 48, height: 48)
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture().onEnded {
                                    onShowShare()
                                }
                            )
                            .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                                if pressing {
                                    isPressingShare = true
                                    quickShareWork?.cancel()
                                    let work = DispatchWorkItem {
                                        if isPressingShare && !showQuickShare {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showQuickShare = true }
                                        }
                                    }
                                    quickShareWork = work
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
                                } else {
                                    isPressingShare = false
                                    quickShareWork?.cancel()
                                    if showQuickShare {
                                        if let h = quickHighlighted {
                                            quickSent = [h]
                                            hapticMedium.prepare()
                                            hapticMedium.impactOccurred()
                                        }
                                        withAnimation(.easeOut(duration: 0.2)) { showQuickShare = false }
                                        quickHighlighted = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { quickSent.removeAll() }
                                    }
                                }
                            }) {}
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard showQuickShare else { return }
                                let p = value.location
                                let targets = quickTargetOffsets()
                                var newHighlight: UUID? = nil
                                for (id, off) in targets {
                                    let dx = p.x - (14 + off.x)
                                    let dy = p.y - (14 + off.y)
                                    let dist = CGFloat(hypot(Double(dx), Double(dy)))
                                    if dist < 36 { newHighlight = id }
                                }
                                if let h = newHighlight {
                                    quickHighlighted = h
                                    quickSent = [h]
                                } else {
                                    quickHighlighted = nil
                                    quickSent.removeAll()
                                }
                            }
                            .onEnded { _ in
                                guard showQuickShare else { return }
                                withAnimation(.easeOut(duration: 0.2)) { showQuickShare = false }
                                quickHighlighted = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { quickSent.removeAll() }
                            }
                    )
                    Text(formatCount(item.shares))
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, size.height * 0.55)
            .padding(.trailing, 16)
            .overlay(alignment: .bottom) {
                if showSavedToast && !isCommentsOverlayActive { savedToast }
            }
        }

        private func quickTargetOffsets() -> [UUID: CGPoint] {
            var map: [UUID: CGPoint] = [:]
            if quickPeople.count >= 3 {
                map[quickPeople[0].id] = CGPoint(x: -72, y: -48)
                map[quickPeople[1].id] = CGPoint(x: -92, y: 0)
                map[quickPeople[2].id] = CGPoint(x: -72, y: 48)
            }
            return map
        }

        private var mediaView: some View {
            Group {
                if let u = item.videoUrl, player != nil {
                    ZStack {
                        // 1. Imagen de fondo SIEMPRE visible hasta que el video esté listo
                        if let poster = item.posterUrl, let pu = URL(string: poster) {
                            AsyncImage(url: pu) { phase in
                                switch phase {
                                case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                                case .empty: Color.black
                                case .failure(_): Color.black
                                @unknown default: Color.black
                                }
                            }
                            .opacity(isVideoReady ? 0 : 1) // Desvanecer suavemente cuando esté listo
                            .animation(.easeOut(duration: 0.3), value: isVideoReady)
                        } else {
                            WebImage(url: URL(string: item.backgroundUrl))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(isVideoReady ? 0 : 1)
                                .animation(.easeOut(duration: 0.3), value: isVideoReady)
                        }
                        
                        // 2. Video Player
                        VideoPlayer(player: player)
                            .disabled(true)
                            .opacity(isVideoReady ? 1 : 0) // Aparecer suavemente
                            .animation(.easeIn(duration: 0.3), value: isVideoReady)
                        
                        if isPaused {
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 80, weight: .bold))
                                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 3)
                                .transition(.opacity)
                                .opacity(1.0)
                        }
                    }
                } else {
                    WebImage(url: URL(string: item.backgroundUrl))
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                }
            }
        }

        private func updatePlayback() {
            guard let p = player else { return }
            
            // Lógica Centralizada:
            // Solo reproducir si:
            // 1. El coordinador dice que somos el video activo (evita audios simultáneos)
            // 2. La pantalla está activa (no hay menús encima)
            // 3. El usuario no lo pausó manualmente
            let shouldPlay = (coordinator.activeVideoId == item.id) && isScreenActive && !isPaused
            
            if shouldPlay {
                // Solo llamar a play si no está reproduciendo para evitar overhead
                if p.rate == 0 && p.status == .readyToPlay { 
                    p.play() 
                }
                p.isMuted = false
            } else {
                if p.rate != 0 { p.pause() }
                // No silenciar si está pausado por el usuario, solo pausar
                // p.isMuted = true 
            }
        }

        private var quickShareRadial: some View {
            ZStack {
                ForEach(quickPeople) { person in
                    let off = quickTargetOffsets()[person.id] ?? .zero
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.90))
                                .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                                .frame(width: 46, height: 46)
                                .shadow(color: Color.black.opacity(0.6), radius: 6, x: 0, y: 4)
                            Text(person.emoji)
                                .font(.system(size: 22))
                            if quickSent.contains(person.id) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 46, height: 46)
                                    .overlay(Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 16, weight: .bold)))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        Text(person.name)
                            .foregroundColor(.white)
                            .font(.system(size: 11, weight: .medium))
                            .opacity(0.95)
                    }
                    .offset(x: off.x, y: off.y)
                    .scaleEffect(showQuickShare ? 1 : 0.8)
                    .opacity(showQuickShare ? 1 : 0)
                }
            }
            .frame(width: 180, height: 180)
            .contentShape(Rectangle())
        }

        private var savedToast: some View {
            HStack(spacing: 12) {
                Text(toastMode == .saved ? "Guardado en \(lastSavedFolder)" : "Quitado de \(lastSavedFolder)")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 0)
                if toastMode == .saved {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) { showSavedToast = false }
                        onShowMusic()
                    }) {
                        Text("Cambiar")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .bold))
                    }
                } else {
                    Button(action: {
                        isBookmarked = true
                        toastMode = .saved
                        withAnimation(.easeOut(duration: 0.2)) { showSavedToast = false }
                    }) {
                        Text("Deshacer")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.95)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        private func presentToast(_ mode: SavedToastMode) {
            toastWork?.cancel()
            let showNew = {
                toastMode = mode
                withAnimation(.easeOut(duration: 0.22)) { showSavedToast = true }
                let work = DispatchWorkItem {
                    withAnimation(.easeOut(duration: 0.2)) { showSavedToast = false }
                }
                toastWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: work)
            }
            if showSavedToast {
                withAnimation(.easeOut(duration: 0.18)) { showSavedToast = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { showNew() }
            } else {
                showNew()
            }
        }

        private func formatCount(_ count: Int) -> String {
            if count >= 1_000_000 {
                return String(format: "%.1fM", Double(count) / 1_000_000)
            } else if count >= 1_000 {
                return String(format: "%.1fK", Double(count) / 1_000)
            } else {
                return "\(count)"
            }
        }
    }
}
