import SwiftUI
import SDWebImageSwiftUI

struct SearchFoodView: View {
    var animation: Namespace.ID
    @Binding var isPresented: Bool
    
    @FocusState private var isFocused: Bool
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
                        .font(.system(size: 20))
                    
                    TextField("Buscar comida, restaurantes...", text: $searchText)
                        .foregroundColor(.primary)
                        .focused($isFocused)
                        .submitLabel(.search)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                // Matched Geometry for smooth transition
                .matchedGeometryEffect(id: "searchBar", in: animation)
                
                Button(action: {
                    // 🚀 OPTIMIZACIÓN CRÍTICA:
                    // 1. Quitar foco del estado SwiftUI
                    isFocused = false
                    // 2. Forzar al sistema a cerrar el teclado INMEDIATAMENTE
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    // 3. Cerrar la vista con una animación suave pero rápida
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Text("Cancelar")
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10) // Safe area top handled by parent ZStack usually, or ignoresSafeArea
            .padding(.bottom, 12)
            .background(Color(uiColor: .systemBackground))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Categorías Horizontales (Pills)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(["Cercanos", "Top Rated", "Económico", "Vegano", "Premium"], id: \.self) { cat in
                                Text(cat)
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .foregroundColor(.primary)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                    
                    if searchText.isEmpty {
                        // Section Header
                        HStack {
                            Text("Explorar")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    LazyVStack(spacing: 16) {
                        ForEach(filteredItems) { item in
                            HStack(spacing: 16) {
                                // Imagen con sombra
                                WebImage(url: URL(string: item.imageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 4) {
                                        if item.type == "Restaurante" {
                                            Image(systemName: "fork.knife")
                                                .font(.caption)
                                        } else {
                                            Image(systemName: "flame.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        Text(item.detail)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if !item.rating.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        Text(item.rating.replacingOccurrences(of: " ⭐️", with: ""))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(8)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(uiColor: .tertiaryLabel))
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
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .onAppear {
            // 🚀 TECLADO INMEDIATO: Eliminado delay artificial de 0.1s
            // Usamos task asíncrona inmediata para asegurar que la vista ya está montada
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
}
