import SwiftUI
import SDWebImageSwiftUI
import UIKit
import Combine
import Foundation

class FullMenuViewModel: ObservableObject {
    @Published var dishes: [FullMenuView.Dish] = []
    @Published var branches: [FullMenuView.Branch] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    
    private let restaurantId: String
    
    init(restaurantId: String) {
        self.restaurantId = restaurantId
        loadData()
    }
    
    func loadData() {
        // SCALABILITY NOTE:
        // This function is designed to fetch data from a database (e.g., Firebase, REST API).
        // Currently simulating data, but 'restaurantId' would be used to query the specific restaurant's menu.
        // Example:
        // Task {
        //     let menu = await Database.fetchMenu(for: restaurantId)
        //     await MainActor.run {
        //         self.dishes = menu.dishes
        //         self.branches = menu.branches
        //         self.updateCategories()
        //     }
        // }
        
        self.dishes = [
            .init(
                id: "green-burger",
                category: "Pizzas",
                title: "Clásica Green Burger",
                subtitle: "Carne premium, lechuga fresca, jitomate y nuestra salsa especial de la casa.",
                price: 12.99,
                imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
                isPopular: true
            ),
            .init(
                id: "avocado-toast",
                category: "Desayunos",
                title: "Avocado Toast",
                subtitle: "Pan de masa madre, aguacate hass, huevo pochado y semillas de girasol.",
                price: 8.50,
                imageUrl: "https://images.unsplash.com/photo-1588137372308-15f75323ca8d",
                isPopular: true
            ),
            .init(
                id: "sushi-bowl",
                category: "Comida Asiática",
                title: "Salmon Poke Bowl",
                subtitle: "Salmón fresco, arroz de sushi, edamames, aguacate y salsa ponzu.",
                price: 14.20,
                imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c",
                isPopular: true
            ),
            .init(
                id: "tacos-pastor",
                category: "Mexicana",
                title: "Orden de Tacos al Pastor",
                subtitle: "5 tacos con todo: piña, cilantro, cebolla y salsa de la casa.",
                price: 6.00,
                imageUrl: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b",
                isPopular: true
            ),
            .init(
                id: "pizza-margarita",
                category: "Pizzas",
                title: "Pizza Margarita",
                subtitle: "Mozzarella fresca, albahaca y aceite de oliva extra virgen.",
                price: 11.25,
                imageUrl: "https://images.unsplash.com/photo-1601924582971-b0d4b3a2c0ba",
                isPopular: false
            ),
            .init(
                id: "coca",
                category: "Bebidas",
                title: "Coca-Cola",
                subtitle: "355 ml bien fría.",
                price: 1.50,
                imageUrl: "https://images.unsplash.com/photo-1612528443702-f6741f70a049",
                isPopular: false
            ),
            .init(
                id: "limonada",
                category: "Bebidas",
                title: "Limonada",
                subtitle: "Natural, con hielo y un toque de menta.",
                price: 2.00,
                imageUrl: "https://images.unsplash.com/photo-1528825871115-3581a5387919",
                isPopular: false
            ),
            .init(
                id: "cheesecake",
                category: "Postres",
                title: "Cheesecake",
                subtitle: "Clásico, cremoso y con base de galleta.",
                price: 4.50,
                imageUrl: "https://images.unsplash.com/photo-1542826438-bd32f43d626f",
                isPopular: false
            )
        ]
        
        self.branches = [
            .init(name: "CDMX, México", address: "Av. Horacio 123, Polanco", distanceKm: 2.3),
            .init(name: "Condesa", address: "Tamaulipas 45, Hipódromo Condesa", distanceKm: 2.5),
            .init(name: "Roma Norte", address: "Colima 234, Roma Norte", distanceKm: 3.1),
            .init(name: "Santa Fe", address: "Vasco de Quiroga 3800, Santa Fe", distanceKm: 8.4),
            .init(name: "Coyoacán", address: "Calle Cuauhtémoc 12, Del Carmen", distanceKm: 11.2)
        ]
        
        let cats = Array(Set(self.dishes.map { $0.category })).sorted()
        self.categories = ["Todo"] + cats
    }
}

struct FullMenuView: View {
    let restaurantId: String
    let restaurantName: String
    let coverUrl: String
    let avatarUrl: String
    let location: String
    let branchName: String?
    let distanceKm: Double?
    let isEditing: Bool
    
    @StateObject private var viewModel: FullMenuViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var activeTab: String = "Todo"
    @State private var showBranchSheet = false
    @State private var showDishSheet = false
    @State private var showDishShare = false
    @State private var selectedBranchName: String = ""
    @State private var pendingBranchName: String = ""
    @State private var cart: [String: Int] = [:]
    @State private var selectedDish: Dish? = nil
    @State private var dishQuantity: Int = 1
    @State private var sideOptionQuantities: [String: Int] = [:]
    @State private var drinkOptionQuantities: [String: Int] = [:]
    @State private var showDishMiniHeader: Bool = false
    @State private var dishSheetContentOffsetY: CGFloat = 0
    @State private var dishSheetScrollToTopToken: Int = 0
    @State private var menuContentOffsetY: CGFloat = 0
    @State private var showMenuMiniHeader: Bool = false
    @State private var showCartScreen: Bool = false
    
    // Callback para cerrar todo el flujo de navegación hasta la raíz (o vista padre)
    var onDismissToRoot: (() -> Void)?

    init(
        restaurantId: String,
        restaurantName: String,
        coverUrl: String,
        avatarUrl: String,
        location: String,
        branchName: String?,
        distanceKm: Double?,
        isEditing: Bool = false,
        onDismissToRoot: (() -> Void)? = nil
    ) {
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.coverUrl = coverUrl
        self.avatarUrl = avatarUrl
        self.location = location
        self.branchName = branchName
        self.distanceKm = distanceKm
        self.isEditing = isEditing
        self.onDismissToRoot = onDismissToRoot
        self._viewModel = StateObject(wrappedValue: FullMenuViewModel(restaurantId: restaurantId))
    }
    
    struct Branch: Identifiable {
        let id = UUID()
        let name: String
        let address: String
        let distanceKm: Double
    }
    
    struct Dish: Identifiable {
        let id: String
        let category: String
        let title: String
        let subtitle: String
        let price: Double
        let imageUrl: String
        let isPopular: Bool
    }

    private struct DishOption: Identifiable {
        let id: String
        let title: String
        let price: Double
    }

    private struct DishSheetScrollOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    private struct TrackableScrollView<Content: View>: UIViewRepresentable {
        @Binding var contentOffsetY: CGFloat
        let scrollToTopToken: Int
        let showsIndicators: Bool
        let content: Content

        init(
            contentOffsetY: Binding<CGFloat>,
            scrollToTopToken: Int,
            showsIndicators: Bool = false,
            @ViewBuilder content: () -> Content
        ) {
            _contentOffsetY = contentOffsetY
            self.scrollToTopToken = scrollToTopToken
            self.showsIndicators = showsIndicators
            self.content = content()
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        func makeUIView(context: Context) -> UIScrollView {
            let scrollView = UIScrollView()
            scrollView.delegate = context.coordinator
            scrollView.showsVerticalScrollIndicator = showsIndicators
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.alwaysBounceVertical = true
            scrollView.alwaysBounceHorizontal = false
            scrollView.isDirectionalLockEnabled = true
            scrollView.contentInsetAdjustmentBehavior = .never

            let hostingController = UIHostingController(rootView: content)
            hostingController.view.backgroundColor = .clear
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            context.coordinator.hostingController = hostingController

            scrollView.addSubview(hostingController.view)
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
            ])

            return scrollView
        }

        func updateUIView(_ uiView: UIScrollView, context: Context) {
            context.coordinator.parent = self
            context.coordinator.hostingController?.rootView = content
            uiView.showsVerticalScrollIndicator = showsIndicators

            if context.coordinator.lastScrollToTopToken != scrollToTopToken {
                context.coordinator.lastScrollToTopToken = scrollToTopToken
                uiView.setContentOffset(.zero, animated: false)
                DispatchQueue.main.async {
                    contentOffsetY = 0
                }
            }
        }

        final class Coordinator: NSObject, UIScrollViewDelegate {
            var parent: TrackableScrollView
            var hostingController: UIHostingController<Content>?
            var lastScrollToTopToken: Int = 0

            init(parent: TrackableScrollView) {
                self.parent = parent
            }

            func scrollViewDidScroll(_ scrollView: UIScrollView) {
                parent.contentOffsetY = scrollView.contentOffset.y
            }
        }
    }

    private var recommendedSides: [DishOption] {
        [
            .init(id: "fries", title: "Papas Fritas", price: 2.5),
            .init(id: "onion-rings", title: "Aros de Cebolla", price: 3),
            .init(id: "caesar-salad", title: "Ensalada César", price: 2)
        ]
    }

    private var recommendedDrinks: [DishOption] {
        [
            .init(id: "coke", title: "Coca-Cola", price: 1.5),
            .init(id: "sparkling", title: "Agua mineral", price: 1.25),
            .init(id: "lemonade", title: "Limonada", price: 2)
        ]
    }
    
    // MARK: - Computed Data
    private var hardcodedBranches: [Branch] { viewModel.branches }
    private var hardcodedDishes: [Dish] { viewModel.dishes }
    
    private var categories: [String] {
        viewModel.categories
    }
    
    private var nearestBranchId: UUID? {
        hardcodedBranches.min(by: { $0.distanceKm < $1.distanceKm })?.id
    }
    
    private var displayedDishes: [Dish] {
        if activeTab == "Todo" { return hardcodedDishes }
        return hardcodedDishes.filter { $0.category == activeTab }
    }
    
    private var cartCount: Int {
        cart.values.reduce(0, +)
    }
    
    private var cartTotal: Double {
        var total: Double = 0
        for dish in hardcodedDishes {
            let qty = cart[dish.id] ?? 0
            total += Double(qty) * dish.price
        }
        return total
    }

    private var currentBranchName: String {
        selectedBranchName.isEmpty ? (branchName ?? (location.isEmpty ? "CDMX, México" : location)) : selectedBranchName
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            TrackableScrollView(contentOffsetY: $menuContentOffsetY, scrollToTopToken: 0, showsIndicators: false) {
                VStack(spacing: 14) {
                    heroSection
                    
                    // Optimized: Using Struct
                    FullMenuBranchCard(
                        branchName: currentBranchName,
                        distanceKm: distanceKm,
                        onTap: { openBranchSheet() }
                    )
                    
                    // Optimized: Using Struct
                    FullMenuCategoryTabs(
                        categories: categories,
                        activeTab: $activeTab
                    )
                    
                    menuList
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 16)
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) {
                topBar
            }
        }
        .safeAreaInset(edge: .bottom) {
            checkoutBar
        }
        .tint(.fuchsia)
        .onChange(of: menuContentOffsetY) { _, newValue in
            let shouldShow = newValue > 168
            if shouldShow != showMenuMiniHeader {
                withAnimation(.easeInOut(duration: 0.16)) {
                    showMenuMiniHeader = shouldShow
                }
            }
        }
        .onAppear {
            selectedBranchName = branchName ?? location
            pendingBranchName = selectedBranchName.isEmpty ? (branchName ?? location) : selectedBranchName
            if cart.isEmpty {
                cart["green-burger"] = 1
            }
            showMenuMiniHeader = false
        }
        .overlay {
            ZStack {
                branchSheetOverlay
                dishSheetOverlay
            }
        }
        .fullScreenCover(isPresented: $showCartScreen) {
            CartScreenView(
                restaurantName: restaurantName,
                items: hardcodedDishes.map { .init(id: $0.id, title: $0.title, subtitle: $0.subtitle, price: $0.price, imageUrl: $0.imageUrl) },
                quantities: $cart,
                onOrderCompleted: {
                    cart.removeAll()
                    // Si existe el callback para ir a raíz, lo usamos. Si no, cerramos el carrito.
                    if let onDismissToRoot = onDismissToRoot {
                        onDismissToRoot()
                    } else {
                        showCartScreen = false
                    }
                }
            )
        }
    }

    private var heroSection: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 12) {
                identityRow
                    .zIndex(3)
                infoRow
                    .zIndex(2)
            }
            .padding(.top, -140)
        }
    }

    private var header: some View {
        let stretch = max(0, -menuContentOffsetY)
        return GeometryReader { geo in
            coverImage
                .frame(width: geo.size.width, height: 250 + stretch)
                .clipped()
                .overlay(headerGradient)
                .offset(y: -stretch)
        }
        .frame(height: 250)
        .padding(.horizontal, -16) // Cancelar padding del padre
    }

    private var identityRow: some View {
        HStack(spacing: 14) {
            avatarImage
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurantName)
                    .foregroundColor(.white)
                    .font(.system(size: 30, weight: .bold))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 13, weight: .semibold))
                    Text(location.isEmpty ? "CDMX, México" : location)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .padding(.leading, 6)

            Spacer()
        }
        .padding(.leading, 18)
    }

    private var infoRow: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white)
            .frame(height: 86)
            .shadow(color: Color.black.opacity(0.10), radius: 14, x: 0, y: 8)
            .overlay(
                HStack(spacing: 0) {
                    metricCard(title: "Tiempo", value: "25-35 min", system: "clock", tint: .fuchsia)
                        .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 1, height: 42)
                    
                    metricCard(title: "Envío", value: "$2.99", system: "shippingbox.fill", tint: .green)
                        .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 1, height: 42)
                    
                    metricCard(title: "Rating", value: "4.8", system: "star.fill", tint: .yellow)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
            )
            .padding(.horizontal, 8)
    }

    private func metricCard(title: String, value: String, system: String, tint: Color) -> some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: system)
                    .foregroundColor(tint)
                    .font(.system(size: 13, weight: .bold))
                Text(title.uppercased())
                    .foregroundColor(.gray)
                    .font(.system(size: 11, weight: .bold))
            }
            Text(value)
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .bold))
        }
    }
    
    private var menuList: some View {
        VStack(alignment: .leading, spacing: 14) {
            if activeTab == "Todo" {
                sectionHeader("Populares")
                VStack(spacing: 12) {
                    ForEach(displayedDishes.filter { $0.isPopular }) { dish in
                        FullMenuDishRow(
                            dish: dish,
                            quantity: cart[dish.id] ?? 0,
                            onTap: { openDishSheet(dish) },
                            onAdd: { addToCart(dish) },
                            onRemove: { removeFromCart(dish) }
                        )
                    }
                }
                
                ForEach(categories.filter { $0 != "Todo" }, id: \.self) { cat in
                    let items = hardcodedDishes.filter { $0.category == cat && !$0.isPopular }
                    if !items.isEmpty {
                        sectionHeader(cat)
                        VStack(spacing: 12) {
                            ForEach(items) { dish in
                                FullMenuDishRow(
                                    dish: dish,
                                    quantity: cart[dish.id] ?? 0,
                                    onTap: { openDishSheet(dish) },
                                    onAdd: { addToCart(dish) },
                                    onRemove: { removeFromCart(dish) }
                                )
                            }
                        }
                    }
                }
            } else {
                sectionHeader(activeTab)
                VStack(spacing: 12) {
                    ForEach(displayedDishes) { dish in
                        FullMenuDishRow(
                            dish: dish,
                            quantity: cart[dish.id] ?? 0,
                            onTap: { openDishSheet(dish) },
                            onAdd: { addToCart(dish) },
                            onRemove: { removeFromCart(dish) }
                        )
                    }
                }
            }
        }
        .padding(.top, 4)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .foregroundColor(.black)
            .font(.system(size: 22, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
            .padding(.bottom, 2)
    }
    
    private var checkoutBar: some View {
        Button(action: { showCartScreen = true }) {
            Text("Ir al Checkout • \(priceText(cartTotal))")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(cartTotal <= 0)
        .opacity(cartTotal <= 0 ? 0.6 : 1)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private var topBar: some View {
        Group {
            if showMenuMiniHeader {
                compactTopBar
            } else {
                expandedTopBar
            }
        }
    }

    private var expandedTopBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Circle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 38, height: 38)
                    .overlay(Image(systemName: "chevron.left").foregroundColor(.white).font(.system(size: 14, weight: .bold)))
            }
            Spacer()
            Button(action: { showCartScreen = true }) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 38, height: 38)
                        .overlay(Image(systemName: "cart.fill").foregroundColor(.white).font(.system(size: 14, weight: .bold)))
                    if cartCount > 0 {
                        Circle()
                            .fill(Color.fuchsia)
                            .frame(width: 18, height: 18)
                            .overlay(Text("\(cartCount)").foregroundColor(.white).font(.caption2.bold()))
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var compactTopBar: some View {
        HStack(spacing: 10) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 34, height: 34)
                .background(Color.gray.opacity(0.12))
                .clipShape(Circle())
            }

            Text(restaurantName)
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)

            Spacer()

            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.black.opacity(0.75))
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Circle())
            }

            Button(action: { showCartScreen = true }) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 34, height: 34)
                        .overlay(Image(systemName: "cart.fill").foregroundColor(.black.opacity(0.75)).font(.system(size: 14, weight: .bold)))
                    if cartCount > 0 {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 18, height: 18)
                            .overlay(Text("\(cartCount)").foregroundColor(.white).font(.caption2.bold()))
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(Rectangle().fill(Color.gray.opacity(0.12)).frame(height: 1), alignment: .bottom)
    }
    
    private var branchSheetOverlay: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(showBranchSheet ? 0.35 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if showBranchSheet { closeBranchSheet() }
                    }
                
                VStack(spacing: 14) {
                    Capsule()
                        .fill(Color.gray.opacity(0.35))
                        .frame(width: 44, height: 5)
                        .padding(.top, 8)
                    
                    Text("Selecciona una sucursal")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(hardcodedBranches) { branch in
                                branchRow(branch)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 2)
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.42)
                    
                    Button(action: {
                        selectedBranchName = pendingBranchName.isEmpty ? currentBranchName : pendingBranchName
                        closeBranchSheet()
                    }) {
                        Text("Confirmar Selección")
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.fuchsia)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                    
                    Spacer(minLength: 0)
                        .frame(height: geo.safeAreaInsets.bottom)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(FullMenuRoundedCorners(radius: 28, corners: [.topLeft, .topRight]))
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                .offset(y: showBranchSheet ? 0 : (geo.size.height + geo.safeAreaInsets.bottom + 40))
                .ignoresSafeArea(edges: .bottom)
            }
            .allowsHitTesting(showBranchSheet)
            .animation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2), value: showBranchSheet)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }

    private var dishSheetOverlay: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(showDishSheet ? 0.35 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if showDishShare {
                            withAnimation(.easeOut(duration: 0.25)) { showDishShare = false }
                        } else if showDishSheet {
                            closeDishSheet()
                        }
                    }

                dishSheetContent(in: geo)
                    .offset(y: showDishSheet ? 0 : (geo.size.height + geo.safeAreaInsets.bottom + 40))
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(!showDishShare)
                
                if showDishShare {
                    ShareOverlayView(
                        onClose: { withAnimation(.easeOut(duration: 0.25)) { showDishShare = false } },
                        showsMoreOptions: false,
                        theme: .light
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom))
                    .zIndex(3)
                }
            }
            .allowsHitTesting(showDishSheet)
            .animation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2), value: showDishSheet)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func dishSheetContent(in geo: GeometryProxy) -> some View {
        if let dish = selectedDish {
            let sidesTotal = recommendedSides.reduce(0) { partialResult, option in
                partialResult + (Double(sideOptionQuantities[option.id] ?? 0) * option.price)
            }
            let drinksTotal = recommendedDrinks.reduce(0) { partialResult, option in
                partialResult + (Double(drinkOptionQuantities[option.id] ?? 0) * option.price)
            }
            let totalPrice = (dish.price * Double(dishQuantity)) + sidesTotal + drinksTotal

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.35))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                ZStack(alignment: .top) {
                    TrackableScrollView(
                        contentOffsetY: $dishSheetContentOffsetY,
                        scrollToTopToken: dishSheetScrollToTopToken,
                        showsIndicators: false
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            ZStack(alignment: .topTrailing) {
                                dishImage(dish.imageUrl)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                Button(action: { closeDishSheet() }) {
                                    Circle()
                                        .fill(Color.black.opacity(0.35))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Image(systemName: "xmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 13, weight: .bold))
                                        )
                                }
                                .padding(12)
                            }

                            HStack(alignment: .top, spacing: 12) {
                                Text(dish.title)
                                    .foregroundColor(.black)
                                    .font(.system(size: 24, weight: .bold))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 10) {
                                    Button(action: {
                                        withAnimation(.easeOut(duration: 0.25)) { showDishShare = true }
                                    }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.black.opacity(0.75))
                                            .font(.system(size: 16, weight: .semibold))
                                            .frame(width: 34, height: 34)
                                            .background(Color.gray.opacity(0.10))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }

                                    Button(action: {}) {
                                        Image(systemName: "bookmark")
                                            .foregroundColor(.black.opacity(0.75))
                                            .font(.system(size: 16, weight: .semibold))
                                            .frame(width: 34, height: 34)
                                            .background(Color.gray.opacity(0.10))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                            }

                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sit amet nisl a risus porta pellentesque. Integer vitae sem in justo luctus tincidunt. Sed pharetra, justo at aliquet euismod, mauris enim facilisis erat, a accumsan arcu urna nec sapien.")
                                .foregroundColor(.gray)
                                .font(.system(size: 15))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(priceText(dish.price))
                                .foregroundColor(.black)
                                .font(.system(size: 22, weight: .bold))

                            Divider()
                                .overlay(Color.gray.opacity(0.15))

                            optionSection(
                                title: "Acompañamiento recomendado",
                                subtitle: "Selecciona varias opciones",
                                options: recommendedSides,
                                quantities: $sideOptionQuantities
                            )

                            optionSection(
                                title: "Bebidas recomendadas",
                                subtitle: "Selecciona varias opciones",
                                options: recommendedDrinks,
                                quantities: $drinkOptionQuantities
                            )

                            Spacer(minLength: 8)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 2)
                        .padding(.bottom, 16)
                    }
                    .onChange(of: dishSheetContentOffsetY) { _, newValue in
                        let shouldShow = newValue > 168
                        if shouldShow != showDishMiniHeader {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                showDishMiniHeader = shouldShow
                            }
                        }
                    }

                    if showDishMiniHeader {
                        dishMiniHeader(dish)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(2)
                    }
                }

                HStack(spacing: 12) {
                    quantityStepper

                    Button(action: {
                        addToCart(dish, quantity: dishQuantity)
                        closeDishSheet()
                    }) {
                        VStack(spacing: 2) {
                            Text("Agregar al Carrito •")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .bold))
                            Text(priceText(totalPrice))
                                .foregroundColor(.white.opacity(0.92))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 10)

                Spacer(minLength: 0)
                    .frame(height: geo.safeAreaInsets.bottom)
            }
            .frame(maxWidth: .infinity)
            .frame(height: geo.size.height * 0.75)
            .background(Color.white)
            .clipShape(FullMenuRoundedCorners(radius: 28, corners: [.topLeft, .topRight]))
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        }
    }
    
    private func branchRow(_ branch: Branch) -> some View {
        let isSelected = (pendingBranchName.isEmpty ? currentBranchName : pendingBranchName) == branch.name
        let isNearest = branch.id == nearestBranchId
        return Button(action: { pendingBranchName = branch.name }) {
            HStack(spacing: 12) {
                Image(systemName: "storefront.fill")
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.65))
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(isSelected ? Color.fuchsia : Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("FoodTook - \(branch.name)")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(branch.address)
                        .foregroundColor(.gray)
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        Text(String(format: "%.1f km", branch.distanceKm))
                            .foregroundColor(.fuchsia)
                            .font(.system(size: 13, weight: .semibold))
                        if isNearest {
                            Text("Más cerca")
                                .foregroundColor(.fuchsia)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(Color.fuchsia.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.fuchsia)
                        .font(.system(size: 18, weight: .bold))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.25))
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.fuchsia : Color.gray.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
    
    private func openBranchSheet() {
        if pendingBranchName.isEmpty {
            pendingBranchName = currentBranchName
        }
        if showDishSheet {
            closeDishSheet()
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            showBranchSheet = true
        }
    }
    
    private func closeBranchSheet() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            showBranchSheet = false
        }
    }

    private func openDishSheet(_ dish: Dish) {
        if showBranchSheet {
            closeBranchSheet()
        }
        selectedDish = dish
        dishQuantity = 1
        sideOptionQuantities = [:]
        drinkOptionQuantities = [:]
        showDishMiniHeader = false
        dishSheetContentOffsetY = 0
        dishSheetScrollToTopToken += 1
        showDishShare = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            showDishSheet = true
        }
    }

    private func closeDishSheet() {
        showDishShare = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2)) {
            showDishSheet = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if !showDishSheet {
                selectedDish = nil
            }
        }
    }
    
    private func addToCart(_ dish: Dish, quantity: Int = 1) {
        guard quantity > 0 else { return }
        cart[dish.id, default: 0] += quantity
    }

    private func removeFromCart(_ dish: Dish, quantity: Int = 1) {
        guard quantity > 0 else { return }
        let current = cart[dish.id] ?? 0
        let updated = max(0, current - quantity)
        if updated == 0 {
            cart.removeValue(forKey: dish.id)
        } else {
            cart[dish.id] = updated
        }
    }

    private func menuItemQuantityControl(_ dish: Dish, quantity: Int) -> some View {
        Group {
            if quantity <= 0 {
                Button(action: { addToCart(dish, quantity: 1) }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        )
                }
            } else {
                HStack(spacing: 10) {
                    Button(action: { removeFromCart(dish, quantity: 1) }) {
                        Image(systemName: "minus")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(Circle())
                    }

                    Text("\(quantity)")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                        .frame(minWidth: 14)

                    Button(action: { addToCart(dish, quantity: 1) }) {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
        }
    }

    private var quantityStepper: some View {
        HStack(spacing: 12) {
            Button(action: {
                dishQuantity = max(1, dishQuantity - 1)
            }) {
                Text("−")
                    .foregroundColor(.green)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 36, height: 36)
            }

            Text("\(dishQuantity)")
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .bold))
                .frame(minWidth: 22)

            Button(action: {
                dishQuantity = min(99, dishQuantity + 1)
            }) {
                Text("+")
                    .foregroundColor(.green)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 54)
        .background(Color.gray.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func dishMiniHeader(_ dish: Dish) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dish.title)
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                Text(priceText(dish.price))
                    .foregroundColor(.black.opacity(0.75))
                    .font(.system(size: 14, weight: .semibold))
            }

            Spacer()

            Button(action: { closeDishSheet() }) {
                Circle()
                    .fill(Color.gray.opacity(0.18))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "xmark")
                            .foregroundColor(.black.opacity(0.75))
                            .font(.system(size: 13, weight: .bold))
                    )
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(Rectangle().fill(Color.gray.opacity(0.12)).frame(height: 1), alignment: .bottom)
    }

    private func optionSection(
        title: String,
        subtitle: String,
        options: [DishOption],
        quantities: Binding<[String: Int]>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.black)
                    .font(.system(size: 17, weight: .bold))
                Text(subtitle)
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
            }

            VStack(spacing: 10) {
                ForEach(options) { option in
                    dishOptionQuantityRow(option: option, quantities: quantities)
                }
            }
        }
    }

    private func dishOptionQuantityRow(option: DishOption, quantities: Binding<[String: Int]>) -> some View {
        let qty = quantities.wrappedValue[option.id] ?? 0
        let isSelected = qty > 0
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(option.title)
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                Text(plusPriceText(option.price))
                    .foregroundColor(.black.opacity(0.8))
                    .font(.system(size: 14, weight: .bold))
            }

            Spacer()

            if qty <= 0 {
                Button(action: {
                    quantities.wrappedValue[option.id] = 1
                }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        )
                }
            } else {
                HStack(spacing: 10) {
                    Button(action: {
                        let updated = max(0, qty - 1)
                        if updated == 0 {
                            quantities.wrappedValue.removeValue(forKey: option.id)
                        } else {
                            quantities.wrappedValue[option.id] = updated
                        }
                    }) {
                        Image(systemName: "minus")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 30, height: 30)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(Circle())
                    }

                    Text("\(qty)")
                        .foregroundColor(.black)
                        .font(.system(size: 15, weight: .bold))
                        .frame(minWidth: 16)

                    Button(action: {
                        quantities.wrappedValue[option.id] = min(99, qty + 1)
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 30, height: 30)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(isSelected ? Color.white : Color.gray.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.green : Color.gray.opacity(0.10), lineWidth: isSelected ? 2 : 1)
        )
    }
    
    private func priceText(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func plusPriceText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let amount = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "+$\(amount)"
    }
    
    private var coverImage: some View {
        Group {
            if let url = URL(string: coverUrl), !coverUrl.isEmpty {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                )
            }
        }
    }
    
    private var avatarImage: some View {
        Group {
            if let url = URL(string: avatarUrl), !avatarUrl.isEmpty {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color.white.opacity(0.9))
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.gray.opacity(0.55))
                }
            }
        }
    }
    
    private var headerGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black.opacity(0.0), location: 0.0),
                .init(color: Color.black.opacity(0.05), location: 0.35),
                .init(color: Color.black.opacity(0.35), location: 0.65),
                .init(color: Color.black.opacity(0.65), location: 0.85),
                .init(color: Color.black.opacity(0.75), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func dishImage(_ urlString: String) -> some View {
        Group {
            if let url = URL(string: urlString), !urlString.isEmpty {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

struct FullMenuRoundedCorners: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Refactored Components for Performance

struct FullMenuBranchCard: View {
    let branchName: String
    let distanceKm: Double?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SUCURSAL SELECCIONADA")
                        .foregroundColor(.gray)
                        .font(.system(size: 11, weight: .bold))
                    Text(branchName)
                        .foregroundColor(.black)
                        .font(.system(size: 15, weight: .bold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("DISTANCIA")
                        .foregroundColor(.gray)
                        .font(.system(size: 11, weight: .bold))
                    HStack(spacing: 6) {
                        Text(String(format: "%.1f km", distanceKm ?? 2.3))
                            .foregroundColor(.black)
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray.opacity(0.8))
                            .font(.system(size: 13, weight: .bold))
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        }
    }
}

struct FullMenuCategoryTabs: View {
    let categories: [String]
    @Binding var activeTab: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { t in
                    Button(action: { withAnimation(.easeInOut(duration: 0.18)) { activeTab = t } }) {
                        Text(t)
                            .foregroundColor(activeTab == t ? .white : .black.opacity(0.7))
                            .font(.system(size: 13, weight: .bold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(activeTab == t ? Color.fuchsia : Color.gray.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}

struct FullMenuDishRow: View {
    let dish: FullMenuView.Dish
    let quantity: Int
    let onTap: () -> Void
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let url = URL(string: dish.imageUrl), !dish.imageUrl.isEmpty {
                    WebImage(url: url)
                        .resizable()
                        .indicator(.activity)
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: 66, height: 66)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(dish.title)
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "$%.2f", dish.price))
                        .foregroundColor(.black)
                        .font(.system(size: 15, weight: .bold))
                }
                
                Text(dish.subtitle)
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
                    .lineLimit(2)
            }
            .padding(.bottom, 18)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        .overlay(alignment: .bottomTrailing) {
            quantityControl
                .padding(10)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture(perform: onTap)
    }
    
    private var quantityControl: some View {
        Group {
            if quantity <= 0 {
                Button(action: onAdd) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        )
                }
            } else {
                HStack(spacing: 10) {
                    Button(action: onRemove) {
                        Image(systemName: "minus")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(Circle())
                    }

                    Text("\(quantity)")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                        .frame(minWidth: 14)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
        }
    }
}
