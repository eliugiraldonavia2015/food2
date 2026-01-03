import SwiftUI
import SDWebImageSwiftUI

// ✅ Versión conectada a datos reales usando ViewModel
struct UserProfileView: View {
    @StateObject private var viewModel: PublicProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Init con userId para cargar datos reales
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: PublicProfileViewModel(userId: userId))
    }

    // ✅ Nuevo Init para datos Mock (desde FeedItem)
    // Permite usar el diseño real con datos estáticos del feed
    init(mockItem: FeedItem) {
        let mockData = PublicProfileViewModel.UserProfileData(
            id: "mock_user",
            username: mockItem.username,
            name: mockItem.username,
            bio: mockItem.description,
            photoUrl: mockItem.avatarUrl,
            coverUrl: mockItem.backgroundUrl,
            followers: mockItem.likes, // Simulamos followers con likes
            location: "Food City"
        )
        _viewModel = StateObject(wrappedValue: PublicProfileViewModel(userId: "mock_user", initialData: mockData))
    }
    
    // Estado UI
    @State private var isFollowing = false
    @State private var pullOffset: CGFloat = 0
    @State private var headerMinY: CGFloat = 0
    private let headerHeight: CGFloat = 340
    private let refreshThreshold: CGFloat = UIScreen.main.bounds.height * 0.15
    private let photoColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) { // Spacing 0 para diseño ajustado
                if let user = viewModel.user {
                    // Header Parallax
                    GeometryReader { geo in
                        let minY = geo.frame(in: .global).minY
                        ZStack(alignment: .bottom) {
                            WebImage(url: URL(string: user.coverUrl))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: minY > 0 ? headerHeight + minY : headerHeight)
                                .blur(radius: minY > 0 ? min(10, minY / 20) : 0)
                                .overlay(Color.black.opacity(0.3))
                                .offset(y: minY > 0 ? -minY : 0)
                                .clipped()
                            
                            // Avatar superpuesto
                            VStack {
                                WebImage(url: URL(string: user.photoUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                                    .shadow(radius: 5)
                            }
                            .offset(y: 45) // Mitad fuera del header
                        }
                    }
                    .frame(height: headerHeight)
                    
                    // Info del usuario
                    VStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text(user.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding(.top, 50) // Espacio para el avatar
                            
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(user.bio)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        // Stats Row
                        HStack(spacing: 40) {
                            statItem(value: "\(user.followers)", label: "Seguidores")
                            statItem(value: "250", label: "Siguiendo")
                            statItem(value: "\(viewModel.videos.count)", label: "Videos")
                        }
                        .padding(.vertical, 12)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: { isFollowing.toggle() }) {
                                Text(isFollowing ? "Siguiendo" : "Seguir")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isFollowing ? .white : .black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(isFollowing ? Color.white.opacity(0.15) : Color.green)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Grid de Videos
                        LazyVGrid(columns: photoColumns, spacing: 1) {
                            ForEach(viewModel.videos) { video in
                                WebImage(url: URL(string: video.thumbnailUrl))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 130)
                                    .clipped()
                                    .overlay(
                                        HStack {
                                            Image(systemName: "play.fill")
                                                .font(.caption2)
                                            Text("\(video.likes)")
                                                .font(.caption2.bold())
                                        }
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .shadow(radius: 2)
                                        , alignment: .bottomLeading
                                    )
                            }
                        }
                    }
                } else {
                    // Loading State
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Spacer()
                    }
                    .frame(height: UIScreen.main.bounds.height)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .edgesIgnoringSafeArea(.top)
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 50)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}


