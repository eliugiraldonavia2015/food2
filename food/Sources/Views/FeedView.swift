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
            description: "Experience the explosive flavor of our Volcano Burger! Fiery, juicy, and irresistible.",
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
        )
    ]
    
    private let followingItems: [FeedItem] = [
        .init(
            backgroundUrl: "https://images.pexels.com/photos/461198/pexels-photo-461198.jpeg",
            username: "Chef Anna",
            label: .none,
            hasStories: true,
            avatarUrl: "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg",
            title: "Homemade Ravioli",
            description: "Hand-crafted pasta pockets with ricotta and spinach.",
            soundTitle: "Kitchen Beats • Ravioli Jam"
        ),
        .init(
            backgroundUrl: "https://images.pexels.com/photos/262959/pexels-photo-262959.jpeg",
            username: "BBQ Masters",
            label: .foodieReview,
            hasStories: false,
            avatarUrl: "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg",
            title: "Smoked Brisket",
            description: "Low and slow smoked brisket with a peppery bark.",
            soundTitle: "Grill Grooves • Pit Jam"
        )
    ]
    
    private var currentItems: [FeedItem] { activeTab == .foryou ? forYouItems : followingItems }

    @State private var activeTab: ActiveTab = .foryou
    private enum ActiveTab { case following, foryou }

    @StateObject private var feedVM = FeedViewModel()

    @State private var isFollowing = false
    @State private var liked = false
    @State private var showRestaurantProfile = false
    @State private var showMenu = false
    @State private var showComments = false
    @State private var showShare = false
    @State private var showMusic = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geo in
                VerticalPager(count: currentItems.count, index: $feedVM.currentIndex) { size, idx in
                    GeometryReader { pageGeo in
                        let item = currentItems[idx]
                        ZStack {
                                ZStack {
                                    Rectangle().fill(Color.black.opacity(0.2))
                                    WebImage(url: URL(string: item.backgroundUrl))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .clipped()
                                }


                                LinearGradient(
                                    colors: [.black.opacity(0.55), .clear, .black.opacity(0.8)],
                                    startPoint: .bottom, endPoint: .top
                                )

                                overlayContent(pageGeo, item)
                            }
                        }
                }
            }
        }
        .overlay(topTabs.padding(.top, 8), alignment: .top)
        .background(Color.black.ignoresSafeArea())
        .overlay(overlays, alignment: .center)
        .preferredColorScheme(.dark)
        .onAppear { feedVM.prefetch(urls: currentItems.map { $0.backgroundUrl }) }
        .onDisappear { feedVM.cancelPrefetch() }
        .onChange(of: activeTab) { _, _ in
            feedVM.currentIndex = 0
            feedVM.prefetch(urls: currentItems.map { $0.backgroundUrl })
        }
    }

    private func overlayContent(_ geo: GeometryProxy, _ item: FeedItem) -> some View {
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
                            Button(action: { showRestaurantProfile = true }) {
                                Text(item.username)
                                    .foregroundColor(.white)
                                    .font(.headline.bold())
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
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                        Text(item.soundTitle)
                            .foregroundColor(.white)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 10) {
                        Button(action: { isFollowing.toggle() }) {
                            Capsule()
                                .fill(isFollowing ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                                .frame(width: 90, height: 32)
                                .overlay(Text(isFollowing ? "Siguiendo" : "Seguir").foregroundColor(.white).font(.footnote.bold()))
                        }
                        Button(action: { showMenu = true }) {
                            Capsule()
                                .fill(Color.green)
                                .frame(width: 160, height: 36)
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
            .padding(.bottom, 4)
        }
    }

    private var topTabs: some View {
        HStack(spacing: 16) {
            tabButton(title: "Siguiendo", isActive: activeTab == .following, indicatorColor: .red) {
                activeTab = .following
            }
            tabButton(title: "Para Ti", isActive: activeTab == .foryou, indicatorColor: .green) {
                activeTab = .foryou
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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