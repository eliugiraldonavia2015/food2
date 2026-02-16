import SwiftUI
import SDWebImageSwiftUI
import AVKit
import Combine

struct FeedView: View {
    let bottomInset: CGFloat
    let onGlobalShowComments: ((Int, String) -> Void)?
    let onShareOverlayChange: ((Bool) -> Void)? // ✅ Nuevo callback para notificar estado de share
    let isCommentsOverlayActive: Bool
    let isVisible: Bool // Controla si la vista es visible (aunque sea parcialmente)
    let isFullyOpen: Bool // ✅ Controla si la vista está 100% desplegada
    // MARK: - Propiedades Computadas para el Feed (SOLO REAL)
    private var forYouItems: [FeedItem] {
        return forYouVM.videos
    }
    
    private var introCardItem: FeedItem {
        FeedItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            backgroundUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836", // Comida oscura y elegante
            username: "Food2",
            label: .none,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1556910103-1c02745a30bf",
            title: "¿Listo para destapar el hambre?",
            description: "Desliza hacia abajo para descubrir los mejores platillos cerca de ti. 👇🔥",
            soundTitle: "Bienvenido a Food2",
            likes: 0,
            comments: 0,
            shares: 0,
            videoUrl: nil // 🛑 IMPORTANTE: Nil para que sea imagen estática
        )
    }
    
    private var followingItems: [FeedItem] {
        // 🔄 TEMPORAL: Usar mismo contenido que 'Para Ti' hasta implementar lógica de seguidos
        // Para revertir, cambiar a: return followingVM.videos
        return forYouVM.videos 
    }

    private var currentItems: [FeedItem] { activeTab == .foryou ? forYouItems : followingItems }

    @State private var activeTab: ActiveTab = .foryou
    private enum ActiveTab { case following, foryou }

    @ObservedObject var forYouVM: FeedViewModel
    @StateObject private var followingVM = FeedViewModel(storageKey: "feed.following.index")
    @StateObject private var coordinator = VideoPlayerCoordinator.shared
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
    @State private var selectedProfileImage: UIImage? = nil // 🚀 Imagen precargada para transición instantánea
    @State private var selectedItemForProfile: FeedItem? = nil // 🛑 Snapshot del item seleccionado para evitar condiciones de carrera
    @State private var showMenu = false
    @State private var showComments = false
    @State private var showShare = false
    @State private var showMusic = false
    @State private var showSearch = false // ✅ Nuevo estado para búsqueda
    @State private var expandedDescriptions: Set<UUID> = []

    init(viewModel: FeedViewModel, bottomInset: CGFloat, onGlobalShowComments: ((Int, String) -> Void)? = nil, onShareOverlayChange: ((Bool) -> Void)? = nil, isCommentsOverlayActive: Bool = false, isVisible: Bool = true, isFullyOpen: Bool = true) {
        self.forYouVM = viewModel
        self.bottomInset = bottomInset
        self.onGlobalShowComments = onGlobalShowComments
        self.onShareOverlayChange = onShareOverlayChange
        self.isCommentsOverlayActive = isCommentsOverlayActive
        self.isVisible = isVisible
        self.isFullyOpen = isFullyOpen
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
                        isShareOverlayActive: showShare,
                        isFullyOpen: isFullyOpen, // ✅ Pasar estado
                        isActive: idx == selectedVM.currentIndex,
                        isScreenActive: isVisible && !(showRestaurantProfile || showUserProfile || showMenu), // ✅ isVisible controla la reproducción
                        activeVideoId: coordinator.activeVideoId,
                        viewModel: selectedVM,
                        selectedItemForProfile: $selectedItemForProfile,
                        onShowProfile: { capturedImage in
                            // 📸 SNAPSHOT CRÍTICO: Guardamos el item y la imagen EXACTOS del momento del clic
                            self.selectedItemForProfile = item
                            self.selectedProfileImage = capturedImage
                            
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
                    .id(item.id)
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
        .onChange(of: showShare) { newValue in
            onShareOverlayChange?(newValue)
        }
        .onChange(of: activeTab) { _, _ in
            // 🛑 DETENER TODO EL AUDIO AL CAMBIAR DE TAB
            VideoPlayerCoordinator.shared.pauseAll()
            
            withAnimation(.easeInOut(duration: 0.2)) { }
            
            // 🧠 LOGICA INTELIGENTE DE SALTO:
            // Si cambiamos de tab, queremos mantener la posición relativa o saltar la intro.
            // Si el nuevo tab tiene la intro card (índice 0) y ya hemos visto contenido...
            // O simplemente forzar al usuario al primer video (índice 1) si viene de ver videos.
            
            var newIdx = activeTab == .foryou ? forYouVM.currentIndex : followingVM.currentIndex
            
            selectedVM.currentIndex = min(newIdx, max(currentItems.count - 1, 0))
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
            // Usar snapshot si existe, o fallback al índice actual (pero el snapshot es más seguro)
            let item = selectedItemForProfile ?? currentItems[min(selectedVM.currentIndex, max(currentItems.count - 1, 0))]
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
                    photos: photos,
                    cachedImage: selectedProfileImage
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
            .presentationBackground(.clear) // Make fullScreenCover background transparent
        }
        .fullScreenCover(isPresented: $showUserProfile) {
            // Decidir qué perfil mostrar (Real vs Mock)
            Group {
                if let uid = selectedUserId {
                    // ✅ Perfil Real Conectado
                    // Usar snapshot si existe, o fallback al índice actual
                    let item = selectedItemForProfile ?? currentItems[min(selectedVM.currentIndex, max(currentItems.count - 1, 0))]
                    UserProfileView(
                        userId: uid,
                        initialCoverUrl: item.backgroundUrl,
                        initialAvatarUrl: item.avatarUrl,
                        initialName: item.username,
                        cachedImage: selectedProfileImage
                    )
                } else {
                    // ⚠️ Legacy Mock Profile (Mantenemos para demos)
                    let item = selectedItemForProfile ?? currentItems[min(selectedVM.currentIndex, max(currentItems.count - 1, 0))]
                    UserProfileView(
                        userId: "mock_user",
                        initialCoverUrl: item.backgroundUrl,
                        initialAvatarUrl: item.avatarUrl,
                        initialName: item.username,
                        cachedImage: selectedProfileImage
                    ) 
                }
            }
        }
        .fullScreenCover(isPresented: $showMenu) {
            let item = selectedItemForProfile ?? currentItems[min(selectedVM.currentIndex, max(currentItems.count - 1, 0))]
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
        .fullScreenCover(isPresented: $showSearch) {
            SearchUsersView()
        }
    }

    private var topTabs: some View {
        ZStack {
            // Tabs Centrales
            HStack(spacing: 12) {
                tabButton(icon: "person.2", title: "Siguiendo", isActive: activeTab == .following, indicatorColor: .red) {
                    withAnimation(.easeInOut(duration: 0.2)) { activeTab = .following }
                }
                tabButton(icon: "flame", title: "Para Ti", isActive: activeTab == .foryou, indicatorColor: .green) {
                    withAnimation(.easeInOut(duration: 0.2)) { activeTab = .foryou }
                }
            }
            
            // Botón de Búsqueda (Alineado a la Derecha)
            HStack {
                Spacer()
                Button(action: { showSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.01)) // Hit area
                }
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
                .zIndex(30) // Match comments overlay z-index
            }
            if showShare {
                ShareOverlayView(onClose: { withAnimation(.easeOut(duration: 0.25)) { showShare = false } })
                    .zIndex(35) // Higher than comments to be safe, definitely covers feed trigger
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
        // ... (código existente)
        
        // MOVIDO: introCardOverlay ahora es parte de FeedItemView para que sea accesible
        private var introCardOverlay: some View {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("¿Listo para destapar el hambre?")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    Text("Desliza para descubrir")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    // Animación de Swipe Up
                    Image(systemName: "chevron.up")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: -10)
                        .padding(.top, 8)
                        .opacity(heartOpacity > 0 ? 0 : 1) // Reusamos heartOpacity o ignoramos opacidad
                        .modifier(SwipeAnimation()) 
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        
        // ... (resto del código)
        let item: FeedItem
        let size: CGSize
        let bottomInset: CGFloat
        @Binding var expandedDescriptions: Set<UUID>
        let isCommentsOverlayActive: Bool
        let isShareOverlayActive: Bool // ✅ Nuevo: para bloquear interacción
        let isFullyOpen: Bool // ✅ Controla si la vista está 100% desplegada
        let isActive: Bool
        let isScreenActive: Bool
        
        // Acceso al ViewModel para verificar índice real
        @ObservedObject var viewModel: FeedViewModel 
        
        // Callbacks
        let onShowProfile: (UIImage?) -> Void
        let onShowMenu: () -> Void
        let onShowComments: () -> Void
        let onShowShare: () -> Void
        let onShowMusic: () -> Void
        
        // State
        @State private var loadedImage: UIImage? = nil // 🚀 Imagen capturada del feed
        @State private var isLiked = false
        @Binding var selectedItemForProfile: FeedItem? // 🔗 Enlace al estado del padre
        @State private var likesCount: Int
        @State private var isFollowing = false
        @State private var showFollowButton = true
        @State private var orderPressed = false
        @State private var resolvedAuthorUid: String? = nil
        @State private var bottomSectionHeight: CGFloat = 0
        @State private var hapticLight = UIImpactFeedbackGenerator(style: .light)
        @State private var hapticMedium = UIImpactFeedbackGenerator(style: .medium)
        @State private var hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)
        
        // Coordinator
        private let coordinator = VideoPlayerCoordinator.shared
        let activeVideoId: UUID?
        
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
        @State private var readyCancellable: AnyCancellable? = nil
        @State private var activationTask: Task<Void, Never>? = nil // ⏳ Debounce Task

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
        
        init(item: FeedItem, size: CGSize, bottomInset: CGFloat, expandedDescriptions: Binding<Set<UUID>>, isCommentsOverlayActive: Bool, isShareOverlayActive: Bool, isFullyOpen: Bool, isActive: Bool, isScreenActive: Bool, activeVideoId: UUID?, viewModel: FeedViewModel, selectedItemForProfile: Binding<FeedItem?>, onShowProfile: @escaping (UIImage?) -> Void, onShowMenu: @escaping () -> Void, onShowComments: @escaping () -> Void, onShowShare: @escaping () -> Void, onShowMusic: @escaping () -> Void) {
            self.item = item
            self.size = size
            self.bottomInset = bottomInset
            self._expandedDescriptions = expandedDescriptions
            self.isCommentsOverlayActive = isCommentsOverlayActive
            self.isShareOverlayActive = isShareOverlayActive
            self.isFullyOpen = isFullyOpen
            self.isActive = isActive
            self.isScreenActive = isScreenActive
            self.activeVideoId = activeVideoId
            self.viewModel = viewModel
            self._selectedItemForProfile = selectedItemForProfile
            self.onShowProfile = onShowProfile
            self.onShowMenu = onShowMenu
            self.onShowComments = onShowComments
            self.onShowShare = onShowShare
            self.onShowMusic = onShowMusic
            _likesCount = State(initialValue: item.likes)
        }
        
        // MARK: - Marquee Text Helper
    private struct MarqueeText: View {
        let text: String
        let font: Font
        let leftFade: CGFloat
        let rightFade: CGFloat
        let startDelay: Double
        
        @State private var animate = false
        
        init(text: String, font: Font, leftFade: CGFloat, rightFade: CGFloat, startDelay: Double) {
            self.text = text
            self.font = font
            self.leftFade = leftFade
            self.rightFade = rightFade
            self.startDelay = startDelay
        }
        
        var body: some View {
            GeometryReader { contentGeometry in
                let contentWidth = contentGeometry.size.width
                
                Text(text)
                    .font(font)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(GeometryReader { textGeometry in
                        Color.clear.onAppear {
                            let textWidth = textGeometry.size.width
                            let duration = Double(textWidth) * 0.03
                            
                            guard textWidth > contentWidth else { return }
                            
                            withAnimation(.linear(duration: duration).delay(startDelay).repeatForever(autoreverses: false)) {
                                animate = true
                            }
                        }
                    })
                    .offset(x: animate ? -contentGeometry.size.width - 200 : 0) // Simulación simple, idealmente necesitaría duplicación de texto
            }
            .frame(height: 30) // Ajustar altura según fuente
            .mask(
                HStack(spacing: 0) {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: leftFade)
                    Rectangle().fill(Color.black)
                    LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: rightFade)
                }
            )
        }
    }
    
    // MARK: - Subviews Breakdown (Compiler Optimization)
    private var preloaderImage: some View {
            Group {
                if isActive {
                    WebImage(url: URL(string: item.backgroundUrl), options: [.highPriority])
                        .resizable()
                        .frame(width: 1, height: 1)
                        .opacity(0.001)
                        .allowsHitTesting(false)
                }
            }
        }

        private var gradientOverlay: some View {
            Group {
                if !isCommentsOverlayActive && !isShareOverlayActive {
                    LinearGradient(colors: [.black.opacity(0.2), .clear], startPoint: .bottom, endPoint: .top)
                        .allowsHitTesting(false)
                }
            }
        }

        private var likeHeartOverlay: some View {
            Group {
                if showLikeHeart && !isCommentsOverlayActive && !isShareOverlayActive {
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
            }
        }

        private var gestureOverlay: some View {
            Group {
                if item.id.uuidString != "00000000-0000-0000-0000-000000000000" {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { handleDoubleTap() }
                        .onTapGesture { handleSingleTap() }
                        .allowsHitTesting(!isCommentsOverlayActive && !isShareOverlayActive)
                }
            }
        }

        private var contentOverlay: some View {
            Group {
                if item.id.uuidString == "00000000-0000-0000-0000-000000000000" {
                    introCardOverlay
                } else {
                    if !isCommentsOverlayActive && !isShareOverlayActive { leftColumn }
                    if !isCommentsOverlayActive && !isShareOverlayActive { rightColumn }
                }
            }
        }

        var body: some View {
            ZStack(alignment: .top) {
                // 1. Video Player
                mediaView
                    .frame(width: size.width, height: size.height) // ✅ Fix: No cambiar altura con comentarios
                    .clipped()
                    .onTapGesture(count: 2) { handleDoubleTap() }
                    .onTapGesture {
                        guard !isCommentsOverlayActive && !isShareOverlayActive else { return } // ✅ Bloquear tap si comentarios o share están activos
                        guard item.videoUrl != nil else { return }
                        let willPause = !isPaused
                        withAnimation(.easeInOut(duration: 0.08)) { isPaused = willPause }
                        
                        if let p = player {
                            if willPause {
                                p.pause()
                            } else {
                                if activeVideoId == item.id {
                                    p.play()
                                } else {
                                    coordinator.setActive(item.id)
                                }
                            }
                        }
                    }
                Spacer(minLength: 0)
            }
            .frame(width: size.width, height: size.height)
            .overlay(preloaderImage)
            .overlay(gradientOverlay)
            .overlay(likeHeartOverlay)
            .overlay(gestureOverlay)
            .overlay(contentOverlay)
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.25), value: isCommentsOverlayActive)
            .onAppear {
                #if DEBUG
                print("👀 [ItemView] Renderizando: '\(item.title)' | Video: \(item.videoUrl != nil) | Likes: \(item.likes)")
                #endif
                
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
                            
                            do {
                                try await asset.loadValues(forKeys: keys)
                            } catch {
                                print("❌ [FeedItem] Error cargando asset para \(url): \(error.localizedDescription)")
                                return 
                            }
                            
                            // Verificar cancelación
                            if Task.isCancelled { return }
                            
                            await MainActor.run {
                                // Verificar cancelación de nuevo por si acaso
                                if Task.isCancelled { return }
                                
                                let item = AVPlayerItem(asset: asset)
                                setupPlayer(with: item)
                                
                                // FORCE PLAYBACK TRIGGER
                                // Si este es el video activo, forzamos la actualización
                                if isActive && isScreenActive {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if isActive && isScreenActive {
                                            coordinator.setActive(self.item.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onDisappear {
                loadingTask?.cancel() // 🔴 STOP ZOMBIE LOAD
                loadingTask = nil
                readyCancellable?.cancel()
                readyCancellable = nil
                loopCancellable?.cancel()
                loopCancellable = nil
                
                // 🗑️ MEMORY NUKE: Destruir player inmediatamente al salir de pantalla
                if let p = player {
                    p.pause()
                    p.replaceCurrentItem(with: nil) // Liberar recursos del item
                }
                player = nil
                isVideoReady = false 
                
                // Si éramos el activo, soltamos el control
                if activeVideoId == item.id {
                   // Opcional: coordinator.stop(item.id) 
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    // ⏳ DEBOUNCE: Esperar un momento para asegurar que el usuario se detuvo aquí
                    // Esto evita que los videos intermedios "roben" el foco de audio durante un scroll rápido
                    let currentId = item.id
                    
                    // Cancelar cualquier intento previo
                    activationTask?.cancel()
                    
                    activationTask = Task {
                        // Esperar 100ms (ajustable) - Optimizado para respuesta más rápida
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        
                        if !Task.isCancelled {
                            await MainActor.run {
                                // Si seguimos siendo activos, reclamar el audio
                                if isActive {
                                    coordinator.setActive(currentId)
                                    isPaused = false
                                }
                            }
                        }
                    }
                } else {
                    // Dejamos de ser activos -> Cancelar activación pendiente y pausar
                    activationTask?.cancel()
                    activationTask = nil
                    
                    if let p = player {
                        p.pause()
                        p.seek(to: .zero)
                    }
                    isPaused = false
                }
            }
            .onChange(of: activeVideoId) { _, _ in updatePlayback() }
            .onChange(of: isScreenActive) { _, _ in updatePlayback() }
            .onChange(of: isPaused) { _, _ in updatePlayback() }
            .onChange(of: isMuted) { _, _ in updatePlayback() }
            // ✅ FORCE PLAY TRIGGER: Cuando llegamos al 100% de apertura (isFullyOpen pasa a true)
            // Esto asegura que si por alguna razón no estaba reproduciendo, arranque ahora.
            // Solo aplica si somos el item activo.
            .onChange(of: isFullyOpen) { oldValue, newValue in
                if newValue && isActive {
                    // Forzar activación del coordinador y play
                    coordinator.setActive(item.id)
                    player?.play()
                }
            }
        }

        private func setupPlayer(with item: AVPlayerItem) {
            let p = AVPlayer(playerItem: item)
            p.automaticallyWaitsToMinimizeStalling = true
            p.isMuted = true
            isVideoReady = false
            readyCancellable?.cancel()
            readyCancellable = item.publisher(for: \.status, options: [.initial, .new])
                .receive(on: DispatchQueue.main)
                .sink { status in
                    if status == .readyToPlay {
                        withAnimation(.easeOut(duration: 0.2)) { isVideoReady = true }
                    } else if status == .failed {
                        isVideoReady = false
                    }
                }
            
            // 🛑 MEMORY LEAK FIX: Use Combine for looping instead of block-based NotificationCenter
            // This ensures the observer is released when the view/cancellable is deallocated.
            loopCancellable = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: p.currentItem)
                .sink { [weak p] _ in
                    p?.seek(to: .zero)
                    p?.play()
                }
            
            self.player = p
            
            // 🚀 AUTO-PLAY RESTAURADO:
            // Si al terminar de cargar seguimos siendo el video activo, iniciamos la reproducción.
            // Esto es crucial para el primer video o cuando la carga termina y el usuario sigue ahí.
            if isActive && isScreenActive {
                coordinator.setActive(self.item.id)
                // Fallback: Asegurar que se reproduzca si el coordinator ya lo tiene activo
                if coordinator.activeVideoId == self.item.id {
                    p.play()
                }
            }
        }

        private func checkLikeStatus() {
            guard let videoId = item.videoId, let userId = AuthService.shared.user?.uid else { return }
            if let cached = LikeCacheService.shared.get(userId: userId, videoId: videoId) {
                self.isLiked = cached
                return
            }
            DatabaseService.shared.checkIfUserLiked(videoId: videoId, userId: userId) { liked in
                DispatchQueue.main.async {
                    self.isLiked = liked
                    LikeCacheService.shared.set(userId: userId, videoId: videoId, liked: liked)
                }
            }
        }

        private func handleDoubleTap() {
            guard !isCommentsOverlayActive && !isShareOverlayActive else { return }
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
        
        private func handleSingleTap() {
            guard item.videoUrl != nil else { return }
            
            // 1. Toggle local state (Feedback visual inmediato)
            let willPause = !isPaused
            withAnimation(.easeInOut(duration: 0.1)) { isPaused = willPause }
            
            // 2. Control Lógico
            if willPause {
                // Si pausamos, el updatePlayback (onChange of isPaused) se encargará de detener el player
            } else {
                // Si damos play, reclamamos el foco de audio
                if activeVideoId != item.id {
                    coordinator.setActive(item.id)
                } else {
                    // Si ya somos activos, forzamos el play por si acaso
                    player?.play()
                }
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
            LikeCacheService.shared.set(userId: userId, videoId: videoId, liked: isLiked)
            
            if isLiked {
                DatabaseService.shared.likeVideo(videoId: videoId, userId: userId) { _ in }
            } else {
                DatabaseService.shared.unlikeVideo(videoId: videoId, userId: userId) { _ in }
            }
        }
        
        // MARK: - Left Column Subviews
        private var leftColumn: some View {
            VStack {
                Spacer()
                ZStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            userInfoRow
                            videoTitleRow
                            videoDescriptionRow
                            musicRow
                            orderButtonRow
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, bottomInset + 36) // Elevado +60pt extra (original: -24)
            }
            .onAppear { updateFollowingUI() }
            .onChange(of: AuthService.shared.hasResolvedAuth) { _, newValue in
                if newValue { updateFollowingUI() }
            }
        }

        private var userInfoRow: some View {
            HStack(alignment: .center, spacing: 12) {
                userAvatarView
                userNameAndFollowView
            }
        }

        private var userAvatarView: some View {
            let hasRing = item.label == .foodieReview || item.hasStories
            let ringColor: Color = item.label == .foodieReview ? .yellow : .green
            
            return ZStack {
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
        }

        private var userNameAndFollowView: some View {
            let labelText: String = {
                // Alternar hardcodeado según id hash
                return (item.id.hashValue % 2 == 0) ? "FOODIE REVIEW ⭐️" : "SPONSORED"
            }()
            let labelColor: Color = (item.id.hashValue % 2 == 0) ? .yellow : .blue

            return VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Button(action: { onShowProfile(loadedImage) }) {
                        Text(item.username)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold)) // ↑ De 18 a 20
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                }
                
                Text(labelText)
                    .foregroundColor(labelColor)
                    .font(.system(size: 13, weight: .black)) // ↑ De 12 a 13
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }

        private var followButton: some View {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { isFollowing = true }
                if let followerUid = AuthService.shared.user?.uid, let followedUid = item.authorId {
                    DatabaseService.shared.followUser(followerUid: followerUid, followedUid: followedUid) { _ in
                        DispatchQueue.main.async {
                            AuthService.shared.recordLocalFollow(followedUid: followedUid)
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.2)) { showFollowButton = false }
                }
            }) {
                Capsule()
                    .fill(isFollowing ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                    .frame(width: 90, height: 32)
                    .overlay(
                        Text(isFollowing ? "Siguiendo" : "Seguir")
                            .foregroundColor(.white)
                            .font(.footnote.bold())
                            .transition(.opacity.combined(with: .scale))
                    )
            }
        }

        private var videoTitleRow: some View {
            // Título estático normal (corregido: no debe ser marquee)
            Text("The Ultimate Volcano Burger")
                .foregroundColor(.white)
                .font(.system(size: 19, weight: .bold)) // ↑ De 17 a 19
                .lineLimit(2)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }

        private var videoDescriptionRow: some View {
            let isExpanded = expandedDescriptions.contains(item.id)
            return Text(item.description)
                .foregroundColor(.white.opacity(0.9))
                .font(.system(size: 15)) // ↑ De 14 a 15
                .lineLimit(isExpanded ? nil : 2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: size.width * 0.5, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isExpanded { expandedDescriptions.remove(item.id) } else { expandedDescriptions.insert(item.id) }
                }
        }

        private var musicRow: some View {
            HStack(spacing: 8) {
                Image(systemName: "music.note")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                
                // Marquee aplicado al AUDIO como solicitado
                MarqueeText(
                    text: "Burger Flip Beat - Chef Beats Original • Vlog Vibes - Chill Lofi • ",
                    font: .system(size: 16, weight: .medium), // ↑ De 15 a 16
                    leftFade: 5,
                    rightFade: 5,
                    startDelay: 1.0
                )
                .frame(width: size.width * 0.55) // Ancho limitado para efecto de scroll
            }
        }

        private var orderButtonRow: some View {
            let isFoodie = (item.id.hashValue % 2 == 0)
            
            return HStack(spacing: 10) {
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.12)) { orderPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { orderPressed = false }
                                self.selectedItemForProfile = item // 📸 Guardar snapshot también para el menú
                                onShowMenu()
                            }
                        }) {
                            Capsule()
                        .fill(isFoodie ? Color(white: 0.4) : Color.brandGreen) // Gris sólido (opaco) para Foodie
                        .frame(width: 240, height: 48) // Ancho aumentado para texto
                        .overlay(
                            HStack(spacing: 6) {
                                Image(systemName: isFoodie ? "mappin.and.ellipse" : "cart.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text(isFoodie ? "View Spot • Menu" : "Order Now • $15.99")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                        )
                        // Borde sutil solo para el botón translúcido
                        .overlay(
                            Group {
                                if isFoodie {
                                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            }
                        )
                        .scaleEffect(orderPressed ? 0.95 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: orderPressed)
                }
            }
        }

        private func updateFollowingUI() {
            guard let followerUid = AuthService.shared.user?.uid else {
                showFollowButton = true
                return
            }
            if let authorUid = item.authorId {
                resolvedAuthorUid = authorUid
            } else if resolvedAuthorUid == nil {
                DatabaseService.shared.getUidForUsername(item.username) { uid in
                    DispatchQueue.main.async { resolvedAuthorUid = uid }
                }
            }
            guard let followedUid = resolvedAuthorUid ?? item.authorId else {
                showFollowButton = true
                return
            }
            if AuthService.shared.isFollowingCached(followedUid) == true {
                isFollowing = true
                showFollowButton = false
                return
            }
            DatabaseService.shared.checkIfFollowing(followerUid: followerUid, followedUid: followedUid) { isF in
                DispatchQueue.main.async {
                    isFollowing = isF
                    showFollowButton = !isF
                    AuthService.shared.setFollowingCached(followedUid, value: isF)
                }
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
            ZStack {
                // 1. Imagen de fondo (Thumbnail) - ELIMINADA
                // El usuario solicitó explícitamente NO mostrar ninguna imagen estática,
                // confiando 100% en la precarga del video.
                // Si el video no está listo, se verá negro (o el color de fondo).
                
                // 2. Video Player (Solo si existe URL y player)
                if let _ = item.videoUrl, let p = player {
                    FeedVideoPlayer(player: p)
                        .disabled(true)
                        .allowsHitTesting(false)
                        // Sin opacidad condicional ni animación: "Raw" playback
                }

                // 3. Play Icon
                if isPaused {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 80, weight: .bold))
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 3)
                        .transition(.opacity)
                        .opacity(1.0)
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
            let shouldPlay = (activeVideoId == item.id) && isScreenActive && !isPaused
            
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
        .padding(.bottom, 60) // Increased from 8 to 60 to move it higher
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
