import SwiftUI
import SDWebImageSwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel: PublicProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Estados visuales inspirados en RestaurantProfileView
    @State private var isFollowing = false
    @State private var showFullMenu = false
    @State private var showLocationList = false
    @State private var selectedBranchName = ""
    @State private var pullOffset: CGFloat = 0
    @State private var headerMinY: CGFloat = 0
    
    private let headerHeight: CGFloat = 220
    private let refreshThreshold: CGFloat = UIScreen.main.bounds.height * 0.15
    private let photoColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private struct LocationItem: Identifiable {
        let id = UUID()
        let name: String
        let address: String
        let distanceKm: Double
    }

    private struct MediaItem: Identifiable {
        let id = UUID()
        let url: String
        let likes: Int
    }

    private let hardcodedLocations: [LocationItem] = [
        .init(name: "Sucursal Centro", address: "Av. Juárez 123, Centro", distanceKm: 1.2),
        .init(name: "Sucursal Condesa", address: "Av. Michoacán 78, Condesa", distanceKm: 2.3),
        .init(name: "Sucursal Roma", address: "Calle Orizaba 45, Roma Norte", distanceKm: 3.1),
        .init(name: "Sucursal Polanco", address: "Masaryk 200, Polanco", distanceKm: 4.0)
    ]

    private let hardcodedMedia: [MediaItem] = [
        .init(url: "https://images.unsplash.com/photo-1504674900247-0877df9cc836", likes: 12000),
        .init(url: "https://images.unsplash.com/photo-1604908176997-431199f7c209", likes: 5200),
        .init(url: "https://images.unsplash.com/photo-1600891964599-f61ba0e24092", likes: 8000),
        .init(url: "https://images.unsplash.com/photo-1605475121025-6520df4cf73e", likes: 1800),
        .init(url: "https://images.unsplash.com/photo-1589308078053-02051b89c1a3", likes: 9100),
        .init(url: "https://images.unsplash.com/photo-1612197528228-7d9d7e9db2e8", likes: 3400),
        .init(url: "https://images.unsplash.com/photo-1617191519200-3d5d4b8c9a27", likes: 6700),
        .init(url: "https://images.unsplash.com/photo-1550547660-d9450f859349", likes: 2200),
        .init(url: "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe", likes: 4300)
    ]

    private let hardcodedDescriptionText =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco."
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: PublicProfileViewModel(userId: userId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Scroll Preference para efectos
                Color.clear
                    .frame(height: 0)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("profileScroll")).minY)
                        }
                    )
                    .padding(.bottom, -16)
                
                if let user = viewModel.user {
                    // Header Parallax
                    header(user: user)
                        .padding(.horizontal, -16)
                    
                    // Info Principal
                    profileInfo(user: user)
                    
                    sectionHeader("Ubicaciones disponibles")
                    locationSelector
                        .overlay(alignment: .topLeading) {
                            if showLocationList {
                                locationList
                                    .padding(.top, 60)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .zIndex(2)
                            }
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2), value: showLocationList)
                        .zIndex(showLocationList ? 10 : 0)

                    // Grid de Contenido
                    sectionHeader("Fotos y Videos")
                    mediaGrid
                } else {
                    loadingView
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
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
                    .fill(Color.white)
                    .frame(width: 38, height: 38)
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
                    .overlay(Image(systemName: "chevron.left").foregroundColor(.black))
            }
            .padding(12)
            .offset(y: 12)
        }
        .background(Color.white.ignoresSafeArea())
        .tint(Color.fuchsia)
        .preferredColorScheme(.light)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            viewModel.loadData()
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
                    distanceKm: 2.3
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
                .init(color: Color.black.opacity(0.0), location: 0.0),
                .init(color: Color.black.opacity(0.0), location: 0.55),
                .init(color: Color.black.opacity(0.15), location: 0.75),
                .init(color: Color.black.opacity(0.25), location: 0.9),
                .init(color: Color.black.opacity(0.3), location: 1.0)
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
            .offset(y: -55)
            .padding(.bottom, -40)
            
            VStack(spacing: 8) {
                Text(user.name)
                    .foregroundColor(.black)
                    .font(.system(size: 24, weight: .bold))
                
                Text("@\(user.username)")
                    .foregroundColor(.gray)
                    .font(.system(size: 15))
                
                HStack(spacing: 12) {
                    if !user.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse").foregroundColor(.fuchsia).font(.caption)
                            Text(user.location).foregroundColor(.gray).font(.caption)
                        }
                    }
                    HStack(spacing: 4) {
                        if !user.location.isEmpty { Text("•").foregroundColor(.gray) }
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                        Text("4.8").foregroundColor(.black).font(.caption.bold())
                    }
                }
                
                // Categoría y Seguidores
                HStack(spacing: 16) {
                    Text("Foodie")
                        .foregroundColor(.black.opacity(0.8))
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                    
                    VStack(spacing: 0) {
                        Text(formatCount(user.followers))
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                        Text("Seguidores")
                            .foregroundColor(.gray)
                            .font(.system(size: 11))
                    }
                }
                .padding(.top, 4)
                
                // Botones
                HStack(spacing: 12) {
                    Button(action: { isFollowing.toggle() }) {
                        HStack(spacing: 8) {
                            Image(systemName: isFollowing ? "person.checkmark" : "person.badge.plus")
                                .foregroundColor(.white)
                            Text(isFollowing ? "Siguiendo" : "Seguir")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFollowing ? Color.gray : Color.fuchsia)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Text("✈️").font(.system(size: 16))
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
                        Image(systemName: "fork.knife")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(Color.fuchsia)
                            .clipShape(Circle())
                        
                        Text("Ver Menú Completo")
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 12)

                descriptionCard
                    .padding(.top, 10)
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 0)
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

    private var locationSelector: some View {
        Button(action: { showLocationList.toggle() }) {
            HStack(spacing: 10) {
                Image(systemName: "mappin")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text(selectedBranchName.isEmpty ? "Sucursal Condesa" : selectedBranchName)
                    .foregroundColor(.black)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(showLocationList ? 180 : 0))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var locationList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(hardcodedLocations) { loc in
                    Button(action: {
                        selectedBranchName = loc.name
                        showLocationList = false
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.name)
                                    .foregroundColor(.black)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(loc.address)
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                            Spacer()
                            Text(String(format: "%.1f km", loc.distanceKm))
                                .foregroundColor(.gray)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                    }
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: CGFloat(min(hardcodedLocations.count, 3)) * 70)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var mediaGrid: some View {
        LazyVGrid(columns: photoColumns, spacing: 12) {
            ForEach(hardcodedMedia) { item in
                WebImage(url: URL(string: item.url))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text(formatCount(item.likes))
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                        , alignment: .bottomLeading
                    )
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
