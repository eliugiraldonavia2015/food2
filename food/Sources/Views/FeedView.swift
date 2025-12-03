import SwiftUI

struct FeedView: View {
    private let sampleImages: [String] = [
        "https://images.pexels.com/photos/1640772/pexels-photo-1640772.jpeg",
        "https://images.pexels.com/photos/704569/pexels-photo-704569.jpeg",
        "https://images.pexels.com/photos/461198/pexels-photo-461198.jpeg",
        "https://images.pexels.com/photos/1435893/pexels-photo-1435893.jpeg"
    ]

    @State private var activeTab: ActiveTab = .foryou
    private enum ActiveTab { case following, foryou }


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
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(sampleImages, id: \.self) { url in
                            ZStack {
                                AsyncImage(url: URL(string: url)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .clipped()
                                } placeholder: {
                                    Color.black.opacity(0.4)
                                }

                                LinearGradient(
                                    colors: [.black.opacity(0.55), .clear, .black.opacity(0.8)],
                                    startPoint: .bottom, endPoint: .top
                                )

                                VStack {
                                    Spacer()
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Button(action: { showRestaurantProfile = true }) {
                                                Text("Restaurante La Plaza")
                                                    .foregroundColor(.white)
                                                    .font(.headline.bold())
                                            }
                                            Text("Descubre el nuevo combo especial con sabores auténticos.")
                                                .foregroundColor(.white.opacity(0.9))
                                                .font(.footnote)
                                                .lineLimit(2)
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
                                                        .frame(width: 140, height: 36)
                                                        .overlay(Text("Ordenar Ahora").foregroundColor(.white).font(.footnote.bold()))
                                                }
                                            }
                                        }
                                        Spacer()
                                        VStack(spacing: 18) {
                                            Button(action: { liked.toggle() }) {
                                                Image(systemName: liked ? "heart.fill" : "heart")
                                                    .foregroundColor(liked ? .red : .white)
                                                    .font(.title3)
                                            }
                                            Button(action: { showComments = true }) {
                                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                                    .foregroundColor(.white)
                                                    .font(.title3)
                                            }
                                            Button(action: { showMusic = true }) {
                                                Image(systemName: "music.note")
                                                    .foregroundColor(.white)
                                                    .font(.title3)
                                            }
                                            Button(action: { showShare = true }) {
                                                Image(systemName: "square.and.arrow.up")
                                                    .foregroundColor(.white)
                                                    .font(.title3)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                                }
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                }
            }
        }
        .overlay(topTabs.padding(.top, 8), alignment: .top)
        .background(Color.black.ignoresSafeArea())
        .overlay(overlays, alignment: .center)
        .preferredColorScheme(.dark)
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
            if showMusic { modalCard(title: "Música", onClose: { showMusic = false }) }
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