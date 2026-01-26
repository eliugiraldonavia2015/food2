import SwiftUI
import SDWebImageSwiftUI

// Model definitions
struct EditableDish: Identifiable {
    let id: String
    var category: String
    var title: String
    var subtitle: String
    var price: Double
    var imageUrl: String
    var isPopular: Bool
}

// Reuse the same view model logic but adapted for editing
class RestaurantEditableMenuViewModel: ObservableObject {
    @Published var dishes: [EditableDish] = []
    @Published var categories: [String] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Simulating data loading
        self.dishes = [
            .init(id: "green-burger", category: "Pizzas", title: "Clásica Green Burger", subtitle: "Carne premium, lechuga fresca, jitomate y nuestra salsa especial de la casa.", price: 12.99, imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd", isPopular: true),
            .init(id: "avocado-toast", category: "Desayunos", title: "Avocado Toast", subtitle: "Pan de masa madre, aguacate hass, huevo pochado y semillas de girasol.", price: 8.50, imageUrl: "https://images.unsplash.com/photo-1588137372308-15f75323ca8d", isPopular: true),
            .init(id: "sushi-bowl", category: "Comida Asiática", title: "Salmon Poke Bowl", subtitle: "Salmón fresco, arroz de sushi, edamames, aguacate y salsa ponzu.", price: 14.20, imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c", isPopular: true),
            .init(id: "tacos-pastor", category: "Mexicana", title: "Orden de Tacos al Pastor", subtitle: "5 tacos con todo: piña, cilantro, cebolla y salsa de la casa.", price: 6.00, imageUrl: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b", isPopular: true),
            .init(id: "pizza-margarita", category: "Pizzas", title: "Pizza Margarita", subtitle: "Mozzarella fresca, albahaca y aceite de oliva extra virgen.", price: 11.25, imageUrl: "https://images.unsplash.com/photo-1601924582971-b0d4b3a2c0ba", isPopular: false),
            .init(id: "coca", category: "Bebidas", title: "Coca-Cola", subtitle: "355 ml bien fría.", price: 1.50, imageUrl: "https://images.unsplash.com/photo-1612528443702-f6741f70a049", isPopular: false),
            .init(id: "limonada", category: "Bebidas", title: "Limonada", subtitle: "Natural, con hielo y un toque de menta.", price: 2.00, imageUrl: "https://images.unsplash.com/photo-1528825871115-3581a5387919", isPopular: false),
            .init(id: "cheesecake", category: "Postres", title: "Cheesecake", subtitle: "Clásico, cremoso y con base de galleta.", price: 4.50, imageUrl: "https://images.unsplash.com/photo-1542826438-bd32f43d626f", isPopular: false)
        ]
        
        let cats = Array(Set(self.dishes.map { $0.category })).sorted()
        self.categories = ["Todo"] + cats
    }
    
    func updateDish(_ updatedDish: EditableDish) {
        if let index = dishes.firstIndex(where: { $0.id == updatedDish.id }) {
            dishes[index] = updatedDish
            // Re-calculate categories if needed
            let cats = Array(Set(self.dishes.map { $0.category })).sorted()
            self.categories = ["Todo"] + cats
        }
    }
}

struct RestaurantEditableMenuView: View {
    // Basic props needed for the header
    let restaurantName: String = "Burger King"
    let location: String = "Centro, CDMX"
    let coverUrl: String = "https://images.unsplash.com/photo-1504674900247-0877df9cc836"
    let avatarUrl: String = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd"
    
    // Callback to open main menu
    var onMenuTap: () -> Void
    
    @StateObject private var viewModel = RestaurantEditableMenuViewModel()
    @State private var activeTab: String = "Todo"
    @State private var menuContentOffsetY: CGFloat = 0
    @State private var showMenuMiniHeader: Bool = false
    
    // Edit Sheet State
    @State private var showEditSheet = false
    @State private var selectedDishForEdit: EditableDish?
    
    // Animation state for "jiggle" effect in edit mode
    @State private var isJiggling = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            // Main Content
            TrackableScrollView(contentOffsetY: $menuContentOffsetY, scrollToTopToken: 0, showsIndicators: false) {
                VStack(spacing: 14) {
                    heroSection
                    
                    // Edit Mode Indicator
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                        Text("MODO EDICIÓN ACTIVO")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    .padding(.top, 10)
                    
                    FullMenuCategoryTabs(
                        categories: viewModel.categories,
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
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                isJiggling = true
            }
        }
        .onChange(of: menuContentOffsetY) { _, newValue in
            let shouldShow = newValue > 168
            if shouldShow != showMenuMiniHeader {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showMenuMiniHeader = shouldShow
                }
            }
        }
        .sheet(item: $selectedDishForEdit) { dish in
            EditDishSheet(dish: dish) { updatedDish in
                viewModel.updateDish(updatedDish)
                selectedDishForEdit = nil
            }
        }
    }
    
    // MARK: - Components (Reused & Adapted)
    
    private var heroSection: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 12) {
                identityRow
                    .zIndex(3)
            }
            .padding(.top, -80) // Adjusted for cleaner look in dashboard
        }
    }
    
    private var header: some View {
        let stretch = max(0, -menuContentOffsetY)
        return GeometryReader { geo in
            WebImage(url: URL(string: coverUrl))
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: 250 + stretch)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear, .black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: -stretch)
        }
        .frame(height: 250)
        .padding(.horizontal, -16)
        .ignoresSafeArea(edges: .top)
    }
    
    private var identityRow: some View {
        HStack(spacing: 14) {
            WebImage(url: URL(string: avatarUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(radius: 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurantName)
                    .foregroundColor(.white)
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 13, weight: .semibold))
                    Text(location)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .padding(.leading, 6)

            Spacer()
        }
        .padding(.leading, 18)
    }
    
    private var menuList: some View {
        VStack(alignment: .leading, spacing: 14) {
            let dishes = activeTab == "Todo" ? viewModel.dishes : viewModel.dishes.filter { $0.category == activeTab }
            
            // Group by popularity if "Todo"
            if activeTab == "Todo" {
                sectionHeader("Populares")
                VStack(spacing: 16) {
                    ForEach(dishes.filter { $0.isPopular }) { dish in
                        EditableDishRow(dish: dish, isJiggling: isJiggling) {
                            selectedDishForEdit = dish
                        }
                    }
                }
                
                ForEach(viewModel.categories.filter { $0 != "Todo" }, id: \.self) { cat in
                    let items = dishes.filter { $0.category == cat && !$0.isPopular }
                    if !items.isEmpty {
                        sectionHeader(cat)
                        VStack(spacing: 16) {
                            ForEach(items) { dish in
                                EditableDishRow(dish: dish, isJiggling: isJiggling) {
                                    selectedDishForEdit = dish
                                }
                            }
                        }
                    }
                }
            } else {
                sectionHeader(activeTab)
                VStack(spacing: 16) {
                    ForEach(dishes) { dish in
                        EditableDishRow(dish: dish, isJiggling: isJiggling) {
                            selectedDishForEdit = dish
                        }
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
    
    // Top Bar adapted for Dashboard
    private var topBar: some View {
        Group {
            if showMenuMiniHeader {
                HStack(spacing: 10) {
                    Button(action: onMenuTap) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 40, height: 40)
                    }
                    
                    Text("Editar Menú")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
            } else {
                HStack {
                    Button(action: onMenuTap) {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .bold))
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
    }
}

// MARK: - Editable Row Component
struct EditableDishRow: View {
    let dish: EditableDish
    let isJiggling: Bool
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 12) {
                // Image
                ZStack(alignment: .topTrailing) {
                    WebImage(url: URL(string: dish.imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Edit Icon Overlay
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .overlay(Image(systemName: "pencil").foregroundColor(.blue).font(.system(size: 16, weight: .bold)))
                        .offset(x: 10, y: -10)
                        .scaleEffect(isJiggling ? 1.1 : 1.0)
                        .animation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true), value: isJiggling)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(dish.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .lineLimit(2)
                        Spacer()
                    }
                    
                    Text(dish.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    HStack {
                        Text(String(format: "$%.2f", dish.price))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Text("Editar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.blue))
                            .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                }
                .frame(height: 110)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue.opacity(isJiggling ? 0.5 : 0), lineWidth: 2)
            )
            // Jiggle effect
            .rotationEffect(.degrees(isJiggling ? 1 : -1), anchor: .center)
            .animation(Animation.easeInOut(duration: 0.14).repeatForever(autoreverses: true), value: isJiggling)
            .scaleEffect(isJiggling ? 0.98 : 1.0)
            .animation(Animation.easeInOut(duration: 0.25).repeatForever(autoreverses: true), value: isJiggling)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Edit Sheet
struct EditDishSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var dish: EditableDish
    var onSave: (EditableDish) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información Básica")) {
                    TextField("Nombre del plato", text: $dish.title)
                    TextField("Descripción", text: $dish.subtitle)
                    TextField("Precio", value: $dish.price, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Imagen")) {
                    TextField("URL de imagen", text: $dish.imageUrl)
                    if let url = URL(string: dish.imageUrl) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                    }
                }
                
                Section(header: Text("Configuración")) {
                    Toggle("Es Popular", isOn: $dish.isPopular)
                }
            }
            .navigationTitle("Editar Plato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(dish)
                        dismiss()
                    }
                }
            }
        }
    }
}

// Helper for scroll tracking (duplicated locally to avoid dependency issues if needed, or reuse from FullMenuView)
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
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: TrackableScrollView
        var hostingController: UIHostingController<Content>?

        init(parent: TrackableScrollView) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.contentOffsetY = scrollView.contentOffset.y
        }
    }
}
