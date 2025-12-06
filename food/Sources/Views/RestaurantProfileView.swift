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

    private let locations: [LocationItem] = [
        .init(name: "Sucursal Centro", address: "Av. Juárez 123, Centro", distanceKm: 3194.7),
        .init(name: "Sucursal Condesa", address: "Av. Michoacán 78, Condesa", distanceKm: 3195.6),
        .init(name: "Sucursal Roma", address: "Calle Orizaba 45, Roma Norte", distanceKm: 3195.6),
        .init(name: "Sucursal Polanco", address: "Masaryk 200, Polanco", distanceKm: 3196.1)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                    .padding(.horizontal, -16)
                profileInfo
                menuPill
                descriptionCard
                sectionHeader("Ubicaciones disponibles")
                ZStack(alignment: .topLeading) {
                    HStack {
                        locationSelector
                        Spacer()
                    }
                    if showLocationList {
                        locationList
                            .padding(.top, 52)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2), value: showLocationList)
                sectionHeader("Fotos")
                photoGrid
            }
            .padding(.horizontal, 16)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            WebImage(url: URL(string: data.coverUrl))
                .resizable()
                .indicator(.activity)
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

    private var profileInfo: some View {
        VStack(spacing: 12) {
            WebImage(url: URL(string: data.avatarUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.green, lineWidth: 2))
                .offset(y: -22)
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
                        Text(String(format: "%.1f km", loc.distanceKm))
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .shadow(color: Color.black.opacity(0.6), radius: 16, x: 0, y: 8)
    }

    private var photoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(data.photos) { p in
                ZStack(alignment: .bottomLeading) {
                    WebImage(url: URL(string: p.url))
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    if !p.title.isEmpty {
                        Text(p.title)
                            .foregroundColor(.white)
                            .font(.footnote.weight(.semibold))
                            .padding(8)
                            .background(Color.black.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(6)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).foregroundColor(.white).font(.headline)
            Spacer()
        }
    }

    

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count)/1_000_000) }
        else if count >= 1_000 { return String(format: "%.1fK", Double(count)/1_000) }
        else { return "\(count)" }
    }
}

