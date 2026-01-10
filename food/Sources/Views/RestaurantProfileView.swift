import SwiftUI
import SDWebImageSwiftUI
import UIKit

struct RestaurantProfileView: View {
    struct PhotoItem: Identifiable { let id = UUID(); let url: String; let title: String }
    struct LocationItem: Identifiable { let id = UUID(); let name: String; let address: String; let distanceKm: Double }
    struct DataModel {
        let coverUrl: String
        let avatarUrl: String
        let name: String
        let username: String
        let location: String
        let rating: Double
        let category: String
        let followers: Int
        let description: String
        let branch: String
        let photos: [PhotoItem]
    }

    let data: DataModel
    let onRefresh: (() async -> DataModel?)?
    @Environment(\.dismiss) private var dismiss
    @State private var isFollowing = false
    @State private var showLocationList = false
    @State private var selectedBranchName = ""
    @State private var isRefreshing = false
    @State private var pullOffset: CGFloat = 0
    @State private var headerMinY: CGFloat = 0
    @State private var reachedThreshold = false
    @State private var didHapticThreshold = false
    @State private var refreshedData: DataModel?
    @State private var showFullMenu = false
    @State private var showChat = false
    @StateObject private var messagesStore = MessagesStore()

    private var currentData: DataModel { refreshedData ?? data }
    private let headerHeight: CGFloat = 220
    private let refreshThreshold: CGFloat = UIScreen.main.bounds.height * 0.15
    private let photoColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    @State private var fetchedVideos: [Video] = []
    
    private var photoItems: [PhotoItem] {
        if !fetchedVideos.isEmpty {
            return fetchedVideos.map { video in
                PhotoItem(url: video.thumbnailUrl, title: video.title)
            }
        }
        return (0..<12).map { i in i < currentData.photos.count ? currentData.photos[i] : PhotoItem(url: "", title: "") }
    }

    private let locations: [LocationItem] = [
        .init(name: "Sucursal Centro", address: "Av. Juárez 123, Centro", distanceKm: 3194.7),
        .init(name: "Sucursal Condesa", address: "Av. Michoacán 78, Condesa", distanceKm: 3195.6),
        .init(name: "Sucursal Roma", address: "Calle Orizaba 45, Roma Norte", distanceKm: 3195.6),
        .init(name: "Sucursal Polanco", address: "Masaryk 200, Polanco", distanceKm: 3196.1)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header ocupando todo el ancho
                header
                
                // Contenido del perfil
                VStack(spacing: 20) {
                    profileInfo
                    menuButtonView
                    aboutSection
                    
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Ubicaciones disponibles")
                        HStack {
                            locationSelector
                            Spacer()
                        }
                        .overlay(alignment: .topLeading) {
                            if showLocationList {
                                locationList
                                    .padding(.top, 52)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .zIndex(20)
                            }
                        }
                        .zIndex(showLocationList ? 20 : 1)
                    }
                    .zIndex(showLocationList ? 20 : 1)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Fotos y Videos")
                        photoGrid
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .coordinateSpace(name: "profileScroll")
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .overlay(Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundColor(.black))
            }
            .padding(.leading, 16)
            .padding(.top, 50) // Posición más baja para evitar el notch/isla
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            loadVideos()
        }
        .fullScreenCover(isPresented: $showFullMenu) {
            FullMenuView(
                restaurantId: currentData.username.replacingOccurrences(of: " ", with: "").lowercased(),
                restaurantName: currentData.name,
                coverUrl: currentData.coverUrl,
                avatarUrl: currentData.avatarUrl,
                location: currentData.location,
                branchName: selectedBranchName.isEmpty ? currentData.branch : selectedBranchName,
                distanceKm: 2.3
            )
        }
        .sheet(isPresented: $showChat) {
            ChatView(
                conversation: Conversation(
                    title: currentData.name,
                    subtitle: "Responde habitualmente en 1 hora",
                    timestamp: "Ahora",
                    unreadCount: 0,
                    avatarSystemName: "storefront.fill",
                    isOnline: true
                ),
                store: messagesStore
            )
        }
    }

    private var header: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            ZStack(alignment: .topLeading) {
                coverImage(minY: minY)
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

    private func coverImage(minY: CGFloat) -> some View {
        WebImage(url: URL(string: currentData.coverUrl))
            .resizable()
            .indicator(.activity)
            .aspectRatio(contentMode: .fill)
            .frame(height: minY > 0 ? headerHeight + minY : headerHeight)
            .blur(radius: minY > 0 ? min(12, minY / 18) : 0, opaque: true)
            .clipped()
            .overlay(coverGradient)
            .offset(y: minY > 0 ? -minY : 0)
    }


    private var pullProgress: CGFloat { min(max(pullOffset / refreshThreshold, 0), 1) }

    private var refreshOverlay: some View {
        ZStack {
            if isRefreshing {
                RefreshSpinner()
                Text("Actualizando…")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.top, 64)
                    .transition(.opacity)
            } else if pullOffset > 0 {
                VStack(spacing: 10) {
                    if reachedThreshold {
                        RefreshSpinner()
                            .frame(width: 42, height: 42)
                        Text("Soltar para actualizar")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                            .opacity(0.95)
                    } else {
                        ProgressRing(progress: pullProgress)
                            .frame(width: 42, height: 42)
                        Text("Desliza para actualizar")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                            .opacity(0.95)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: max(0, min(pullOffset, 140)))
        .frame(maxWidth: .infinity)
        .background((pullOffset > 0 || isRefreshing) ? Color.black.opacity(0.6) : Color.clear)
    }

    private var refreshHeader: some View {
        ZStack {
            if isRefreshing {
                VStack(spacing: 10) {
                    RefreshSpinner()
                    Text("Actualizando…")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.95)
                }
                .padding(.vertical, 12)
            } else if reachedThreshold {
                VStack(spacing: 10) {
                    RefreshSpinner()
                        .frame(width: 56, height: 56)
                    Text("Soltar para actualizar")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(0.98)
                }
                .padding(.vertical, 14)
                .transition(.move(edge: .top).combined(with: .opacity))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 8)
            }
        }
        .frame(height: max(0, min(pullOffset, UIScreen.main.bounds.height * 0.25)))
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        )
    }

    private var profileInfo: some View {
        VStack(spacing: 0) {
            // Avatar con Placeholder
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                if let url = URL(string: currentData.avatarUrl), !currentData.avatarUrl.isEmpty {
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
            .padding(.bottom, -40) // Ajuste fino para acercar el texto
            
            VStack(spacing: 8) {
                Text(currentData.name)
                    .foregroundColor(.black)
                    .font(.system(size: 24, weight: .bold))
                
                Text("@\(currentData.username)")
                    .foregroundColor(.gray)
                    .font(.system(size: 15))
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse").foregroundColor(.fuchsia).font(.caption)
                        Text(currentData.location).foregroundColor(.gray).font(.caption)
                    }
                    HStack(spacing: 4) {
                        Text("•").foregroundColor(.gray)
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                        Text(String(format: "%.1f", currentData.rating)).foregroundColor(.black).font(.caption.bold())
                    }
                }
                
                // Categoría y Seguidores alineados
                HStack(spacing: 16) {
                    Text(currentData.category)
                        .foregroundColor(.black.opacity(0.8))
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                    
                    VStack(spacing: 0) {
                        Text(formatCount(currentData.followers))
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
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.white)
                            Text(isFollowing ? "Siguiendo" : "Seguir")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.fuchsia)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button(action: {
                        showChat = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.fuchsia)
                            Text("Mensaje")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 0)
    }

    private var menuButtonView: some View {
        Button(action: { showFullMenu = true }) {
            HStack(spacing: 12) {
                Image(systemName: "fork.knife")
                    .foregroundColor(.white) // Icono blanco sobre fondo fuchsia
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 36, height: 36)
                    .background(Color.fuchsia) // Fondo fuchsia sólido
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
        .padding(.vertical, 8)
        .zIndex(1) // Asegurar visibilidad
    }

    private var aboutSection: some View {
        Text(currentData.description)
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
    }

    private var locationSelector: some View {
        Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2)) { showLocationList.toggle() } }) {
            HStack(spacing: 10) {
                Image(systemName: "mappin")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text(selectedBranchName.isEmpty ? currentData.branch : selectedBranchName)
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
        let nearestId = locations.min(by: { $0.distanceKm < $1.distanceKm })?.id
        return ScrollView {
            VStack(spacing: 8) {
                ForEach(locations) { loc in
                    locationRow(loc: loc, nearestId: nearestId)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: CGFloat(min(locations.count, 3)) * 76)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func locationRow(loc: LocationItem, nearestId: UUID?) -> some View {
        Button(action: {
            selectedBranchName = loc.name
            showLocationList = false
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.name)
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                    Text(loc.address)
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
                Spacer()
                HStack(spacing: 8) {
                    nearestBadge(nearest: nearestId == loc.id)
                    distanceText(km: loc.distanceKm)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(nearestId == loc.id ? 0.3 : 0.2), lineWidth: 1))
        }
    }

    private func nearestBadge(nearest: Bool) -> some View {
        Group {
            if nearest {
                Text("Más cercano")
                    .foregroundColor(.green)
                    .font(.caption2.weight(.semibold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private func distanceText(km: Double) -> some View {
        Text(String(format: "%.1f km", km))
            .foregroundColor(.green)
            .font(.system(size: 14, weight: .semibold))
    }

    private func loadVideos() {
        // Intentar cargar videos reales si el usuario existe
        DatabaseService.shared.getUidForUsername(currentData.username) { uid in
            guard let uid = uid else { return }
            DatabaseService.shared.fetchUserVideos(userId: uid) { result in
                if case .success(let videos) = result {
                    DispatchQueue.main.async {
                        self.fetchedVideos = videos
                    }
                }
            }
        }
    }

    private func performRefresh() async {
        await MainActor.run { isRefreshing = true }
        let newData = await onRefresh?()
        await MainActor.run {
            if let newData = newData {
                refreshedData = newData
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2)) {
                isRefreshing = false
            }
        }
    }

    private var photoGrid: some View {
        LazyVGrid(columns: photoColumns, spacing: 12) {
            ForEach(0..<photoItems.count, id: \.self) { i in
                PhotoTileView(url: photoItems[i].url)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).foregroundColor(.black).font(.headline)
            Spacer()
        }
    }

    struct PhotoTileView: View {
        let url: String
        var body: some View {
            let finalURL = URL(string: url.isEmpty ? "" : url + (url.contains("unsplash.com") ? "?auto=format&fit=crop&w=800&q=80" : ""))
            AsyncImage(url: finalURL) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                case .failure(_):
                    errorView
                @unknown default:
                    Color.gray.opacity(0.3)
                }
            }
            .frame(height: 120)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        }

        private var placeholder: some View {
            ZStack {
                LinearGradient(colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
        }

        private var errorView: some View {
            ZStack {
                LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Text("🍽️")
                    .font(.system(size: 28))
            }
        }
    }

    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    struct HeaderOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }
    struct ProgressRing: View {
        let progress: CGFloat
        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AngularGradient(colors: [.fuchsia, .white], center: .center), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.25, dampingFraction: 0.9, blendDuration: 0.2), value: progress)
            }
        }
    }

    struct RefreshSpinner: View {
        @State private var spin = false
        var body: some View {
            Circle()
                .stroke(Color.gray.opacity(0.25), lineWidth: 4)
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .trim(from: 0.0, to: 0.65)
                        .stroke(AngularGradient(colors: [.fuchsia, .white], center: .center), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 42, height: 42)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: spin)
                )
                .onAppear { spin = true }
                .onDisappear { spin = false }
        }
    }
    

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count)/1_000_000) }
        else if count >= 1_000 { return String(format: "%.1fK", Double(count)/1_000) }
        else { return "\(count)" }
    }
}

