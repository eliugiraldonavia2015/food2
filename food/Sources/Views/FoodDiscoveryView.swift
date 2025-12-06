import SwiftUI
import SDWebImageSwiftUI

struct FoodDiscoveryView: View {
    @State private var selectedCategory = "Burgers"
    @State private var searchText = ""
    @State private var showFilters = false // Estado para mostrar filtros
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
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Fixed Header Section
                VStack(spacing: 12) {
                    headerView
                    searchBar
                    categoriesFilter
                }
                .padding(.top, 55) // Ajuste manual para subirlo más
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
            .blur(radius: showFilters ? 5 : 0) // Blur effect when filters are shown
            
            // Dimming Background
            if showFilters {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showFilters = false }
                    }
                    .transition(.opacity)
            }
            
            // Filter Sheet
            if showFilters {
                FilterSheet(onClose: { withAnimation { showFilters = false } })
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
        }
        .ignoresSafeArea(edges: .top)
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 50 && !showFilters {
                    onClose()
                }
            }
        )
        .animation(.easeInOut, value: showFilters)
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
            
            Button(action: {
                withAnimation { showFilters = true }
            }) {
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

// MARK: - Filter Sheet
struct FilterSheet: View {
    var onClose: () -> Void
    @State private var expandedSections: Set<String> = ["Precio", "Calificación", "Tipo de comida"]
    @State private var priceValue: Double = 25
    @State private var timeValue: Double = 30
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Filtros")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            // Limpiar acción
                        }) {
                            Text("Limpiar Filtros")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .padding(.top, 10)
                    
                    // Content List
                    ScrollView {
                        VStack(spacing: 12) {
                            // Precio
                            filterSection(title: "Precio: $0 - $50", id: "Precio") {
                                VStack(spacing: 8) {
                                    Slider(value: $priceValue, in: 0...50, step: 1)
                                        .accentColor(.green)
                                    HStack {
                                        Text("$0").font(.caption).foregroundColor(.gray)
                                        Spacer()
                                        Text("$50").font(.caption).foregroundColor(.gray)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Tiempo
                            filterSection(title: "Tiempo: 0 - 60 min", id: "Tiempo") {
                                VStack(spacing: 8) {
                                    Slider(value: $timeValue, in: 0...60, step: 5)
                                        .accentColor(.green)
                                    HStack {
                                        Text("0 min").font(.caption).foregroundColor(.gray)
                                        Spacer()
                                        Text("60 min").font(.caption).foregroundColor(.gray)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Calificación
                            filterSection(title: "Calificación", id: "Calificación") {
                                HStack(spacing: 12) {
                                    ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                                        Button(action: {}) {
                                            HStack(spacing: 4) {
                                                Text("\(star)")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.yellow)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.06))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Tipo de comida
                            filterSection(title: "Tipo de comida", id: "Tipo de comida") {
                                FlowLayout(spacing: 10) {
                                    ForEach(["Mexicana", "Italiana", "China", "Japonesa", "Vegana", "Vegetariana"], id: \.self) { type in
                                        Text(type)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.06))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Distancia
                            filterSection(title: "Distancia: Hasta 5 km", id: "Distancia") {
                                EmptyView()
                            }
                            
                            // Ofertas
                            filterSection(title: "Ofertas y descuentos", id: "Ofertas") {
                                EmptyView()
                            }
                        }
                        .padding()
                        .padding(.bottom, 80) // Space for apply button
                    }
                    
                    // Apply Button
                    Button(action: onClose) {
                        Text("Aplicar")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .frame(height: geometry.size.height * 0.65)
                .background(Color(red: 0.1, green: 0.1, blue: 0.1)) // Dark background
                .cornerRadius(24, corners: [.topLeft, .topRight])
            }
        }
        .ignoresSafeArea()
    }
    
    private func filterSection<Content: View>(title: String, id: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation {
                    if expandedSections.contains(id) {
                        expandedSections.remove(id)
                    } else {
                        expandedSections.insert(id)
                    }
                }
            }) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(expandedSections.contains(id) ? 180 : 0))
                }
                .padding()
                .background(Color.white.opacity(0.06))
            }
            
            if expandedSections.contains(id) {
                content()
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

// Helper for FlowLayout (Simple horizontal wrapping)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flow(subviews: subviews, containerWidth: proposal.width ?? .infinity)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flow(subviews: subviews, containerWidth: bounds.width)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func flow(subviews: Subviews, containerWidth: CGFloat) -> (size: CGSize, points: [CGPoint]) {
        var points: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            points.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), points)
    }
}

// Helper for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
