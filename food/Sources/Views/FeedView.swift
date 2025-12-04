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
        .init(
            backgroundUrl: "https://images.pexels.com/photos/704569/pexels-photo-704569.jpeg",
            username: "The Burger Joint",
            label: .sponsored,
            hasStories: true,
            avatarUrl: "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg",
            title: "The Volcano Burger",
            description: "Experience the explosive flavor of our Volcano Burger! Fiery, juicy, and irresistible. Double-stacked patties with melted cheddar, jalapeño relish, and our signature smoky sauce — crafted for heat lovers.",
            soundTitle: "Chef Beats Original • Burger BGM"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/461198/pexels-photo-461198.jpeg",
            username: "Pasta Lovers",
            label: .foodieReview,
            hasStories: false,
            avatarUrl: "https://images.pexels.com/photos/3184192/pexels-photo-3184192.jpeg",
            title: "Truffle Alfredo",
            description: "A creamy truffle alfredo with fresh herbs and parmesan.",
            soundTitle: "Foodie Groove • Pasta Jam"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/357756/pexels-photo-357756.jpeg",
            username: "Sushi Time",
            label: .none,
            hasStories: true,
            avatarUrl: "https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg",
            title: "Dragon Roll",
            description: "Crispy tempura with avocado and spicy mayo. Finished with eel sauce and toasted sesame for a perfect bite in every roll.",
            soundTitle: "Tokyo Beat • Sushi Wave"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/315755/pexels-photo-315755.jpeg",
            username: "Pizza Planet",
            label: .foodieReview,
            hasStories: false,
            avatarUrl: "https://images.pexels.com/photos/1036623/pexels-photo-1036623.jpeg",
            title: "Pepperoni Supreme",
            description: "Thin crust, double pepperoni, extra cheese.",
            soundTitle: "Slice Anthem • Pizza Jam"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/302680/pexels-photo-302680.jpeg",
            username: "Dessert Dreams",
            label: .sponsored,
            hasStories: true,
            avatarUrl: "https://images.pexels.com/photos/360680/pexels-photo-360680.jpeg",
            title: "Chocolate Lava Cake",
            description: "Warm molten center with vanilla ice cream.",
            soundTitle: "Sweet Lo-Fi • Dessert Flow"
        )
    ]
    
    private let followingItems: [FeedItem] = [
        .init(
            backgroundUrl: "https://images.pexels.com/photos/262959/pexels-photo-262959.jpeg",
            username: "BBQ Masters",
            label: .foodieReview,
            hasStories: false,
            avatarUrl: "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg",
            title: "Smoked Brisket",
            description: "Low and slow smoked brisket with a peppery bark. 14-hour cook, juicy slices, and house-made pickles — a true pitmaster staple.",
            soundTitle: "Grill Grooves • Pit Jam"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/1099680/pexels-photo-1099680.jpeg",
            username: "Green Bowl",
            label: .none,
            hasStories: true,
            avatarUrl: "https://images.pexels.com/photos/247878/pexels-photo-247878.jpeg",
            title: "Superfood Salad",
            description: "Quinoa, kale, avocado, nuts and seeds. Citrus vinaigrette, roasted chickpeas, and microgreens for crunch and balance.",
            soundTitle: "Fresh Beats • Green Flow"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/2271099/pexels-photo-2271099.jpeg",
            username: "Taco Truck",
            label: .foodieReview,
            hasStories: true,
            avatarUrl: "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg",
            title: "Street Tacos",
            description: "Carnitas with cilantro, onion and lime.",
            soundTitle: "Fiesta Mix • Taco Jam"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/410648/pexels-photo-410648.jpeg",
            username: "Sandwich Hub",
            label: .none,
            hasStories: false,
            avatarUrl: "https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg",
            title: "Club Sandwich",
            description: "Triple stack with turkey, bacon and tomato.",
            soundTitle: "Cafe Vibes • Lunch Groove"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg",
            username: "Coffee & Donuts",
            label: .sponsored,
            hasStories: true,
            avatarUrl: "https://images.pexels.com/photos/230477/pexels-photo-230477.jpeg",
            title: "Glazed Donuts",
            description: "Freshly made, soft and sweet glaze.",
            soundTitle: "Morning Swing • Donut Beat"
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
            Spacer()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 12) {
                        WebImage(url: URL(string: item.avatarUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                        .overlay(
                            Circle().stroke(hasRing ? ringColor : .clear, lineWidth: hasRing ? 2 : 0)
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Button(action: { showRestaurantProfile = true }) {
                                    Text(item.username)
                                        .foregroundColor(.white)
                                        .font(.headline.bold())
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
                        .font(.title2.bold())
                    
                    Text(item.description)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.footnote)
                        .lineLimit(isExpanded ? nil : 2)
                        .truncationMode(.tail)
                        .frame(maxWidth: size.width * 0.5, alignment: .leading)
                        .onTapGesture {
                            if isExpanded { expandedDescriptions.remove(item.id) } else { expandedDescriptions.insert(item.id) }
                        }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                        Text(item.soundTitle)
                            .foregroundColor(.white)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 10) {
                        Button(action: { showMenu = true }) {
                            Capsule()
                                .fill(Color.green)
                                .frame(width: 180, height: 40)
                                .overlay(Text("Ordenar Ahora").foregroundColor(.white).font(.footnote.bold()))
                        }
                    }
                }
                Spacer()
                VStack(spacing: 20) {
                    Button(action: { liked.toggle() }) {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(liked ? .red : .white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    Button(action: { showComments = true }) {
                        Image(systemName: "ellipsis.bubble.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    Button(action: { showMusic = true }) {
                        Image(systemName: "bookmark.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 32)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    Button(action: { showShare = true }) {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, bottomInset)
            // El padding top ya se maneja en el overlay de topTabs
        }
    }

    private var topTabs: some View {
        HStack(spacing: 16) {
            tabButton(title: "Siguiendo", isActive: activeTab == .following, indicatorColor: .red) {
                withAnimation(.easeInOut(duration: 0.2)) { activeTab = .following }
            }
            tabButton(title: "Para Ti", isActive: activeTab == .foryou, indicatorColor: .green) {
                withAnimation(.easeInOut(duration: 0.2)) { activeTab = .foryou }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.clear)
    }

    private func tabButton(title: String, isActive: Bool, indicatorColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .foregroundColor(isActive ? .white : .secondary)
                    .font(.subheadline.bold())
                if isActive {
                    Capsule()
                        .fill(indicatorColor)
                        .frame(width: 60, height: 3)
                        .shadow(color: indicatorColor.opacity(0.6), radius: 6)
                }
            }
            .padding(.horizontal, 6)
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
}
