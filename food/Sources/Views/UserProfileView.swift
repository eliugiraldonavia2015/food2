import SwiftUI
import SDWebImageSwiftUI
import UIKit

struct UserProfileView: View {
    @StateObject private var viewModel: PublicProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Estados visuales inspirados en RestaurantProfileView
    @State private var isFollowing = false
    @State private var showFullMenu = false
    @State private var pullOffset: CGFloat = 0
    @State private var headerMinY: CGFloat = 0
    @State private var animateContent = false
    
    private let headerHeight: CGFloat = 280
    private let refreshThreshold: CGFloat = UIScreen.main.bounds.height * 0.15
    private let photoColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    private let hardcodedDescriptionText =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco."
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: PublicProfileViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("profileScroll")).minY)
                            }
                        )
                        .padding(.bottom, -16)
                    
                    if let user = viewModel.user {
                        header(user: user)
                        
                        VStack(spacing: 24) {
                            profileInfo(user: user)
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1 : 0)
                            
                            descriptionCard
                                .offset(y: animateContent ? 0 : 30)
                                .opacity(animateContent ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)

                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("Fotos y Videos")
                                mediaGrid
                            }
                            .offset(y: animateContent ? 0 : 40)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                        .padding(.top, 16)
                    } else {
                        loadingView
                    }
                }
            }
        }
        .coordinateSpace(name: "profileScroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { y in
            pullOffset = max(0, y)
        }
        .onPreferenceChange(HeaderOffsetPreferenceKey.self) { v in
            headerMinY = v
            pullOffset = max(0, v)
        }
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: "chevron.left").foregroundColor(.primary))
            }
            .padding(12)
            .offset(y: 12)
            .opacity(animateContent ? 1 : 0)
            .animation(.easeIn.delay(0.3), value: animateContent)
        }
        .background(Color.white.ignoresSafeArea())
        .tint(Color.fuchsia)
        .preferredColorScheme(.light)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            viewModel.loadData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
        .fullScreenCover(isPresented: $showFullMenu) {
            if let user = viewModel.user {
                FullMenuView(
                    restaurantId: user.username.replacingOccurrences(of: " ", with: "").lowercased(),
                    restaurantName: user.name,
                    coverUrl: user.coverUrl,
                    avatarUrl: user.photoUrl,
                    location: user.location.isEmpty ? "CDMX, México" : user.location,
                    branchName: user.location.isEmpty ? "CDMX, México" : user.location,
                    distanceKm: 2.3,
                    onDismissToRoot: {
                        showFullMenu = false
                    }
                )
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Componentes Visuales
    
    private func header(user: PublicProfileViewModel.UserProfileData) -> some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            ZStack(alignment: .topLeading) {
                WebImage(url: URL(string: user.coverUrl))
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: minY > 0 ? headerHeight + minY : headerHeight)
                    .blur(radius: minY > 0 ? min(12, minY / 18) : 0, opaque: true)
                    .clipped()
                    .overlay(coverGradient)
                    .offset(y: minY > 0 ? -minY : 0)
                
                Color.clear
                    .preference(key: HeaderOffsetPreferenceKey.self, value: minY)
            }
            .frame(height: headerHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(height: headerHeight)
    }
    
    private var coverGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: 0.6),
                .init(color: Color.white, location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func profileInfo(user: PublicProfileViewModel.UserProfileData) -> some View {
        VStack(spacing: 0) {
            // Avatar con Placeholder
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                if let url = URL(string: user.photoUrl), !user.photoUrl.isEmpty {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 102, height: 102)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 102, height: 102)
                        .foregroundColor(.gray.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .offset(y: -75) // Subido de -55 a -75
            .padding(.bottom, -60) // Ajustado de -40 a -60 para compensar
            
            VStack(spacing: 8) {
                Text(user.name)
                    .foregroundColor(.black)
                    .font(.system(size: 24, weight: .bold))
                
                Text("@\(user.username)")
                    .foregroundColor(.gray)
                    .font(.system(size: 15))
                
                HStack(spacing: 32) {
                    // Rating (Reemplaza Categoría)
                    VStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Text("4.8")
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 18))
                        }
                        Text("Calificación")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                    
                    // Seguidores
                    VStack(spacing: 0) {
                        Text(formatCount(user.followers))
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                        Text("Seguidores")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                }
                .padding(.top, 12)
                
                // Botones
                HStack(spacing: 12) {
                    Button(action: { isFollowing.toggle() }) {
                        HStack(spacing: 8) {
                            Image(systemName: isFollowing ? "person.checkmark" : "person.badge.plus")
                                .foregroundColor(.white)
                            Text(isFollowing ? "Siguiendo" : "Seguir")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .fixedSize()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFollowing ? Color.gray : Color.fuchsia)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .animation(nil, value: isFollowing)
                    
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Text("Mensaje").foregroundColor(.black).font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.top, 12)
                
                Button(action: { showFullMenu = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.fuchsia)
                                .frame(width: 44, height: 44) // Ligeramente más grande para impacto
                                .shadow(color: Color.fuchsia.opacity(0.4), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "fork.knife")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ver Menú Completo")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .bold))
                            Text("Explora nuestros platillos")
                                .foregroundColor(.gray)
                                .font(.system(size: 13, weight: .medium))
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.black.opacity(0.6))
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(20) // Bordes más redondeados y modernos
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4) // Sombra suave y difusa tipo iOS
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) // Borde sutil brillante
                    )
                    .scaleEffect(1.0)
                }
                .buttonStyle(BouncyButtonStyle()) // Animación personalizada
                .padding(.top, 12)

            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 0)
    }
    
    // Estilo de botón con animación de rebote (Spring)
    struct BouncyButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
                .opacity(configuration.isPressed ? 0.9 : 1.0)
        }
    }
    
    private var descriptionCard: some View {
        Text(hardcodedDescriptionText)
            .foregroundColor(.gray)
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
    }

    private var mediaGrid: some View {
        LazyVGrid(columns: photoColumns, spacing: 2) {
            ForEach(0..<15, id: \.self) { index in
                // Si hay videos reales, úsalos; si no, usa placeholders hardcodeados
                if index < viewModel.videos.count {
                    PhotoTileView(video: viewModel.videos[index], index: index)
                } else {
                    // Placeholder hardcodeado con diseño bonito
                    HardcodedTileView(index: index)
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).foregroundColor(.black).font(.headline)
            Spacer()
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                .scaleEffect(1.5)
            Spacer()
        }
        .frame(height: UIScreen.main.bounds.height * 0.5)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count)/1_000_000) }
        else if count >= 1_000 { return String(format: "%.1fK", Double(count)/1_000) }
        else { return "\(count)" }
    }
    
    // Componente interno para las celdas de video con animación
    struct PhotoTileView: View {
        let video: Video
        let index: Int
        @State private var appear = false
        
        var body: some View {
            GeometryReader { geo in
                let url = URL(string: video.thumbnailUrl)
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.4))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .overlay(
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text("\(video.likes)")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                        , alignment: .bottomLeading
                    )
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.9)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05)) {
                            appear = true
                        }
                    }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color.gray.opacity(0.1))
        }
    }

    // Componente Placeholder Hardcodeado (Diseño Bonito)
    struct HardcodedTileView: View {
        let index: Int
        @State private var appear = false
        
        // Imágenes de ejemplo de Unsplash (Comida atractiva)
        let sampleImages = [
            "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
            "https://images.unsplash.com/photo-1604908176997-431199f7c209",
            "https://images.unsplash.com/photo-1600891964599-f61ba0e24092",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1",
            "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
            "https://images.unsplash.com/photo-1565958011703-44f9829ba187",
            "https://images.unsplash.com/photo-1482049016688-2d3e1b311543",
            "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
            "https://images.unsplash.com/photo-1484723091739-30a097e8f929",
            "https://images.unsplash.com/photo-1467003909585-2f8a7270028d",
            "https://images.unsplash.com/photo-1473093295043-cdd812d0e601",
            "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f",
            "https://images.unsplash.com/photo-1476224203421-9ac39bcb3327",
            "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd",
            "https://images.unsplash.com/photo-1496417263034-38ec4f0d665a"
        ]
        
        var body: some View {
            GeometryReader { geo in
                let urlString = sampleImages[index % sampleImages.count]
                let url = URL(string: urlString + "?auto=format&fit=crop&w=400&q=80")
                
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.4))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .overlay(
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text("\(Int.random(in: 100...5000))")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                        , alignment: .bottomLeading
                    )
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.9)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05)) {
                            appear = true
                        }
                    }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color.gray.opacity(0.1))
        }
    }
}

// Helpers para Scroll y Parallax
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct HeaderOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct RoundedCorners: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
