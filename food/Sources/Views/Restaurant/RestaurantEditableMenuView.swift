import SwiftUI
import SDWebImageSwiftUI
import Combine

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
    
    func addDish(_ newDish: EditableDish) {
        dishes.append(newDish)
        let cats = Array(Set(self.dishes.map { $0.category })).sorted()
        self.categories = ["Todo"] + cats
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
    @State private var showAddDishSheet = false
    @State private var categoryForNewDish: String? = nil
    
    // Edit Mode Toggle
    @State private var isEditModeActive: Bool = true
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            // Main Content
            TrackableScrollView(contentOffsetY: $menuContentOffsetY, scrollToTopToken: 0, showsIndicators: false) {
                VStack(spacing: 14) {
                    heroSection
                    
                    // Edit Mode Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isEditModeActive.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: isEditModeActive ? "checkmark.circle.fill" : "pencil.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text(isEditModeActive ? "Desactivar Edición" : "Activar Modo Edición")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(isEditModeActive ? Color.black.opacity(0.8) : Color.green)
                        .clipShape(Capsule())
                        .shadow(color: (isEditModeActive ? Color.black : Color.green).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 10)
                    
                    FullMenuCategoryTabs(
                        categories: viewModel.categories,
                        activeTab: $activeTab
                    )
                    
                    menuList
                    
                    if isEditModeActive {
                        // Action Buttons Section
                        VStack(spacing: 12) {
                            Button(action: {
                                categoryForNewDish = nil // General add
                                showAddDishSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Agregar Nuevo Plato")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: {
                                // Action for adding category could be implemented here
                            }) {
                                HStack {
                                    Image(systemName: "folder.badge.plus")
                                    Text("Agregar Categoría")
                                }
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 16)
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) {
                topBar
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
            EditDishSheet(dish: dish, categories: viewModel.categories.filter { $0 != "Todo" }) { updatedDish in
                viewModel.updateDish(updatedDish)
                selectedDishForEdit = nil
            }
        }
        .sheet(isPresented: $showAddDishSheet) {
            EditDishSheet(
                dish: EditableDish(
                    id: UUID().uuidString,
                    category: categoryForNewDish ?? (viewModel.categories.first { $0 != "Todo" } ?? "General"),
                    title: "",
                    subtitle: "",
                    price: 0.0,
                    imageUrl: "",
                    isPopular: false
                ),
                categories: viewModel.categories.filter { $0 != "Todo" },
                isNew: true
            ) { newDish in
                viewModel.addDish(newDish)
                showAddDishSheet = false
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
                infoRow
                    .zIndex(2)
            }
            .padding(.top, -140) // Match FullMenuView offset
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
                    Text(location)
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
            let dishes = activeTab == "Todo" ? viewModel.dishes : viewModel.dishes.filter { $0.category == activeTab }
            
            // Group by popularity if "Todo"
            if activeTab == "Todo" {
                sectionHeader("Populares")
                VStack(spacing: 16) {
                    ForEach(dishes.filter { $0.isPopular }) { dish in
                        if isEditModeActive {
                            EditableDishRow(dish: dish) {
                                selectedDishForEdit = dish
                            }
                        } else {
                            // Standard View Mode
                            StandardDishRow(dish: dish)
                        }
                    }
                }
                
                ForEach(viewModel.categories.filter { $0 != "Todo" }, id: \.self) { cat in
                    let items = dishes.filter { $0.category == cat && !$0.isPopular }
                    // Show section if it has items OR if we are in edit mode (to allow adding items to empty sections)
                    if !items.isEmpty || isEditModeActive {
                        HStack {
                            sectionHeader(cat)
                            Spacer()
                            if isEditModeActive {
                                Button(action: {
                                    categoryForNewDish = cat
                                    showAddDishSheet = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        
                        VStack(spacing: 16) {
                            ForEach(items) { dish in
                                if isEditModeActive {
                                    EditableDishRow(dish: dish) {
                                        selectedDishForEdit = dish
                                    }
                                } else {
                                    StandardDishRow(dish: dish)
                                }
                            }
                        }
                    }
                }
            } else {
                HStack {
                    sectionHeader(activeTab)
                    Spacer()
                    if isEditModeActive {
                        Button(action: {
                            categoryForNewDish = activeTab
                            showAddDishSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 8)
                    }
                }
                VStack(spacing: 16) {
                    ForEach(dishes) { dish in
                        if isEditModeActive {
                            EditableDishRow(dish: dish) {
                                selectedDishForEdit = dish
                            }
                        } else {
                            StandardDishRow(dish: dish)
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

// MARK: - Standard Row Component (Non-Editable)
struct StandardDishRow: View {
    let dish: EditableDish
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Image
            WebImage(url: URL(string: dish.imageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
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
                    
                    // Add Button (Visual only for preview)
                    Button(action: {}) {
                        Text("Agregar")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.green))
                    }
                }
            }
            .frame(height: 110)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Editable Row Component
struct EditableDishRow: View {
    let dish: EditableDish
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
                    
                    // Edit Icon Overlay (Static, non-bouncing)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .overlay(Image(systemName: "pencil").foregroundColor(.blue).font(.system(size: 16, weight: .bold)))
                        .offset(x: 10, y: -10)
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
                        
                        // No button here, row is clickable
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
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Redesigned Edit Sheet
struct EditDishSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var dish: EditableDish
    var categories: [String]
    var isNew: Bool = false
    var onSave: (EditableDish) -> Void
    
    @State private var showingImageSourceOptions = false
    @State private var showingAIStyleOptions = false
    @State private var showingAddStyleSheet = false
    @State private var isGeneratingAI = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Image Section
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            if !dish.imageUrl.isEmpty, let url = URL(string: dish.imageUrl) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 220)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("Sin imagen")
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                            
                            HStack(spacing: 12) {
                                // AI Menu
                                Menu {
                                    Button(action: { /* Apply Style 1 */ }) {
                                        Label("Estilo #1", systemImage: "camera.macro")
                                    }
                                    Button(action: { /* Apply Style 2 */ }) {
                                        Label("Estilo #2", systemImage: "paintbrush.pointed.fill")
                                    }
                                    Button(action: { showingAddStyleSheet = true }) {
                                        Label("Agregar estilo", systemImage: "plus.circle.fill")
                                    }
                                } label: {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                                        .overlay(Image(systemName: "wand.and.stars").foregroundColor(.purple).font(.system(size: 18, weight: .bold)))
                                }
                                
                                // Camera/Gallery Menu
                                Menu {
                                    Button(action: { /* Take Photo */ }) {
                                        Label("Tomar foto", systemImage: "camera")
                                    }
                                    Button(action: { /* Choose from Gallery */ }) {
                                        Label("Elegir de la galería", systemImage: "photo.on.rectangle")
                                    }
                                } label: {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                                        .overlay(Image(systemName: "camera.fill").foregroundColor(.black).font(.system(size: 18, weight: .bold)))
                                }
                            }
                            .padding(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Details Section
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre del plato")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            TextField("Ej: Hamburguesa Clásica", text: $dish.title, prompt: Text("Ej: Hamburguesa Clásica").foregroundColor(.gray))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.vertical, 8)
                            
                            Divider()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descripción")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            TextField("Describe los ingredientes y el sabor...", text: $dish.subtitle, prompt: Text("Describe los ingredientes y el sabor...").foregroundColor(.gray), axis: .vertical)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .lineLimit(3...5)
                                .padding(12)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                        }
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Precio")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                
                                TextField("0.00", value: $dish.price, format: .currency(code: "USD"), prompt: Text("0.00").foregroundColor(.gray))
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(12)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Categoría")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                
                                Menu {
                                    ForEach(categories, id: \.self) { cat in
                                        Button(cat) { dish.category = cat }
                                    }
                                } label: {
                                    HStack {
                                        Text(dish.category)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(12)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color.white)
            .navigationTitle(isNew ? "Crear Plato" : "Editar Plato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(dish)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black)
                    .clipShape(Capsule())
                }
            }
            .sheet(isPresented: $showingAddStyleSheet) {
                AddStyleView(isGeneratingAI: $isGeneratingAI, dish: $dish)
            }
            .overlay {
                if isGeneratingAI {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Procesando con AI...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(30)
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}

struct AddStyleView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isGeneratingAI: Bool
    @Binding var dish: EditableDish
    @State private var styleDescription = ""
    @State private var appear = false
    
    // Reference Image State
    @State private var referenceImage: UIImage? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.gray.opacity(0.05).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 56))
                            .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(.top, 20)
                            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                            .scaleEffect(appear ? 1 : 0.5)
                            .opacity(appear ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appear)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Define tu Estilo")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Describe cómo quieres que se vea la imagen o añade una referencia visual. La IA transformará tu plato siguiendo estas instrucciones.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
                    
                    // Input Area
                    ZStack(alignment: .topLeading) {
                        if styleDescription.isEmpty {
                            Text("Ej: Iluminación cinematográfica, estilo minimalista, fondo desenfocado, colores vibrantes...")
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $styleDescription)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(.black)
                            .padding(8)
                            .frame(height: 120)
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(styleDescription.isEmpty ? Color.clear : Color.purple.opacity(0.3), lineWidth: 1)
                    )
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 30)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)
                    
                    // Reference Image Upload Section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Imagen de Referencia (Opcional)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            Menu {
                                Button(action: { 
                                    // Simulate taking photo
                                    referenceImage = UIImage(systemName: "photo.fill") 
                                }) {
                                    Label("Tomar foto", systemImage: "camera")
                                }
                                Button(action: { 
                                    // Simulate gallery selection
                                    referenceImage = UIImage(systemName: "photo.fill")
                                }) {
                                    Label("Elegir de la galería", systemImage: "photo.on.rectangle")
                                }
                                if referenceImage != nil {
                                    Button(role: .destructive, action: { referenceImage = nil }) {
                                        Label("Eliminar imagen", systemImage: "trash")
                                    }
                                }
                            } label: {
                                HStack {
                                    if let _ = referenceImage {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Imagen seleccionada")
                                            .foregroundColor(.black)
                                            .fontWeight(.medium)
                                    } else {
                                        Image(systemName: "photo.badge.plus")
                                            .foregroundColor(.blue)
                                        Text("Subir imagen de referencia")
                                            .foregroundColor(.blue)
                                            .fontWeight(.medium)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        if let _ = referenceImage {
                            // Small Preview
                            Image(systemName: "photo") // Placeholder for preview
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                                .padding(4)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.1), radius: 3)
                        }
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 35)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: appear)

                    Spacer()
                    
                    // Button
                    Button(action: {
                        dismiss()
                        // Simulate AI Generation start
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isGeneratingAI = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                isGeneratingAI = false
                                dish.imageUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1" // Mock update
                            }
                        }
                    }) {
                        HStack {
                            Text("Guardar Estilo")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: (styleDescription.isEmpty && referenceImage == nil) ? [.gray] : [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: (styleDescription.isEmpty && referenceImage == nil) ? .clear : .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .disabled(styleDescription.isEmpty && referenceImage == nil)
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.9)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: appear)
                    .padding(.bottom, 10)
                }
                .padding(24)
            }
            .navigationTitle("Nuevo Estilo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.black)
                }
            }
            .onAppear {
                appear = true
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
