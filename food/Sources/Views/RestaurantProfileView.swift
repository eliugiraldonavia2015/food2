import SwiftUI
import SDWebImageSwiftUI
import UIKit
import AVKit

struct RestaurantProfileView: View {
    struct PhotoItem: Identifiable { let id = UUID(); let url: String; let title: String }
    struct LocationItem: Identifiable { let id = UUID(); let name: String; let address: String; let distanceKm: Double }
    struct FeatureFlags {
        var followEnabled: Bool = true
        var messageEnabled: Bool = true
        var menuEnabled: Bool = true
        var locationsEnabled: Bool = true
        var mediaEnabled: Bool = true
    }
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
        let features: FeatureFlags = .init()
    }

    let data: DataModel
    let onRefresh: (() async -> DataModel?)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isFollowing = false
    @State private var showLocationList = false
    @State private var selectedBranchName = ""
    @State private var isRefreshing = false
    @State private var pullOffset: CGFloat = 0
    @State private var headerMinY: CGFloat = 0
    @State private var reachedThreshold = false
    @State private var didHapticThreshold = false
    @State private var refreshedData: DataModel?
    @State private var showChat = false
    @StateObject private var messagesStore = MessagesStore()
    @State private var showVideoPlayer = false
    @State private var selectedVideoIndex = 0
    @State private var showMockMenu = false

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
        .sheet(isPresented: $showMockMenu) {
            MockRestaurantMenuView(
                restaurantName: currentData.name,
                location: currentData.location
            )
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            ProfileVideoPagerView(videos: fetchedVideos, startIndex: selectedVideoIndex)
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
        ZStack(alignment: .top) {
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

                HStack(spacing: 12) {
                    Button(action: { toggleFollowMock() }) {
                        HStack(spacing: 8) {
                            Image(systemName: isFollowing ? "checkmark" : "person.badge.plus")
                                .foregroundColor(.white)
                            Text(isFollowing ? "Siguiendo" : "Seguir")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.fuchsia.opacity(currentData.features.followEnabled ? 1.0 : 0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!currentData.features.followEnabled)

                    Button(action: { showChat = true }) {
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
                    .opacity(currentData.features.messageEnabled ? 1.0 : 0.55)
                    .disabled(!currentData.features.messageEnabled)
                }
                .padding(.top, 12)
            }
            .padding(.top, 60)
            .padding(.horizontal, 8)

            avatarView
                .offset(y: -55)
        }
        .padding(.top, 0)
    }

    private var avatarView: some View {
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
    }

    private var menuButtonView: some View {
        Button(action: { showMockMenu = true }) {
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
        .padding(.vertical, 8)
        .zIndex(1)
        .opacity(currentData.features.menuEnabled ? 1.0 : 0.55)
        .disabled(!currentData.features.menuEnabled)
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
        .opacity(currentData.features.locationsEnabled ? 1.0 : 0.55)
        .disabled(!currentData.features.locationsEnabled)
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
            openMaps(query: loc.address)
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

    private func openMaps(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            openURL(url)
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

    private func toggleFollowMock() {
        guard currentData.features.followEnabled else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            isFollowing.toggle()
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
            if !fetchedVideos.isEmpty {
                ForEach(Array(fetchedVideos.enumerated()), id: \.offset) { idx, v in
                    Button {
                        guard currentData.features.mediaEnabled else { return }
                        selectedVideoIndex = idx
                        showVideoPlayer = true
                    } label: {
                        PhotoTileView(url: v.thumbnailUrl)
                    }
                    .buttonStyle(.plain)
                    .opacity(currentData.features.mediaEnabled ? 1.0 : 0.65)
                }
            } else {
                ForEach(0..<photoItems.count, id: \.self) { i in
                    PhotoTileView(url: photoItems[i].url)
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

final class ProfileVideoPlayerHolder: ObservableObject {
    let player: AVPlayer

    init(urlString: String) {
        if let url = URL(string: urlString) {
            self.player = AVPlayer(url: url)
        } else {
            self.player = AVPlayer()
        }
    }
}

struct ProfileVideoPageView: View {
    let video: Video
    let isActive: Bool
    @StateObject private var holder: ProfileVideoPlayerHolder

    init(video: Video, isActive: Bool) {
        self.video = video
        self.isActive = isActive
        _holder = StateObject(wrappedValue: ProfileVideoPlayerHolder(urlString: video.videoUrl))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VideoPlayer(player: holder.player)
                .ignoresSafeArea()

            LinearGradient(colors: [Color.clear, Color.black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(2)
                Text(video.description)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 13))
                    .lineLimit(2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 22)
        }
        .onAppear { updatePlayback(isActive: isActive) }
        .onChange(of: isActive) { _, newValue in updatePlayback(isActive: newValue) }
        .onDisappear {
            holder.player.pause()
            holder.player.seek(to: .zero)
        }
    }

    private func updatePlayback(isActive: Bool) {
        if isActive {
            holder.player.play()
        } else {
            holder.player.pause()
        }
    }
}

struct ProfileVideoPagerView: View {
    let videos: [Video]
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if videos.isEmpty {
                Text("Sin videos")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
            } else {
                VerticalPager(count: videos.count, index: $index) { size, i in
                    ProfileVideoPageView(video: videos[i], isActive: index == i)
                        .frame(width: size.width, height: size.height)
                }
            }
            Button(action: { dismiss() }) {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(.white))
            }
            .padding(.leading, 16)
            .padding(.top, 50)
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            index = min(max(startIndex, 0), max(videos.count - 1, 0))
        }
    }
}

struct MockRestaurantMenuView: View {
    let restaurantName: String
    let location: String
    @Environment(\.dismiss) private var dismiss

    private struct MenuItem: Identifiable {
        let id = UUID()
        let name: String
        let desc: String
        let price: String
    }

    private let items: [MenuItem] = [
        .init(name: "Tacos al Pastor", desc: "Piña, cebolla, cilantro", price: "$85"),
        .init(name: "Gringa", desc: "Queso + pastor en tortilla de harina", price: "$95"),
        .init(name: "Quesadilla", desc: "Elige tu guiso", price: "$70"),
        .init(name: "Agua de Horchata", desc: "500 ml", price: "$35"),
        .init(name: "Agua de Jamaica", desc: "500 ml", price: "$35")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(restaurantName)
                            .foregroundColor(.black)
                            .font(.system(size: 26, weight: .bold))
                        Text(location)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding(.top, 8)

                    ForEach(items) { it in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(Color.fuchsia.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "fork.knife")
                                        .foregroundColor(.fuchsia)
                                        .font(.system(size: 16, weight: .bold))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(it.name)
                                        .foregroundColor(.black)
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Text(it.price)
                                        .foregroundColor(.black)
                                        .font(.system(size: 16, weight: .bold))
                                }
                                Text(it.desc)
                                    .foregroundColor(.gray)
                                    .font(.system(size: 13))
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Menú")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
        }
    }
}

