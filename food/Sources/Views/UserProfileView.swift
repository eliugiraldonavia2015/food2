import SwiftUI
import SDWebImageSwiftUI
import UIKit

struct UserProfileView: View {
    struct PhotoItem: Identifiable { let id = UUID(); let url: String; let title: String }
    struct DataModel {
        let coverUrl: String
        let avatarUrl: String
        let name: String
        let username: String
        let location: String
        let followers: Int
        let bio: String
        let photos: [PhotoItem]
    }

    let data: DataModel
    let onRefresh: (() async -> DataModel?)?
    @Environment(\.dismiss) private var dismiss
    @State private var isFollowing = false
    @State private var isRefreshing = false
    @State private var pullOffset: CGFloat = 0
    @State private var headerMinY: CGFloat = 0
    @State private var reachedThreshold = false
    @State private var didHapticThreshold = false
    @State private var refreshedData: DataModel?
    private var currentData: DataModel { refreshedData ?? data }
    private let headerHeight: CGFloat = 340
    private let refreshThreshold: CGFloat = UIScreen.main.bounds.height * 0.15
    private let photoColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private var photoItems: [PhotoItem] {
        (0..<12).map { i in i < currentData.photos.count ? currentData.photos[i] : PhotoItem(url: "", title: "") }
    }

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
                    .padding(.bottom, -16)
                header
                    .padding(.horizontal, -16)
                profileInfo
                descriptionCard
                sectionHeader("Fotos")
                photoGrid
            }
            .padding(.horizontal, 16)
        }
        .coordinateSpace(name: "profileScroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { y in
            pullOffset = max(0, y)
            reachedThreshold = pullOffset >= refreshThreshold
            if reachedThreshold && !didHapticThreshold {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                didHapticThreshold = true
            }
            if !reachedThreshold { didHapticThreshold = false }
        }
        .onPreferenceChange(HeaderOffsetPreferenceKey.self) { v in
            headerMinY = v
            pullOffset = max(0, v)
            reachedThreshold = pullOffset >= refreshThreshold
        }
        .safeAreaInset(edge: .top) {
            refreshHeader
                .allowsHitTesting(false)
                .zIndex(1001)
                .animation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2), value: isRefreshing)
        }
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
            }
            .padding(12)
            .offset(y: 80)
            .opacity(1)
            .zIndex(1000)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .named("profileScroll"))
                .onEnded { _ in
                    if reachedThreshold && !isRefreshing {
                        Task { await performRefresh() }
                    }
                }
        )
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .top)
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

    private var refreshHeader: some View {
        ZStack {
            if isRefreshing {
                VStack(spacing: 10) {
                    RefreshSpinner()
                    Text("Actualizando…")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.95)
                }
                .padding(.vertical, 12)
            } else if reachedThreshold {
                VStack(spacing: 10) {
                    RefreshSpinner()
                        .frame(width: 56, height: 56)
                    Text("Soltar para actualizar")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(0.98)
                }
                .padding(.vertical, 14)
                .transition(.move(edge: .top).combined(with: .opacity))
                .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 8)
            }
        }
        .frame(height: max(0, min(pullOffset, UIScreen.main.bounds.height * 0.25)))
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        )
    }

    private var profileInfo: some View {
        VStack(spacing: 12) {
            WebImage(url: URL(string: currentData.avatarUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.green, lineWidth: 2))
                .offset(y: -22)
            VStack(spacing: 6) {
                Text(currentData.name)
                    .foregroundColor(.white)
                    .font(.system(size: 26, weight: .bold))
                Text("@\(currentData.username)")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 16))
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse").foregroundColor(.white.opacity(0.9))
                        Text(currentData.location).foregroundColor(.white).font(.system(size: 14))
                    }
                }
                VStack(spacing: 2) {
                    Text(formatCount(currentData.followers))
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
        .padding(.top, -112)
        .padding(.bottom, 4)
    }

    private var descriptionCard: some View {
        Text(currentData.bio)
            .foregroundColor(.white)
            .font(.subheadline)
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var photoGrid: some View {
        LazyVGrid(columns: photoColumns, spacing: 12) {
            ForEach(0..<photoItems.count, id: \.self) { i in
                PhotoTileView(url: photoItems[i].url)
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

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).foregroundColor(.white).font(.headline)
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
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
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
                Text("🧑🏻‍🍳")
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

    struct RefreshSpinner: View {
        @State private var spin = false
        var body: some View {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 4)
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .trim(from: 0.0, to: 0.65)
                        .stroke(AngularGradient(colors: [.green, .white], center: .center), style: StrokeStyle(lineWidth: 4, lineCap: .round))
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

