import SwiftUI
import SDWebImageSwiftUI

struct FoodDiscoveryView: View {
    @State private var selectedCategory: String? = nil
    @State private var showAllCategories = false
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var showAddressSelection = false
    @State private var currentAddress = "Polanco, CDMX"
    
    // External Actions & Animation
    var onClose: () -> Void
    var onSearch: () -> Void
    var animation: Namespace.ID
    @Binding var selectedStory: RestaurantUpdate? // Binding for stories
    
    @State private var orderTapScale: CGFloat = 1.0
    
    // Scroll Tracking
    @State private var scrollOffset: CGFloat = 0
    
    // Animation States
    @State private var hasAppeared = false
    @State private var animateHeader = false
    @State private var animateSearch = false
    @State private var animateCategories = false
    @State private var animateContent = false
    
    // Navigation States
    @State private var showFullMenu = false
    @State private var selectedDishId: String? = nil
    
    // MARK: - Design Constants
    @Environment(\.colorScheme) var colorScheme
    
    private var isDarkMode: Bool { colorScheme == .dark }

    // Colors
    private var primaryColor: Color { .green }
    private var accentColor: Color { .orange }
    
    private var backgroundColor: Color {
        isDarkMode ? Color.black : Color.white
    }
    
    private var surfaceColor: Color {
        // Cards, Sheets, etc.
        isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var secondaryBackgroundColor: Color {
        // Search bar, secondary buttons
        isDarkMode ? Color(red: 0.17, green: 0.17, blue: 0.18) : Color(red: 0.96, green: 0.96, blue: 0.98)
    }
    
    private var primaryTextColor: Color {
        isDarkMode ? .white : Color.black.opacity(0.9)
    }
    
    private var secondaryTextColor: Color {
        isDarkMode ? Color(red: 0.6, green: 0.6, blue: 0.65) : Color.gray
    }
    
    // MARK: - Data Models
    // Using shared CategoryItem model
    private let categoryItems = allCategoryItems
    
    struct PopularItem: Identifiable {
        let id: UUID
        let name: String
        let restaurant: String
        let price: Double
        let time: String
        let rating: Double
        let discount: Int?
        let imageUrl: String
        
        init(id: UUID = UUID(), name: String, restaurant: String, price: Double, time: String, rating: Double, discount: Int?, imageUrl: String) {
            self.id = id
            self.name = name
            self.restaurant = restaurant
            self.price = price
            self.time = time
            self.rating = rating
            self.discount = discount
            self.imageUrl = imageUrl
        }
    }
    
    private static let popularItems = [
        PopularItem(name: "Zen Garden Bowl", restaurant: "Green Life", price: 145.00, time: "20-30 min", rating: 4.8, discount: nil, imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd"),
        PopularItem(name: "Truffle Pizza", restaurant: "Mozza", price: 220.00, time: "30-45 min", rating: 4.7, discount: 15, imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591"),
        PopularItem(name: "Salmon Rice Bowl", restaurant: "Tokyo Eats", price: 210.00, time: "25-40 min", rating: 4.9, discount: nil, imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c")
    ]
    
    struct RestaurantItem: Identifiable {
        let id: UUID
        let title: String
        let subtitle: String
        let time: String
        let delivery: String
        let rating: Double
        let imageUrl: String
        let priceLevel: String
        let tags: [String]
        
        init(id: UUID = UUID(), title: String, subtitle: String, time: String, delivery: String, rating: Double, imageUrl: String, priceLevel: String, tags: [String]) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.time = time
            self.delivery = delivery
            self.rating = rating
            self.imageUrl = imageUrl
            self.priceLevel = priceLevel
            self.tags = tags
        }
    }

    private static let featuredRestaurants: [RestaurantItem] = [
        RestaurantItem(title: "Sakura Artisanal Sushi", subtitle: "Japonés • Premium", time: "20-30 min", delivery: "Envío gratis", rating: 4.9, imageUrl: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c", priceLevel: "$$$", tags: ["Premium"]),
        RestaurantItem(title: "The Grill Master", subtitle: "Hamburguesas • Grill", time: "15-25 min", delivery: "Pick-up disponible", rating: 4.7, imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd", priceLevel: "$$", tags: []),
        RestaurantItem(title: "La Dolce Vita", subtitle: "Italiana • Pasta", time: "30-45 min", delivery: "Envío $25", rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1473093226795-d6b06c273fd7", priceLevel: "$$", tags: [])
    ]
    
    struct TrendingItem: Identifiable {
        let id: UUID
        let name: String
        let price: String
        let imageUrl: String
        let badge: String?
        
        init(id: UUID = UUID(), name: String, price: String, imageUrl: String, badge: String?) {
            self.id = id
            self.name = name
            self.price = price
            self.imageUrl = imageUrl
            self.badge = badge
        }
    }

    private static let trendingItems: [TrendingItem] = [
        TrendingItem(name: "Baked Feta Pasta", price: "$185.00", imageUrl: "https://images.unsplash.com/photo-1626844131082-256783844137", badge: "TIKTOK VIRAL"),
        TrendingItem(name: "Salmon Rice Bowl", price: "$210.00", imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c", badge: nil),
        TrendingItem(name: "Birria Tacos", price: "$120.00", imageUrl: "https://images.unsplash.com/photo-1504544750208-dc0358e63f7f", badge: "POPULAR")
    ]
    
    // Stories Data
    let updates: [RestaurantUpdate] = [
        .init(name: "McDonald's", logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/McDonald%27s_Golden_Arches.svg/1200px-McDonald%27s_Golden_Arches.svg.png", hasUpdate: true),
        .init(name: "Starbucks", logo: "https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/1200px-Starbucks_Corporation_Logo_2011.svg.png", hasUpdate: true),
        .init(name: "KFC", logo: "https://upload.wikimedia.org/wikipedia/en/thumb/b/bf/KFC_logo.svg/1200px-KFC_logo.svg.png", hasUpdate: false),
        .init(name: "Domino's", logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Domino%27s_pizza_logo.svg/1200px-Domino%27s_pizza_logo.svg.png", hasUpdate: true)
    ]
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Fixed Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 60) // Safe Area adjustment
                    .padding(.bottom, 10)
                    .background(backgroundColor)
                
                // Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // Search Bar
                        searchBar
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        
                        // Stories
                        restaurantUpdatesSection
                            .padding(.bottom, 24)
                        
                        // Hero Promo
                        heroPromo
                            .scaleEffect(animateContent ? 1 : 0.9)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        
                        // Categories
                        categoriesSection
                            .padding(.bottom, 32)
                        
                        // Recommended (Horizontal Large Cards)
                        recommendedSection
                            .padding(.bottom, 32)
                        
                        // Featured Restaurants (Full Width Cards)
                        featuredRestaurantsSection
                            .padding(.bottom, 32)
                            
                        // Trending Dishes
                        trendingSection
                            .padding(.bottom, 120) // Space for floating bar
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ViewOffsetKey.self) { value in
                    withAnimation {
                        scrollOffset = value
                    }
                }
            }
            .blur(radius: showFilters ? 6 : 0)
            
            // Floating Active Order Bar
            activeOrderBar
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
                .offset(y: animateContent ? 0 : 100)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8), value: animateContent)
            
            // Dimming Background
            if showFilters {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showFilters = false }
                    }
                    .transition(.opacity)
                    .zIndex(30)
            }
            
            // Filter Sheet
            if showFilters {
                FilterSheet(onClose: { withAnimation { showFilters = false } })
                    .transition(.move(edge: .bottom))
                    .zIndex(40)
            }
        }
        .fullScreenCover(isPresented: $showAllCategories) {
            AllCategoriesView(selectedCategory: $selectedCategory)
        }
        .fullScreenCover(isPresented: $showAddressSelection) {
            DeliveryAddressSelectionView(
                addresses: [
                    .init(
                        id: "home",
                        title: "Casa",
                        detail: "Av. Paseo de la Reforma 222,\nJuárez, Cuauhtémoc, 06600\nCiudad de México, CDMX",
                        systemIcon: "house.fill"
                    ),
                    .init(
                        id: "office",
                        title: "Oficina",
                        detail: "Torre Virreyes, Pedregal 24, Molino\ndel Rey, 11040 Ciudad de México,\nCDMX",
                        systemIcon: "briefcase.fill"
                    ),
                    .init(
                        id: "partner",
                        title: "Novia",
                        detail: "Calle Colima 123, Roma Norte,\nCuauhtémoc, 06700 Ciudad de\nMéxico, CDMX",
                        systemIcon: "heart.fill"
                    )
                ],
                initialSelectedId: nil
            ) { selected in
                currentAddress = selected.title
            }
        }
        .fullScreenCover(isPresented: $showFullMenu) {
            FullMenuView(
                restaurantId: "hardcoded-discovery",
                restaurantName: "FoodTook Demo",
                coverUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
                avatarUrl: "https://images.unsplash.com/photo-1556910103-1c02745a30bf",
                location: "Polanco, CDMX",
                branchName: "Sucursal Principal",
                distanceKm: 1.5,
                initialDishId: selectedDishId
            )
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        guard !hasAppeared else { return }
        hasAppeared = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animateHeader = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            animateSearch = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            animateCategories = true
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
            animateContent = true
        }
    }
    
    // MARK: - New UI Components
    
    private var headerView: some View {
        HStack(alignment: .center) {
            // Location
            Button(action: { showAddressSelection = true }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(primaryColor.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(primaryColor)
                            .font(.system(size: 18))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ENVIAR A:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(secondaryTextColor)
                            .tracking(0.5)
                        
                        HStack(spacing: 4) {
                            Text(currentAddress)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(primaryTextColor)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Right Icons
            HStack(spacing: 12) {
                if scrollOffset > 80 {
                    Button(action: { onSearch() }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 40, height: 40)
                            .background(secondaryBackgroundColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }
                
                Button(action: {}) {
                    Image(systemName: "gift")
                        .font(.system(size: 20))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 40, height: 40)
                        .background(secondaryBackgroundColor)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: onClose) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 40, height: 40)
                            .background(secondaryBackgroundColor)
                            .clipShape(Circle())
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 1.5)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .opacity(animateHeader ? 1 : 0)
        .offset(y: animateHeader ? 0 : -20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateHeader)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            // Fake Search Bar (Button)
            Button(action: { onSearch() }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(secondaryTextColor)
                        .font(.system(size: 20))
                    
                    Text("Buscar platillos o restaurantes")
                        .font(.system(size: 16))
                        .foregroundColor(primaryTextColor.opacity(0.6)) // Placeholder look
                    
                    Spacer()
                }
                .padding(16)
                .background(secondaryBackgroundColor)
                .cornerRadius(16)
                .matchedGeometryEffect(id: "searchBar", in: animation)
            }
            .buttonStyle(.plain)
            
            // Filter Button
            Button(action: {
                withAnimation { showFilters = true }
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(primaryColor)
                    .cornerRadius(16)
                    .shadow(color: primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .opacity(animateSearch ? 1 : 0)
        .offset(y: animateSearch ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateSearch)
    }
    
    private var heroPromo: some View {
        Button(action: {
            selectedDishId = "green-burger"
            showFullMenu = true
        }) {
            ZStack(alignment: .bottomLeading) {
                safeImage(url: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd", width: nil, height: 220, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .clear]), startPoint: .leading, endPoint: .trailing)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("EXCLUSIVO DE HOY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(primaryColor)
                        .tracking(1)
                    
                    Text("Sabor ")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white) +
                    Text("Premium")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(primaryColor) +
                    Text("\nen tu puerta.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Visual "Button" only
                    Text("Pedir Ahora")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(primaryColor)
                        .cornerRadius(20)
                        .padding(.top, 8)
                }
                .padding(24)
            }
            .contentShape(Rectangle()) // Ensure tap area
            .cornerRadius(24)
            .shadow(color: isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                // Pagination Dots
                HStack(spacing: 6) {
                    Capsule().fill(primaryColor).frame(width: 20, height: 6)
                    Circle().fill(Color.gray.opacity(0.5)).frame(width: 6, height: 6)
                    Circle().fill(Color.gray.opacity(0.5)).frame(width: 6, height: 6)
                }
                .padding(.bottom, 12)
                , alignment: .bottom
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Explorar por Categoría")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryTextColor)
                Spacer()
                Button("Ver todo") {
                    withAnimation {
                        showAllCategories = true
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(primaryColor)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(categoryItems.enumerated()), id: \.element.id) { index, item in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                if selectedCategory == item.name {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = item.name
                                }
                            }
                        }) {
                            VStack(spacing: 8) {
                                // Intento de carga directa desde bundle path (más robusto para prototipos)
                                if let path = Bundle.main.path(forResource: item.image, ofType: "png", inDirectory: "CategoryImages"),
                                   let uiImage = UIImage(contentsOfFile: path) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedCategory == item.name ? primaryColor : Color.clear, lineWidth: 3)
                                        )
                                        .scaleEffect(selectedCategory == item.name ? 1.1 : 1.0)
                                        .shadow(color: isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                } else if let uiImage = UIImage(named: item.image) {
                                    // Fallback al Asset Catalog normal
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedCategory == item.name ? primaryColor : Color.clear, lineWidth: 3)
                                        )
                                        .scaleEffect(selectedCategory == item.name ? 1.1 : 1.0)
                                        .shadow(color: isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                } else {
                                    // Fallback visual final
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            VStack(spacing: 2) {
                                                Image(systemName: "photo")
                                                Text("?")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        )
                                }
                                
                                Text(item.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedCategory == item.name ? primaryColor : primaryTextColor)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .scaleEffect(animateCategories ? 1 : 0.5)
                        .opacity(animateCategories ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05 + 0.3), value: animateCategories)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10) // Espacio para la animación de escala
            }
        }
    }
    
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recomendados para ti")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(Self.popularItems.enumerated()), id: \.element.id) { index, item in
                        Button(action: {
                            // Map to dummy dish IDs
                            if item.name.contains("Bowl") {
                                selectedDishId = "sushi-bowl"
                            } else if item.name.contains("Pizza") {
                                selectedDishId = "pizza-margarita"
                            } else {
                                selectedDishId = "green-burger"
                            }
                            showFullMenu = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                safeImage(url: item.imageUrl, width: 160, height: 160, contentMode: .fill)
                                    .cornerRadius(20)
                                
                                Text(item.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(primaryTextColor)
                                    .lineLimit(1)
                                
                                Text(String(format: "$%.2f", item.price))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(primaryColor)
                            }
                            .frame(width: 160)
                            .contentShape(Rectangle()) // Ensure tap area
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .scaleEffect(animateContent ? 1 : 0.5)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2 + Double(index) * 0.1), value: animateContent)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var featuredRestaurantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Restaurantes Destacados")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryTextColor)
                Spacer()
                Button("Ver todo") {
                    // Action
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(primaryColor)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 24) {
                ForEach(Array(Self.featuredRestaurants.enumerated()), id: \.element.id) { index, restaurant in
                    Button(action: {
                        // Navigate to restaurant details (Full Menu)
                        // Para restaurantes, abrimos el menú sin seleccionar un platillo específico automáticamente,
                        // a menos que queramos destacar el "best seller". Por ahora, solo abrir menú.
                        selectedDishId = nil 
                        showFullMenu = true
                    }) {
                        ZStack(alignment: .bottom) {
                            // Image Background
                            safeImage(url: restaurant.imageUrl, width: nil, height: 250, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .overlay(
                                    LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .clear]), startPoint: .bottom, endPoint: .center)
                                )
                            
                            // Info Overlay
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(restaurant.title)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 14))
                                        Text(String(format: "%.1f", restaurant.rating))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                }
                                
                                Text("\(restaurant.subtitle) • \(restaurant.priceLevel)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                        Text(restaurant.time)
                                    }
                                    HStack(spacing: 4) {
                                        Image(systemName: "bicycle")
                                        Text(restaurant.delivery)
                                    }
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(primaryColor)
                            }
                            .padding(20)
                        }
                        .cornerRadius(24)
                        .contentShape(Rectangle()) // Ensure tap area
                        .shadow(color: isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.4 + Double(index) * 0.1), value: animateContent)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Platillos en Tendencia")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Text("TIKTOK VIRAL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(primaryColor)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(Self.trendingItems.enumerated()), id: \.element.id) { index, item in
                        Button(action: {
                            // Play video or show details
                            // Map to dummy dish IDs
                            if item.name.contains("Bowl") {
                                selectedDishId = "sushi-bowl"
                            } else if item.name.contains("Tacos") {
                                selectedDishId = "tacos-pastor"
                            } else if item.name.contains("Pasta") {
                                selectedDishId = "pizza-margarita" // Closest match
                            } else {
                                selectedDishId = "green-burger"
                            }
                            showFullMenu = true
                        }) {
                            ZStack(alignment: .bottomLeading) {
                                safeImage(url: item.imageUrl, width: 220, height: 280, contentMode: .fill)
                                    .overlay(
                                        LinearGradient(gradient: Gradient(colors: [.black.opacity(0.7), .clear]), startPoint: .bottom, endPoint: .center)
                                    )
                                    .cornerRadius(20)
                                
                                // Play Button Center
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if let badge = item.badge {
                                        Text(badge)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(primaryColor)
                                            .cornerRadius(8)
                                            .padding(.bottom, 4)
                                    }
                                    
                                    Text(item.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                        
                                    Text(item.price)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(primaryColor)
                                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                }
                                .padding(16)
                            }
                            .frame(width: 220, height: 280)
                            .contentShape(Rectangle()) // Ensure tap area
                            .shadow(color: isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .scaleEffect(animateContent ? 1 : 0.8)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5 + Double(index) * 0.1), value: animateContent)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var activeOrderBar: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "scooter")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Tu pedido está en camino")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("LLEGA EN 15 MIN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Rastrear")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(primaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
            }
        }
        .padding(16)
        .background(primaryColor)
        .cornerRadius(24)
        .shadow(color: primaryColor.opacity(isDarkMode ? 0.2 : 0.4), radius: 10, x: 0, y: 5)
    }

    // MARK: - Helpers

    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
        }
    }

    private func safeImage(url: String, width: CGFloat? = nil, height: CGFloat? = nil, contentMode: ContentMode = .fill) -> some View {
        WebImage(url: URL(string: url))
            .resizable()
            .indicator(.activity)
            .transition(.fade(duration: 0.5))
            .aspectRatio(contentMode: contentMode)
            .frame(width: width, height: height)
            .clipped()
            .background(secondaryBackgroundColor)
    }

    private var restaurantUpdatesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Add Story Button (Optional)
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(secondaryBackgroundColor)
                            .frame(width: 68, height: 68)
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Text("Mis Favoritos")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.leading, 20)
                
                // Restaurant Circles
                ForEach(updates) { update in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedStory = update
                        }
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
                                // Ring
                                if update.hasUpdate {
                                    Circle()
                                        .stroke(
                                            AngularGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 244/255, green: 37/255, blue: 123/255), // Brand Pink
                                                    Color.orange
                                                ]),
                                                center: .center
                                            ),
                                            lineWidth: 2.5
                                        )
                                        .frame(width: 72, height: 72)
                                } else {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        .frame(width: 72, height: 72)
                                }
                                
                                // Image
                                if let url = URL(string: update.logo) {
                                    WebImage(url: url)
                                        .resizable()
                                        .scaledToFit() // Logos usually fit better
                                        .padding(12)   // Padding inside circle for logo
                                        .frame(width: 64, height: 64)
                                        .background(surfaceColor)
                                        .clipShape(Circle())
                                }
                            }
                            
                            Text(update.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .frame(width: 70)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 20)
        }
    }
}

// MARK: - FilterSheet
struct FilterSheet: View {
    var onClose: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var isDarkMode: Bool { colorScheme == .dark }
    
    private var backgroundColor: Color {
        isDarkMode ? Color(uiColor: .secondarySystemBackground) : Color.white
    }
    
    private var surfaceColor: Color {
        isDarkMode ? Color(red: 0.17, green: 0.17, blue: 0.18) : Color.white
    }
    
    private var chipBackgroundColor: Color {
        isDarkMode ? Color(uiColor: .tertiarySystemBackground) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    // Estado de expansión
    @State private var expandedSection: String? = nil
    
    // Estados de Sliders
    @State private var priceIndex: Double = 0
    @State private var timeIndex: Double = 0
    @State private var distanceIndex: Double = 0
    
    // Estados de Selección Múltiple
    @State private var selectedRatings: Set<Int> = []
    @State private var selectedFoodTypes: Set<String> = []
    @State private var selectedOffers: Set<String> = []
    
    // Arrays de valores
    private let priceValues: [Int] = [1, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]
    private let timeValues: [Int] = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 75, 90, 105, 120]
    private let distanceValues: [Int] = [1, 5, 10, 15, 20, 25, 30, 35, 40]
    
    private let foodTypes = ["Mexicana", "Italiana", "China", "Japonesa", "Vegana", "Vegetariana", "Hamburguesas", "Postres"]
    private let offerTypes = ["10% off", "20% off", "50% off", "2x1", "Envío Gratis", "Cupón"]
    
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
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: clearFilters) {
                            Text("Limpiar")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .padding(.top, 10)
                    .background(backgroundColor)
                    
                    // Content List
                    ScrollView {
                        VStack(spacing: 12) {
                            // Precio
                            filterSection(title: "Precio: \(getPriceString())", id: "Precio") {
                                VStack(spacing: 8) {
                                    Slider(value: $priceIndex, in: 0...Double(priceValues.count - 1), step: 1)
                                        .accentColor(.green)
                                    HStack {
                                        Text("$1").font(.caption).foregroundColor(.gray)
                                        Spacer()
                                        Text("$150").font(.caption).foregroundColor(.gray)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Tiempo
                            filterSection(title: "Tiempo: \(getTimeString())", id: "Tiempo") {
                                VStack(spacing: 8) {
                                    Slider(value: $timeIndex, in: 0...Double(timeValues.count - 1), step: 1)
                                        .accentColor(.green)
                                    HStack {
                                        Text("1 min").font(.caption).foregroundColor(.gray)
                                        Spacer()
                                        Text("120 min").font(.caption).foregroundColor(.gray)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Calificación
                            filterSection(title: "Calificación", id: "Calificación") {
                                HStack(spacing: 12) {
                                    ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                                        Button(action: { toggleRating(star) }) {
                                            HStack(spacing: 4) {
                                                Text("\(star)")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(selectedRatings.contains(star) ? .white : .primary)
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(selectedRatings.contains(star) ? .white : .orange)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedRatings.contains(star) ? Color.orange : chipBackgroundColor)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Tipo de comida
                            filterSection(title: "Tipo de comida", id: "Tipo de comida") {
                                FlowLayout(spacing: 10) {
                                    ForEach(foodTypes, id: \.self) { type in
                                        Button(action: { toggleFoodType(type) }) {
                                            Text(type)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedFoodTypes.contains(type) ? .white : .primary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedFoodTypes.contains(type) ? Color.orange : chipBackgroundColor)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Distancia
                            filterSection(title: "Distancia: \(getDistanceString())", id: "Distancia") {
                                VStack(spacing: 8) {
                                    Slider(value: $distanceIndex, in: 0...Double(distanceValues.count - 1), step: 1)
                                        .accentColor(.green)
                                    HStack {
                                        Text("1 km(-)").font(.caption).foregroundColor(.gray)
                                        Spacer()
                                        Text("40 km").font(.caption).foregroundColor(.gray)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            // Ofertas
                            filterSection(title: "Ofertas y descuentos", id: "Ofertas") {
                                FlowLayout(spacing: 10) {
                                    ForEach(offerTypes, id: \.self) { offer in
                                        Button(action: { toggleOffer(offer) }) {
                                            Text(offer)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedOffers.contains(offer) ? .white : .primary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedOffers.contains(offer) ? Color.orange : chipBackgroundColor)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                    
                    // Apply Button
                    Button(action: onClose) {
                        Text("Aplicar Filtros")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                            .shadow(color: isDarkMode ? Color.white.opacity(0.1) : Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding()
                    .background(backgroundColor)
                }
                .frame(height: geometry.size.height * 0.75)
                .background(backgroundColor)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .shadow(color: isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
            }
        }
        .ignoresSafeArea()
    }
    


    private func filterSection<Content: View>(title: String, id: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation {
                    if expandedSection == id {
                        expandedSection = nil
                    } else {
                        expandedSection = id
                    }
                }
            }) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(expandedSection == id ? 180 : 0))
                }
                .padding()
                .background(chipBackgroundColor.opacity(0.5))
            }
            
            if expandedSection == id {
                content()
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(surfaceColor)
        .cornerRadius(12)
        .shadow(color: isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helpers
    
    private func clearFilters() {
        withAnimation {
            priceIndex = 0
            timeIndex = 0
            distanceIndex = 0
            selectedRatings.removeAll()
            selectedFoodTypes.removeAll()
            selectedOffers.removeAll()
        }
    }
    
    private func toggleRating(_ rating: Int) {
        if selectedRatings.contains(rating) {
            selectedRatings.remove(rating)
        } else {
            selectedRatings.insert(rating)
        }
    }
    
    private func toggleFoodType(_ type: String) {
        if selectedFoodTypes.contains(type) {
            selectedFoodTypes.remove(type)
        } else {
            selectedFoodTypes.insert(type)
        }
    }
    
    private func toggleOffer(_ offer: String) {
        if selectedOffers.contains(offer) {
            selectedOffers.remove(offer)
        } else {
            selectedOffers.insert(offer)
        }
    }
    
    private func getPriceString() -> String {
        let val = priceValues[Int(priceIndex)]
        return "$\(val)"
    }
    
    private func getTimeString() -> String {
        let val = timeValues[Int(timeIndex)]
        return "\(val) min"
    }
    
    private func getDistanceString() -> String {
        let val = distanceValues[Int(distanceIndex)]
        return val == 1 ? "1 km(-)" : "\(val) km"
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

// MARK: - View Offset Key
struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
