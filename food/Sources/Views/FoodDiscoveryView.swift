import SwiftUI
import SDWebImageSwiftUI

struct FoodDiscoveryView: View {
    @State private var selectedCategory = "Burgers"
    @State private var searchText = ""
    var onClose: () -> Void
    
    // Datos simulados
    let categories = ["Burgers", "Pizza", "Saludable", "Carnes", "Drinks", "Sushi"]
    
    struct CategoryItem: Identifiable {
        let id = UUID()
        let name: String
        let icon: String // SF Symbol o emoji
        let color: Color
    }
    
    let categoryItems = [
        CategoryItem(name: "Burgers", icon: "hamburger", color: .orange),
        CategoryItem(name: "Pizza", icon: "fork.knife", color: .yellow),
        CategoryItem(name: "Saludable", icon: "leaf", color: .green),
        CategoryItem(name: "Carnes", icon: "flame", color: .red),
        CategoryItem(name: "Drinks", icon: "wineglass", color: .blue),
        CategoryItem(name: "Sushi", icon: "fish", color: .pink)
    ]
    
    struct PopularItem: Identifiable {
        let id = UUID()
        let name: String
        let restaurant: String
        let price: Double
        let time: String
        let rating: Double
        let discount: Int?
        let imageUrl: String
    }
    
    let popularItems = [
        PopularItem(
            name: "Plato Especial 1",
            restaurant: "Restaurante 1",
            price: 22.38,
            time: "38 min",
            rating: 4.9,
            discount: 32,
            imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c"
        ),
        PopularItem(
            name: "Plato Especial 3",
            restaurant: "Restaurante 3",
            price: 26.57,
            time: "38 min",
            rating: 4.7,
            discount: 28,
            imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd"
        ),
        PopularItem(
            name: "Plato Especial 5",
            restaurant: "Restaurante 5",
            price: 27.55,
            time: "33 min",
            rating: 4.8,
            discount: 37,
            imageUrl: "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header Section
                    VStack(spacing: 24) {
                        headerView
                        searchBar
                        categoriesFilter
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(Color.black)
                    
                    // Scrollable Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            heroBanner
                            
                            categoryIconsRow
                            
                            popularSection
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 50 {
                    onClose()
                }
            }
        )
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.green)
                    .font(.system(size: 18))
                Text("Tu ubicación")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            Text("Foodtook")
                .foregroundColor(.white)
                .font(.system(size: 22, weight: .heavy))
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.crop.circle.fill") // Avatar placeholder
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.green, lineWidth: 2)
                    )
            }
            .onTapGesture {
                // Close or profile action
                onClose()
            }
        }
        .padding(.horizontal)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Buscar restaurantes...", text: $searchText)
                    .foregroundColor(.white)
                Image(systemName: "mic")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(UIColor.systemGray6).opacity(0.15))
            .cornerRadius(25)
            
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color(UIColor.systemGray6).opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }
    
    private var categoriesFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category)
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(selectedCategory == category ? Color.green : Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var heroBanner: some View {
        ZStack(alignment: .leading) {
            // Background Image
            WebImage(url: URL(string: "https://images.unsplash.com/photo-1504674900247-0877df9cc836"))
                .resizable()
                .indicator(.activity)
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Get 50% Off")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("en tu primera orden sobre $25")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                
                Button(action: {}) {
                    Text("Ordenar ahora")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 180)
        .cornerRadius(24)
        .padding(.horizontal)
    }
    
    private var categoryIconsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(categoryItems) { item in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 64, height: 64)
                            
                            // Usamos imágenes del sistema como placeholder para los iconos coloridos
                            // En una app real serían Assets personalizados
                            Image(systemName: item.icon)
                                .font(.system(size: 28))
                                .foregroundColor(item.color)
                        }
                        
                        Text(item.name)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular cerca de ti")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(popularItems) { item in
                        popularCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func popularCard(item: PopularItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Header
            ZStack(alignment: .top) {
                WebImage(url: URL(string: item.imageUrl))
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 140)
                    .clipped()
                
                HStack {
                    if let discount = item.discount {
                        Text("\(discount)% off")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", item.rating))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                }
                .padding(10)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.restaurant)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                HStack {
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text(item.time)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
        }
        .frame(width: 200)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
