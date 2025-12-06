import SwiftUI
import SDWebImageSwiftUI

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
    @Environment(\.dismiss) private var dismiss
    @State private var isFollowing = false
    @State private var showLocationList = false
    @State private var selectedBranchName = ""
    @State private var isRefreshing = false
    @State private var pullOffset: CGFloat = 0
    @State private var refreshToken = UUID()
    private let photoColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private var photoItems: [PhotoItem] {
        (0..<12).map { i in i < data.photos.count ? data.photos[i] : PhotoItem(url: "", title: "") }
    }

    private let locations: [LocationItem] = [
        .init(name: "Sucursal Centro", address: "Av. Juárez 123, Centro", distanceKm: 3194.7),
        .init(name: "Sucursal Condesa", address: "Av. Michoacán 78, Condesa", distanceKm: 3195.6),
        .init(name: "Sucursal Roma", address: "Calle Orizaba 45, Roma Norte", distanceKm: 3195.6),
        .init(name: "Sucursal Polanco", address: "Masaryk 200, Polanco", distanceKm: 3196.1)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Color.clear
                    .frame(height: 0)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("profileScroll")).minY)
                        }
                    )
                header
                    .padding(.horizontal, -16)
                profileInfo
                menuPill
                descriptionCard
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
                            .zIndex(2)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2), value: showLocationList)
                .zIndex(showLocationList ? 10 : 0)
                sectionHeader("Fotos")
                photoGrid
            }
            .padding(.horizontal, 16)
        }
        .coordinateSpace(name: "profileScroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { y in
            pullOffset = max(0, y)
        }
        .overlay(alignment: .top) {
            refreshOverlay
                .allowsHitTesting(false)
                .animation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2), value: pullOffset)
                .animation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2), value: isRefreshing)
            if isRefreshing { refreshingHUD }
        }
        .refreshable { await performRefresh() }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            WebImage(url: URL(string: data.coverUrl), options: [.refreshCached])
                .resizable()
                .indicator(.activity)
                .transition(.fade(duration: 0.6))
                .aspectRatio(contentMode: .fill)
                .frame(height: 340)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.black.opacity(0.0), location: 0.0),
                            .init(color: Color.black.opacity(0.0), location: 0.55),
                            .init(color: Color.black.opacity(0.30), location: 0.65),
                            .init(color: Color.black.opacity(0.75), location: 0.75),
                            .init(color: Color.black.opacity(1.0), location: 0.85),
                            .init(color: Color.black.opacity(1.0), location: 0.92),
                            .init(color: Color.black.opacity(1.0), location: 0.97),
                            .init(color: Color.black.opacity(1.0), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: 80)
                .id(refreshToken)
            Button(action: { dismiss() }) {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
            }
            .padding(12)
            .offset(y: 160)
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
        .padding(.top, -80)
    }

    private var refreshOverlay: some View {
        let h = max(0, min(pullOffset, 120))
        return ZStack {
            if h > 0 {
                RefreshIndicatorView(progress: min(1, h / 120), isRefreshing: isRefreshing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: h)
        .frame(maxWidth: .infinity)
        .background(h > 0 ? Color.black.opacity(0.6) : Color.clear)
    }

    private var refreshingHUD: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("Actualizando…")
                .foregroundColor(.white)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .padding(.top, 44)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.9))
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .bottom)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(30)
    }

    private var profileInfo: some View {
        VStack(spacing: 12) {
            WebImage(url: URL(string: data.avatarUrl), options: [.refreshCached])
                .resizable()
                .scaledToFill()
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.green, lineWidth: 2))
                .offset(y: -22)
                .transition(.fade(duration: 0.6))
                .id(refreshToken)
            VStack(spacing: 6) {
                Text(data.name)
                    .foregroundColor(.white)
                    .font(.system(size: 26, weight: .bold))
                Text("@\(data.username)")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 16))
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse").foregroundColor(.white.opacity(0.9))
                        Text(data.location).foregroundColor(.white).font(.system(size: 14))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text(String(format: "%.1f", data.rating)).foregroundColor(.white).font(.system(size: 14))
                    }
                }
                HStack(spacing: 8) {
                    Text("Categoría:")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 14))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    Text(data.category)
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                VStack(spacing: 2) {
                    Text(formatCount(data.followers))
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                    Text("Seguidores")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: 13))
                }
            }
            .padding(.top, -10)
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
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill").foregroundColor(.white)
                        Text("Mensaje").foregroundColor(.white).font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.top, -22)
        .padding(.bottom, 4)
    }

    private var menuPill: some View {
        ZStack {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white)
                Spacer()
            }
            Text("Ver Menú Completo")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.black)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.8), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var descriptionCard: some View {
        Text(data.description)
            .foregroundColor(.white)
            .font(.subheadline)
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var locationSelector: some View {
        Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2)) { showLocationList.toggle() } }) {
            HStack(spacing: 10) {
                Image(systemName: "mappin")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text(selectedBranchName.isEmpty ? data.branch : selectedBranchName)
                    .foregroundColor(.white)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.white.opacity(0.8))
                    .rotationEffect(.degrees(showLocationList ? 180 : 0))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(width: UIScreen.main.bounds.width * 0.65)
        }
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var locationList: some View {
        let nearestId = locations.min(by: { $0.distanceKm < $1.distanceKm })?.id
        return ScrollView {
            VStack(spacing: 8) {
                ForEach(locations) { loc in
                    Button(action: {
                        selectedBranchName = loc.name
                        showLocationList = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(loc.name)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                                Text(loc.address)
                                    .foregroundColor(.white.opacity(0.75))
                                    .font(.footnote)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                if nearestId == loc.id {
                                    Text("Más cercano")
                                        .foregroundColor(.green)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                Text(String(format: "%.1f km", loc.distanceKm))
                                    .foregroundColor(.green)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(Color.white.opacity(nearestId == loc.id ? 0.12 : 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: CGFloat(min(locations.count, 3)) * 76)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.6), radius: 16, x: 0, y: 8)
    }

    private func performRefresh() async {
        await MainActor.run { isRefreshing = true }
        try? await Task.sleep(nanoseconds: UInt64(0.9 * 1_000_000_000))
        await MainActor.run {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2)) {
                refreshToken = UUID()
                isRefreshing = false
            }
        }
    }

    private var photoGrid: some View {
        LazyVGrid(columns: photoColumns, spacing: 12) {
            ForEach(0..<photoItems.count, id: \.self) { i in
                PhotoTileView(url: photoItems[i].url, reloadKey: refreshToken)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).foregroundColor(.white).font(.headline)
            Spacer()
        }
    }

    struct PhotoTileView: View {
        let url: String
        let reloadKey: UUID
        var body: some View {
            let finalURL = URL(string: url.isEmpty ? "" : url + (url.contains("unsplash.com") ? "?auto=format&fit=crop&w=800&q=80" : ""))
            AsyncImage(url: finalURL, transaction: Transaction(animation: .spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0.2))) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .transition(.scale.combined(with: .opacity))
                case .failure(_):
                    errorView
                @unknown default:
                    Color.gray.opacity(0.3)
                }
            }
            .frame(height: 120)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .id(reloadKey)
        }

        private var placeholder: some View {
            ZStack {
                LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
            }
        }

        private var errorView: some View {
            ZStack {
                LinearGradient(colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Text("🍽️")
                    .font(.system(size: 28))
            }
        }
    }

    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    struct RefreshIndicatorView: View {
        let progress: CGFloat
        let isRefreshing: Bool
        @State private var pulse = false
        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 46 + progress * 18, height: 46 + progress * 18)
                    .scaleEffect(isRefreshing ? (pulse ? 1.08 : 0.92) : 1)
                Image(systemName: "fork.knife")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(1 + progress * 0.15)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(isRefreshing ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2), value: pulse)
            .onAppear { if isRefreshing { pulse = true } }
            .onChange(of: isRefreshing) { v in pulse = v }
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count)/1_000_000) }
        else if count >= 1_000 { return String(format: "%.1fK", Double(count)/1_000) }
        else { return "\(count)" }
    }
}

