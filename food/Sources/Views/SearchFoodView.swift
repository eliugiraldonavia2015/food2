import SwiftUI
import SDWebImageSwiftUI

struct SearchFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var isSearching = false
    
    // Mock Data
    struct SearchItem: Identifiable {
        let id = UUID()
        let name: String
        let detail: String
        let imageUrl: String
        let type: String // "Restaurante" o "Platillo"
        let rating: String
    }
    
    let suggestedItems: [SearchItem] = [
        .init(name: "Hamburguesas", detail: "Categoría", imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd", type: "Categoría", rating: ""),
        .init(name: "Sushi", detail: "Categoría", imageUrl: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c", type: "Categoría", rating: ""),
        .init(name: "The Burger Joint", detail: "Hamburguesas • Americano", imageUrl: "https://images.unsplash.com/photo-1550547660-d9450f859349", type: "Restaurante", rating: "4.8 ⭐️"),
        .init(name: "Volcano Burger", detail: "The Burger Joint", imageUrl: "https://images.unsplash.com/photo-1586190848861-99c8a3da726c", type: "Platillo", rating: "4.9 ⭐️"),
        .init(name: "Pizza Paradise", detail: "Italiana • Pizza", imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591", type: "Restaurante", rating: "4.6 ⭐️")
    ]
    
    var filteredItems: [SearchItem] {
        if searchText.isEmpty {
            return suggestedItems
        } else {
            return suggestedItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.detail.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Search Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar comida, restaurantes...", text: $searchText)
                        .foregroundColor(.primary)
                }
                .padding(10)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancelar")
                        .foregroundColor(.primary)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(Color(uiColor: .systemBackground).ignoresSafeArea(edges: .top))
            .overlay(
                Rectangle()
                    .fill(Color(uiColor: .separator))
                    .frame(height: 0.5),
                alignment: .bottom
            )
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if searchText.isEmpty {
                        Text("Explorar")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }
                    
                    LazyVStack(spacing: 16) {
                        ForEach(filteredItems) { item in
                            HStack(spacing: 12) {
                                WebImage(url: URL(string: item.imageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text(item.detail)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if !item.rating.isEmpty {
                                    Text(item.rating)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Navigate to details
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}
