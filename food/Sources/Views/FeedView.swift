import SwiftUI
import SDWebImageSwiftUI

struct FeedView: View {
    let bottomInset: CGFloat
    private struct FeedItem: Identifiable {
        enum Label { case sponsored, foodieReview, none }
        let id = UUID()
        let backgroundUrl: String
        let username: String
        let label: Label
        let hasStories: Bool
        let avatarUrl: String
        let title: String
        let description: String
        let soundTitle: String
    }

    private let forYouItems: [FeedItem] = [
        // 1. Foodie Review con historias (círculo verde)
        .init(
            backgroundUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1",
            username: "Burger Master",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
            title: "🔥 Smash Burger Deluxe",
            description: "Juicy double patty with special sauce, crispy onions, and melted cheese. The perfect burger experience!",
            soundTitle: "Grill Beats • Burger Jam"
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
            soundTitle: "Pizza Groove • Delivery Beat"
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
            soundTitle: "Tokyo Vibes • Sushi Flow"
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
            soundTitle: "Italian Beats • Pasta Jam"
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
            soundTitle: "Sweet Melody • Dessert Mix"
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
            soundTitle: "Fresh Beats • Green Mix"
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
            soundTitle: "Fiesta Rhythm • Taco Beat"
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
            soundTitle: "Smokehouse Beats • BBQ Jam"
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
            soundTitle: "Healthy Vibes • Green Mix"
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
            soundTitle: "Street Beats • Taco Flow"
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
            soundTitle: "Delicious Beats • Sandwich Jam"
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
            soundTitle: "Sweet Melody • Donut Mix"
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
            soundTitle: "Italian Beats • Pizza Flow"
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
            soundTitle: "Gourmet Beats • Burger Mix"
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
            get: { activeTab == .foryou ? forYouVM.currentIndex : followingVM.currentIndex },
            set: { newValue in
                if activeTab == .foryou {
                    forYouVM.currentIndex = newValue
                } else {
                    followingVM.currentIndex = newValue
                }
            }
        )
    }

    @State private var isFollowing = false
    @State private var liked = false
    @State private var showRestaurantProfile = false
    @State private var showMenu = false
    @State private var showComments = false
    @State private var showShare = false
    @State private var showMusic = false
    @State private var expandedDescriptions: Set<UUID> = []
    @State private var likesCount = 2487
    @State private var commentsCount = 132
    @State private var sharesCount = 89
    @State private var bottomSectionHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            
            ZStack {
                // PAGER PRINCIPAL - OCUPA TODA LA PANTALLA
                VerticalPager(count: currentItems.count, index: selectedIndexBinding, pageHeight: totalHeight) { size, idx in
                    let item = currentItems[idx]
                    
                ZStack {
                    // IMAGEN que cubre TODA la pantalla
                    WebImage(url: URL(string: item.backgroundUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .contentShape(Rectangle())
                    
                    // Gradiente opcional
                    LinearGradient(
                        colors: [.black.opacity(0.2), .clear],
                        startPoint: .bottom, endPoint: .top
                    )
                    
                    // CONTENIDO OVERLAY
                    overlayContent(size, item)
                }
                .frame(width: size.width, height: size.height)
                .ignoresSafeArea()
            }
                .frame(height: totalHeight)
                .ignoresSafeArea()
                
                // COLUMNA DERECHA DE BOTONES - Fuera del overlay para libre posicionamiento
                VStack(spacing: 24) {
                    // Like button with count
                    VStack(spacing: 6) {
                        Button(action: { 
                            liked.toggle()
                            likesCount += liked ? 1 : -1
                        }) {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .foregroundColor(liked ? .red : .white)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                        }
                        Text(formatCount(likesCount))
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    // Comment button with count
                    VStack(spacing: 6) {
                        Button(action: { showComments = true }) {
                            Image(systemName: "bubble.left")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                        }
                        Text(formatCount(commentsCount))
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    // Bookmark button
                    Button(action: { showMusic = true }) {
                        Image(systemName: "bookmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 28)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                    }
                    
                    // Share button with count
                    VStack(spacing: 6) {
                        Button(action: { showShare = true }) {
                            Image(systemName: "paperplane")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                        }
                        Text(formatCount(sharesCount))
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, geo.size.height * 0.59)
                .padding(.trailing, 16)
                
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
            withAnimation(.easeInOut(duration: 0.2)) { }
            selectedVM.currentIndex = min(selectedVM.currentIndex, max(currentItems.count - 1, 0))
            selectedVM.prefetch(urls: currentItems.map { $0.backgroundUrl })
        }
    }

    private func overlayContent(_ size: CGSize, _ item: FeedItem) -> some View {
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
            Spacer(minLength: size.height * 0.75)
            ZStack {
                    // Columna izquierda - se mantiene alineada al fondo
                    HStack {
                    ZStack(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 12) {
                            WebImage(url: URL(string: item.avatarUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 53, height: 53)
                                .clipShape(Circle())
                            .overlay(
                                Circle().stroke(hasRing ? ringColor : .clear, lineWidth: hasRing ? 2 : 0)
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Button(action: { showRestaurantProfile = true }) {
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
                                        .font(.caption2)
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
                    }
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.bottom, bottomSectionHeight + 10)
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                            Text(item.soundTitle)
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .lineLimit(1)
                        }
                        HStack(spacing: 10) {
                            Button(action: { showMenu = true }) {
                                Capsule()
                                    .fill(Color.green)
                                    .frame(width: 216, height: 48)
                                    .overlay(Text("Ordenar Ahora").foregroundColor(.white).font(.system(size: 14, weight: .bold)))
                            }
                        }
                    }
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { bottomSectionHeight = proxy.size.height }
                        }
                    )
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, bottomInset + 20)
            // El padding top ya se maneja en el overlay de topTabs
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
            if showRestaurantProfile { modalCard(title: "Perfil del Restaurante", onClose: { showRestaurantProfile = false }) }
            if showMenu { modalCard(title: "Menú", onClose: { showMenu = false }) }
            if showComments { modalCard(title: "Comentarios", onClose: { showComments = false }) }
            if showShare { modalCard(title: "Compartir", onClose: { showShare = false }) }
            if showMusic { modalCard(title: "Guardados", onClose: { showMusic = false }) }
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
}
