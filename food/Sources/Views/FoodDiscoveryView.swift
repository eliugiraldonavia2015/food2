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
        CategoryItem(name: "Burgers", icon: "🍔", color: .white),
        CategoryItem(name: "Pizza", icon: "🍕", color: .white),
        CategoryItem(name: "Saludable", icon: "🥗", color: .white),
        CategoryItem(name: "Carnes", icon: "🥩", color: .white),
        CategoryItem(name: "Drinks", icon: "🥤", color: .white),
        CategoryItem(name: "Sushi", icon: "🍣", color: .white)
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
        PopularItem(name: "Plato Especial 1", restaurant: "Restaurante 1", price: 22.38, time: "38 min", rating: 4.9, discount: 32, imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c"),
        PopularItem(name: "Plato Especial 2", restaurant: "Restaurante 2", price: 20.10, time: "35 min", rating: 4.6, discount: 20, imageUrl: "https://images.unsplash.com/photo-1550547660-d9450f859349"),
        PopularItem(name: "Plato Especial 3", restaurant: "Restaurante 3", price: 26.57, time: "38 min", rating: 4.7, discount: 28, imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd"),
        PopularItem(name: "Plato Especial 4", restaurant: "Restaurante 4", price: 18.25, time: "42 min", rating: 4.5, discount: 15, imageUrl: "https://images.unsplash.com/photo-1473093226795-d6b06c273fd7"),
        PopularItem(name: "Plato Especial 5", restaurant: "Restaurante 5", price: 27.55, time: "33 min", rating: 4.8, discount: 37, imageUrl: "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe"),
        PopularItem(name: "Plato Especial 6", restaurant: "Restaurante 6", price: 16.70, time: "31 min", rating: 4.4, discount: 12, imageUrl: "https://images.unsplash.com/photo-1601924582971-b0d4b3a2c0ba"),
        PopularItem(name: "Plato Especial 7", restaurant: "Restaurante 7", price: 24.90, time: "47 min", rating: 4.6, discount: 25, imageUrl: "https://images.unsplash.com/photo-1478145046317-39f10e56b5e9")
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
                        promoCarousel
                        categoryIconsRow
                        ForEach(style1SectionsData) { section in
                            sectionStyle1(title: section.title, items: section.items)
                        }
                        dealsSection(title: "Descuentazos")
                        dealsSection(title: "Más ofertas")
                        popularSection
                        feedSectionStyle4
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
            safeImage(url: "https://images.unsplash.com/photo-1504674900247-0877df9cc836", height: 180, contentMode: .fill)
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
                                .fill(Color.white.opacity(0.14))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                )
                            Text(item.icon)
                                .font(.system(size: 30))
                                .foregroundColor(.white)
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

    struct RestaurantItem: Identifiable {
        let id = UUID()
        let title: String
        let time: String
        let fee: String
        let distance: String
        let rating: Double
        let imageUrl: String
        let promo: String?
    }

    struct SectionData: Identifiable {
        let id = UUID()
        let title: String
        let items: [RestaurantItem]
    }

    private var style1SectionsData: [SectionData] {
        [
            SectionData(title: "Pollo delicioso", items: [
                RestaurantItem(title: "KFC", time: "48 min", fee: "$0.90", distance: "2.9 km", rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1606755962773-d32477b6a225", promo: "$4 gratis en créditos"),
                RestaurantItem(title: "Burger King", time: "48 min", fee: "$1.50", distance: "5 km", rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe", promo: "$4 gratis en créditos"),
                RestaurantItem(title: "Pío Pío", time: "36 min", fee: "$1.10", distance: "3.5 km", rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1604908177221-b6154a5340ff", promo: "$2 de envío"),
                RestaurantItem(title: "Chicken Bros", time: "40 min", fee: "$0.80", distance: "2.2 km", rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1553163147-622ab57be1c7", promo: nil),
                RestaurantItem(title: "Crispy House", time: "49 min", fee: "$1.00", distance: "4.0 km", rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1606756793446-1e2c9ef7bd8d", promo: "$4 gratis en créditos"),
                RestaurantItem(title: "Wings & Co", time: "52 min", fee: "$1.20", distance: "5.6 km", rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1562967916-eb82221dfb36", promo: nil),
                RestaurantItem(title: "Pollo Express", time: "35 min", fee: "$0.70", distance: "2.1 km", rating: 4.2, imageUrl: "https://images.unsplash.com/photo-1606755962773-d32477b6a225", promo: nil)
            ]),
            SectionData(title: "Antojo de hamburguesa", items: [
                RestaurantItem(title: "El Corral", time: "62 min", fee: "$1.50", distance: "5 km", rating: 4.8, imageUrl: "https://images.unsplash.com/photo-1550547660-d9450f859349", promo: "$4 gratis en créditos"),
                RestaurantItem(title: "Roger's Smash", time: "45 min", fee: "$0.80", distance: "3.1 km", rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1550547660-1b6b1fcef2b8", promo: "$4 gratis en créditos"),
                RestaurantItem(title: "Smash House", time: "43 min", fee: "$0.90", distance: "2.8 km", rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1550547660-1b6b1fcef2b8", promo: nil),
                RestaurantItem(title: "Burger Factory", time: "50 min", fee: "$1.10", distance: "4.5 km", rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1550317138-10000687a72b", promo: nil),
                RestaurantItem(title: "Double Smash", time: "48 min", fee: "$1.30", distance: "4.9 km", rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1550547660-d9450f859349", promo: "$2 de envío"),
                RestaurantItem(title: "Cheese Lovers", time: "41 min", fee: "$0.70", distance: "3.0 km", rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1550547660-1b6b1fcef2b8", promo: nil),
                RestaurantItem(title: "The Burger Co.", time: "47 min", fee: "$1.00", distance: "3.7 km", rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1550547660-d9450f859349", promo: nil)
            ]),
            SectionData(title: "Pizza top", items: [
                RestaurantItem(title: "Pizzeria Roma", time: "40 min", fee: "$0.70", distance: "3.4 km", rating: 4.7, imageUrl: "https://images.unsplash.com/photo-1548365328-9c4b0fd08475", promo: "$3 de envío"),
                RestaurantItem(title: "Napoli", time: "44 min", fee: "$0.90", distance: "4.0 km", rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1548365328-9c4b0fd08475", promo: nil),
                RestaurantItem(title: "Pizza Lab", time: "38 min", fee: "$0.80", distance: "2.5 km", rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1548365328-9c4b0fd08475", promo: nil),
                RestaurantItem(title: "Mozza", time: "55 min", fee: "$1.20", distance: "6.1 km", rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1548365328-9c4b0fd08475", promo: "$2 de envío"),
                RestaurantItem(title: "Al Taglio", time: "47 min", fee: "$1.10", distance: "4.3 km", rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1548365328-9c4b0fd08475", promo: nil),
                RestaurantItem(title: "Rustica", time: "52 min", fee: "$1.00", distance: "5.0 km", rating: 4.2, imageUrl: "https://images.unsplash.com/photo-1548365328-9c4b0fd08475", promo: nil),
                RestaurantItem(title: "Di Parma", time: "36 min", fee: "$0.70", distance: "2.0 km", rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1548365328-9c4b0fd08475", promo: nil)
            ]),
            SectionData(title: "Sushi favorito", items: [
                RestaurantItem(title: "Kobe Sushi & Rolls", time: "53 min", fee: "$1.10", distance: "4.6 km", rating: 4.9, imageUrl: "https://images.unsplash.com/photo-1553621042-f6e147245754", promo: "$4 gratis en créditos"),
                RestaurantItem(title: "Sushi House", time: "49 min", fee: "$1.00", distance: "4.0 km", rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1553621042-f6e147245754", promo: nil),
                RestaurantItem(title: "Tokyo Bites", time: "45 min", fee: "$0.90", distance: "3.2 km", rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1553621042-f6e147245754", promo: nil),
                RestaurantItem(title: "Sashimi Co.", time: "57 min", fee: "$1.20", distance: "5.7 km", rating: 4.4, imageUrl: "https://images.unsplash.com/photo-1553621042-f6e147245754", promo: "$2 de envío"),
                RestaurantItem(title: "Nigiri Lab", time: "50 min", fee: "$1.10", distance: "4.3 km", rating: 4.3, imageUrl: "https://images.unsplash.com/photo-1553621042-f6e147245754", promo: nil),
                RestaurantItem(title: "Uramaki Spot", time: "43 min", fee: "$0.80", distance: "3.0 km", rating: 4.5, imageUrl: "https://images.unsplash.com/photo-1553621042-f6e147245754", promo: nil),
                RestaurantItem(title: "Zen Sushi", time: "41 min", fee: "$0.70", distance: "2.6 km", rating: 4.6, imageUrl: "https://images.unsplash.com/photo-1553621042-f6e147245754", promo: nil)
            ])
        ]
    }

    private func sectionStyle1(title: String, items: [RestaurantItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        restaurantCardStyle1(item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func restaurantCardStyle1(_ item: RestaurantItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                safeImage(url: item.imageUrl, width: 240, height: 120, contentMode: .fill)
                if let promo = item.promo {
                    Text(promo)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .cornerRadius(6)
                        .padding(8)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Text(item.time)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("•")
                        .foregroundColor(.gray)
                    Text(item.fee)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("•")
                        .foregroundColor(.gray)
                    Text(item.distance)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Text(String(format: "%.1f", item.rating))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.12))
        }
        .frame(width: 240)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }

    struct DealItem: Identifiable {
        let id = UUID()
        let price: String
        let discountText: String
        let oldPrice: String
        let subtitle: String
        let merchant: String
        let time: String
        let imageUrl: String
    }

    private var dealsData: [DealItem] {
        [
            DealItem(price: "$6,55", discountText: "-61%", oldPrice: "$17,00", subtitle: "15 Bocados Especiales..", merchant: "Kobe Sushi & Rolls", time: "53 min", imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c"),
            DealItem(price: "$5,00", discountText: "-53%", oldPrice: "$10,80", subtitle: "Todo por $5", merchant: "Burger King", time: "48 min", imageUrl: "https://images.unsplash.com/photo-1550547660-d9450f859349"),
            DealItem(price: "$5,20", discountText: "-41%", oldPrice: "$8,80", subtitle: "BBQ Pack", merchant: "Carl's Jr.", time: "37 min", imageUrl: "https://images.unsplash.com/photo-1606755962773-d32477b6a225"),
            DealItem(price: "$7,40", discountText: "-35%", oldPrice: "$11,40", subtitle: "Combo Nuggets", merchant: "KFC", time: "44 min", imageUrl: "https://images.unsplash.com/photo-1606756793446-1e2c9ef7bd8d"),
            DealItem(price: "$4,90", discountText: "-45%", oldPrice: "$8,90", subtitle: "Wrap + Papas", merchant: "Shawarma Fast", time: "39 min", imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c"),
            DealItem(price: "$3,80", discountText: "-50%", oldPrice: "$7,60", subtitle: "Sundae 2x1", merchant: "Burger King", time: "48 min", imageUrl: "https://images.unsplash.com/photo-1550317138-10000687a72b"),
            DealItem(price: "$6,10", discountText: "-40%", oldPrice: "$10,20", subtitle: "Sushi Box", merchant: "Kobe", time: "53 min", imageUrl: "https://images.unsplash.com/photo-1553621042-f6e147245754")
        ]
    }

    private func dealsSection(title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(dealsData) { deal in
                        dealCard(deal)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func dealCard(_ deal: DealItem) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                safeImage(url: deal.imageUrl, height: 120, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                Text(deal.discountText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(4)
                    .padding(8)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(deal.price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(deal.oldPrice)
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .strikethrough()
                }
                Text(deal.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(deal.merchant)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Text("•")
                        .foregroundColor(.gray)
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                    Text(deal.time)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 180)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }

    struct FeedItem: Identifiable {
        let id = UUID()
        let title: String
        let imageUrl: String
        let meta: String
        let rating: String
        let promo: String?
    }

    private var feedItems: [FeedItem] {
        [
            FeedItem(title: "Fast Shawarma", imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c", meta: "53 min  •  $1.10  •  4.6 km", rating: "★ 4.9 (35)", promo: "$4 gratis en créditos"),
            FeedItem(title: "Kobe Sushi & Rolls", imageUrl: "https://images.unsplash.com/photo-1527455272121-3e1e7a42e9d1", meta: "53 min  •  $1.10  •  4.6 km", rating: "★ 4.8", promo: nil),
            FeedItem(title: "Pizzeria Roma", imageUrl: "https://images.unsplash.com/photo-1548365328-9c4b0fd08475", meta: "40 min  •  $0.70  •  3.4 km", rating: "★ 4.7", promo: "$3 de envío"),
            FeedItem(title: "Smash House", imageUrl: "https://images.unsplash.com/photo-1550547660-d9450f859349", meta: "45 min  •  $0.80  •  3.1 km", rating: "★ 4.6", promo: "$4 gratis en créditos"),
            FeedItem(title: "Tacos Express", imageUrl: "https://images.unsplash.com/photo-1601924582971-b0d4b3a2c0ba", meta: "35 min  •  $0.60  •  2.0 km", rating: "★ 4.5", promo: nil),
            FeedItem(title: "Thai Garden", imageUrl: "https://images.unsplash.com/photo-1473093226795-d6b06c273fd7", meta: "50 min  •  $1.20  •  5.4 km", rating: "★ 4.8", promo: "$2 de envío")
        ]
    }

    private var feedSectionStyle4: some View {
        VStack(spacing: 16) {
            ForEach(feedItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    safeImage(url: item.imageUrl, height: 160, contentMode: .fill)
                        .cornerRadius(16)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 20, weight: .bold))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.white)
                        if let promo = item.promo {
                            Text(promo)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.yellow)
                                .cornerRadius(6)
                        }
                        Text(item.meta)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Text(item.rating)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }
            Spacer().frame(height: 20)
        }
    }

    private var promoCarousel: some View {
        TabView {
            promoSlide(imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591")
            promoSlide(imageUrl: "https://images.unsplash.com/photo-1550547660-d9450f859349")
            promoSlide(imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c")
        }
        .frame(height: 220)
        .tabViewStyle(PageTabViewStyle())
        .padding(.horizontal)
    }

    private func promoSlide(imageUrl: String) -> some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                safeImage(url: imageUrl, width: 180, height: 220, contentMode: .fill)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Burgers con")
                        .font(.system(size: 18))
                        .foregroundColor(.brown)
                    Text("40% OFF")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.brown)
                    Text("30% FULL")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.brown)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.96, green: 0.93, blue: 0.88))
            }
        }
        .cornerRadius(24)
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
                safeImage(url: item.imageUrl, width: 200, height: 120, contentMode: .fill)
                
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
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.white)
                
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
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.12))
        }
        .frame(width: 200)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - FilterSheet
struct FilterSheet: View {
    var onClose: () -> Void
    
    // Estado de expansión (Solo uno a la vez)
    @State private var expandedSection: String? = nil
    
    // Estados de Sliders (Índices)
    @State private var priceIndex: Double = 0
    @State private var timeIndex: Double = 0
    @State private var distanceIndex: Double = 0
    
    // Estados de Selección Múltiple
    @State private var selectedRatings: Set<Int> = []
    @State private var selectedFoodTypes: Set<String> = []
    @State private var selectedOffers: Set<String> = []
    
    // Arrays de valores para los sliders (Mapeo no lineal)
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
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: clearFilters) {
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
                                                    .foregroundColor(.white)
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(selectedRatings.contains(star) ? .white : .yellow)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedRatings.contains(star) ? Color.orange : Color.white.opacity(0.06))
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
                                    ForEach(foodTypes, id: \.self) { type in
                                        Button(action: { toggleFoodType(type) }) {
                                            Text(type)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedFoodTypes.contains(type) ? Color.orange : Color.white.opacity(0.06))
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
                            
                            // Ofertas y descuentos
                            filterSection(title: "Ofertas y descuentos", id: "Ofertas") {
                                FlowLayout(spacing: 10) {
                                    ForEach(offerTypes, id: \.self) { offer in
                                        Button(action: { toggleOffer(offer) }) {
                                            Text(offer)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedOffers.contains(offer) ? Color.orange : Color.white.opacity(0.06))
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
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(expandedSection == id ? 180 : 0))
                }
                .padding()
                .background(Color.white.opacity(0.06))
            }
            
            if expandedSection == id {
                content()
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
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



// Global safe image loader with graceful fallback
func safeImage(url: String, width: CGFloat? = nil, height: CGFloat? = nil, contentMode: SwiftUI.ContentMode = .fill) -> some View {
    let finalURL = URL(string: url + (url.contains("unsplash.com") ? "?auto=format&fit=crop&w=800&q=80" : ""))
    return WebImage(url: finalURL)
        .resizable()
        .placeholder {
            ZStack {
                LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.3))
        .aspectRatio(contentMode: contentMode)
        .frame(width: width, height: height)
        .background(Color.white.opacity(0.06))
        .clipped()
}
