import SwiftUI
import SDWebImageSwiftUI

struct RestaurantProfileView: View {
    struct PhotoItem: Identifiable { let id = UUID(); let url: String; let title: String }
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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                    .padding(.horizontal, -16)
                profileInfo
                menuPill
                descriptionCard
                sectionHeader("Ubicaciones disponibles")
                locationSelector
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
                .frame(height: 280)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                )
            Button(action: { dismiss() }) {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
    }

    private var profileInfo: some View {
        VStack(spacing: 12) {
            WebImage(url: URL(string: data.avatarUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.green, lineWidth: 2))
            Text(data.name)
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .bold))
            Text("@\(data.username)")
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse").foregroundColor(.white.opacity(0.9))
                    Text(data.location).foregroundColor(.white).font(.footnote)
                }
                HStack(spacing: 6) {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Text(String(format: "%.1f", data.rating)).foregroundColor(.white).font(.footnote)
                }
            }
            HStack(spacing: 8) {
                Text("Categoría:")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.footnote)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Text(data.category)
                    .foregroundColor(.green)
                    .font(.footnote.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            VStack(spacing: 2) {
                Text(formatCount(data.followers))
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .bold))
                Text("Seguidores")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.caption)
            }
            HStack(spacing: 12) {
                Button(action: { isFollowing.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.white)
                        Text(isFollowing ? "Siguiendo" : "Seguir")
                            .foregroundColor(.white)
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill").foregroundColor(.white)
                        Text("Mensaje").foregroundColor(.white).font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.bottom, 4)
    }

    private var menuPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.white)
            Text("Ver Menú Completo")
                .foregroundColor(.white)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding()
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
        HStack(spacing: 10) {
            Circle().fill(Color.green.opacity(0.25)).frame(width: 32, height: 32).overlay(Image(systemName: "mappin").foregroundColor(.green))
            Text(data.branch).foregroundColor(.white).font(.subheadline)
            Spacer()
            Image(systemName: "chevron.down").foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
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

