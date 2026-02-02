import SwiftUI
import SDWebImageSwiftUI

struct SearchUsersView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var isSearching = false
    
    // Mock Data for suggestions/results
    struct SearchUser: Identifiable {
        let id = UUID()
        let username: String
        let name: String
        let avatarUrl: String
        let isVerified: Bool
        let followers: String
    }
    
    let suggestedUsers: [SearchUser] = [
        .init(username: "jessica_eats", name: "Jessica Eats", avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2", isVerified: true, followers: "1.2M"),
        .init(username: "burger_king_fan", name: "Burger King Fan", avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e", isVerified: false, followers: "45K"),
        .init(username: "vegan_life", name: "Vegan Life 🌱", avatarUrl: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80", isVerified: true, followers: "890K"),
        .init(username: "chef_ramsey_clone", name: "Not Gordon", avatarUrl: "https://images.unsplash.com/photo-1583337130417-3346a1be7dee", isVerified: false, followers: "12K")
    ]
    
    var filteredUsers: [SearchUser] {
        if searchText.isEmpty {
            return suggestedUsers
        } else {
            return suggestedUsers.filter { $0.username.lowercased().contains(searchText.lowercased()) || $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Search Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Buscar usuarios...", text: $searchText)
                        .foregroundColor(.white)
                        .accentColor(.white)
                }
                .padding(10)
                .background(Color.white.opacity(0.12))
                .cornerRadius(8)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancelar")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10) // Safe area top handled by background
            .padding(.bottom, 12)
            .background(Color.black.ignoresSafeArea(edges: .top))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if searchText.isEmpty {
                        Text("Sugerencias")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }
                    
                    LazyVStack(spacing: 16) {
                        ForEach(filteredUsers) { user in
                            HStack(spacing: 12) {
                                WebImage(url: URL(string: user.avatarUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(user.username)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        if user.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Text(user.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text(user.followers)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Navigate to user profile
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.black.ignoresSafeArea())
        }
        .background(Color.black.ignoresSafeArea())
    }
}
