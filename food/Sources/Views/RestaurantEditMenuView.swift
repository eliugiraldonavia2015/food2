import SwiftUI
import SDWebImageSwiftUI

struct RestaurantEditMenuView: View {
    let restaurantId: String
    let restaurantName: String
    let coverUrl: String
    let avatarUrl: String
    let location: String
    let branchName: String?
    let distanceKm: Double?
    @Environment(\.dismiss) private var dismiss
    @State private var activeTab: String = "Todo"
    @State private var tabs: [String] = ["Todo"]
    @State private var showDishSheet = false
    @State private var sheetTitle: String = ""
    @State private var sheetImageUrl: String = ""
    @State private var sheetPrice: String = "$15.99"
    @State private var sheetSubtitle: String = "Pizza con mozzarella fresca"
    @State private var priceFrame: CGRect = .zero
    @State private var isEditingInfo: Bool = false
    @State private var showEnableSections = false
    @State private var showAddItem = false
    @State private var catalogItems: [SectionCatalogItem] = []
    @State private var selectedCatalogIds: Set<String> = []
    @State private var sections: [MenuSection] = []
    @State private var newItemName: String = ""
    @State private var newItemDescription: String = ""
    @State private var newItemPrice: String = ""
    @State private var newItemImageUrl: String = ""
    @State private var newItemSectionId: String = ""
    @State private var newItemPublish: Bool = true
    @State private var isSavingSections: Bool = false
    @State private var selectedItemId: String = ""
    @State private var isSavingAll: Bool = false
    @State private var showSaveToast: Bool = false
    @State private var showErrorToast: Bool = false
    @State private var errorMessage: String = ""
    private var effectiveRestaurantId: String {
        if !restaurantId.isEmpty { return restaurantId }
        return AuthService.shared.user?.uid ?? restaurantId
    }
    private struct EditableItem: Identifiable { let id = UUID(); var title: String; var price: String; var editing: Bool }
    @State private var sideItems: [EditableItem] = [
        .init(title: "Papas Fritas", price: "+ $2.5", editing: false),
        .init(title: "Aros de Cebolla", price: "+ $3", editing: false),
        .init(title: "Ensalada César", price: "+ $2", editing: false)
    ]
    @State private var drinkItems: [EditableItem] = [
        .init(title: "Coca-Cola", price: "+ $1.5", editing: false),
        .init(title: "Limonada", price: "+ $2", editing: false),
        .init(title: "Té Helado", price: "+ $1.8", editing: false)
    ]
    private struct UIItem: Identifiable { let id = UUID(); let title: String; let url: String; let itemId: String }
    @State private var menuData: [String: [UIItem]] = [:]
    private var allItems: [UIItem] { Array(menuData.values.joined()) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    categoryTabs
                    sectionsStack
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
            }
            .ignoresSafeArea(edges: .top)
            .blur(radius: showDishSheet ? 8 : 0)
            .allowsHitTesting(!showDishSheet)
            if !showDishSheet { saveBar }
            topBar
            if showDishSheet { dishBottomSheet }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            MenuService.shared.getSectionCatalog { res in
                if case .success(let items) = res {
                    catalogItems = items
                }
            }
            MenuService.shared.listEnabledSections(restaurantId: restaurantId) { res in
                if case .success(let secs) = res {
                    sections = secs
                    let names = secs.map { $0.name }
                    tabs = ["Todo"] + names
                    MenuService.shared.listMenuItems(restaurantId: restaurantId, publishedOnly: false) { itemsRes in
                        if case .success(let items) = itemsRes {
                            var grouped: [String: [UIItem]] = [:]
                            for it in items {
                                let ui = UIItem(title: it.name, url: it.imageUrls.first ?? "", itemId: it.id)
                                let secName = secs.first(where: { $0.id == it.sectionId })?.name ?? "Otros"
                                grouped[secName, default: []].append(ui)
                            }
                            menuData = grouped
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showSaveToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Cambios guardados").foregroundColor(.white).font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.bottom, 12)
            } else if showErrorToast {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                    Text(errorMessage).foregroundColor(.white).font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.bottom, 12)
            }
        }
    }

    private var header: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            ZStack(alignment: .bottomLeading) {
                WebImage(url: URL(string: coverUrl))
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: minY > 0 ? 240 + minY : 240)
                    .blur(radius: minY > 0 ? min(12, minY / 18) : 0, opaque: true)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.0), location: 0.0),
                                .init(color: Color.black.opacity(0.0), location: 0.55),
                                .init(color: Color.black.opacity(0.30), location: 0.65),
                                .init(color: Color.black.opacity(0.75), location: 0.75),
                                .init(color: Color.black.opacity(1.0), location: 0.85),
                                .init(color: Color.black.opacity(1.0), location: 0.92),
                                .init(color: Color.black.opacity(1.0), location: 0.97),
                                .init(color: Color.black.opacity(1.0), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: minY > 0 ? -minY : 0)
                HStack(alignment: .center, spacing: 12) {
                    WebImage(url: URL(string: avatarUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.green, lineWidth: 2))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(restaurantName)
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .bold))
                        Text(location)
                            .foregroundColor(.white.opacity(0.9))
                            .font(.subheadline)
                    }
                }
                .padding(16)
                .offset(y: minY > 0 ? -minY * 0.6 : 0)
            }
            .frame(height: 240)
        }
        .frame(height: 240)
        .padding(.horizontal, -16)
        .ignoresSafeArea(edges: .top)
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tabs, id: \.self) { t in
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { activeTab = t } }) {
                        Text(t)
                            .foregroundColor(activeTab == t ? .black : .white)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(activeTab == t ? Color.green : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        HStack { Text(t).foregroundColor(.white).font(.headline); Spacer() }
    }

    private var sectionsStack: some View {
        VStack(spacing: 20) {
            if activeTab == "Todo" {
                section("Todo", items: allItems)
            } else {
                section(activeTab, items: menuData[activeTab] ?? [])
            }
        }
    }

    private func section(_ title: String, items: [UIItem]) -> some View {
        VStack(spacing: 12) {
            sectionTitle(title)
            if items.isEmpty {
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 260, height: 120)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        VStack(spacing: 6) {
                            Text("No hay items todavía")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                            Text("Añade platos a esta sección")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(items) { it in
                            optionDealCard(title: it.title, url: it.url, itemId: it.itemId, merchant: restaurantName, time: String(format: "%.0f min", (distanceKm ?? 48)))
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private func optionDealCard(title: String, url: String, itemId: String, merchant: String, time: String) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                WebImage(url: URL(string: url))
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .mask(
                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: 180, height: 110)
                    )
                Text("-20%")
                    .foregroundColor(.black)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(4)
                    .padding(8)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("$5,00")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                    Text("$10,80")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                        .strikethrough()
                }
                Text(title)
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(merchant)
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                    Text("•")
                        .foregroundColor(.gray)
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                    Text(time)
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
            }
            .padding(10)
            .frame(width: 180, alignment: .leading)
            .background(Color.white.opacity(0.12))
        }
        .frame(width: 180)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.22), lineWidth: 1))
        .onTapGesture {
            sheetTitle = title
            sheetImageUrl = url
            sheetPrice = "$15.99"
            sheetSubtitle = "Pizza con mozzarella fresca"
            selectedItemId = itemId
            withAnimation(.easeOut(duration: 0.25)) { showDishSheet = true }
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { showEnableSections = true }) {
                        Text("Habilitar Secciones")
                            .foregroundColor(.black)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button(action: { showAddItem = true }) {
                        Text("Añadir Plato")
                            .foregroundColor(.black)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 26)
            .padding(.top, 8)
            Spacer()
        }
        .sheet(isPresented: $showEnableSections) { enableSectionsSheet }
        .sheet(isPresented: $showAddItem) { addItemSheet }
    }

    private var dishBottomSheet: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    dishTopBlock
                    dishInfoPanel
                    VStack(alignment: .leading, spacing: 16) {
                        sectionTitle("Acompañamiento recomendado")
                        ForEach($sideItems) { $it in
                            editableRow(item: $it)
                        }
                        addItemRow(forDrinks: false)
                        sectionTitle("Bebidas recomendadas")
                        ForEach($drinkItems) { $it in
                            editableRow(item: $it)
                        }
                        addItemRow(forDrinks: true)
                        sectionTitle("Notas especiales")
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 100)
                            .overlay(
                                Text("¿Alguna preferencia? (ej: sin cebolla, extra salsa...)")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.footnote)
                                    .padding(12), alignment: .topLeading
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 56)
                }
            }
            .overlay(alignment: .topTrailing) { sheetCloseButton.padding(10) }
            .safeAreaInset(edge: .bottom) { sheetActionBar.padding(.horizontal, 16).padding(.top, 0).padding(.bottom, 0).background(Color.black) }
            .coordinateSpace(name: "dishScroll")
            .onPreferenceChange(PriceFrameKey.self) { v in
                priceFrame = v
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.75)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: -4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var dishTopBlock: some View {
        GeometryReader { g in
            let y = g.frame(in: .named("dishScroll")).minY
            ZStack(alignment: .topTrailing) {
                WebImage(url: URL(string: sheetImageUrl))
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .opacity(max(0.0, min(1.0, 1.0 + Double(y) / 160.0)))
                Button(action: { withAnimation(.easeOut(duration: 0.25)) { showDishSheet = false } }) {
                    Circle().fill(Color.black.opacity(0.6)).frame(width: 32, height: 32)
                        .overlay(Image(systemName: "xmark").foregroundColor(.white))
                        .padding(10)
                }
                .opacity(max(0.0, min(1.0, 1.0 + Double(y) / 120.0)))
            }
            .background(Color.clear)
        }
        .frame(height: 180)
        .padding(.horizontal, 12)
    }

    private var dishInfoPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditingInfo {
                TextField("Nombre del plato", text: $sheetTitle)
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .bold))
                TextField("Descripción", text: $sheetSubtitle)
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 14))
                TextField("Precio", text: $sheetPrice)
                    .foregroundColor(.green)
                    .font(.system(size: 20, weight: .bold))
                HStack {
                    Spacer()
                    Button(action: {
                        let price = Double(sheetPrice.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ".")) ?? 0.0
                        let imgs = sheetImageUrl.isEmpty ? [] : [sheetImageUrl]
                        MenuService.shared.updateMenuItem(restaurantId: effectiveRestaurantId, itemId: selectedItemId, name: sheetTitle, description: sheetSubtitle, price: price, imageUrls: imgs, isPublished: nil) { e in
                            if let e = e {
                                errorMessage = "Error guardando plato: \(e.localizedDescription)"
                                showErrorToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { showErrorToast = false }
                            } else {
                                for key in menuData.keys {
                                    if let idx = menuData[key]?.firstIndex(where: { $0.itemId == selectedItemId }) {
                                        menuData[key]?[idx] = UIItem(title: sheetTitle, url: sheetImageUrl, itemId: selectedItemId)
                                    }
                                }
                                isEditingInfo = false
                            }
                        }
                    }) {
                        Text("Guardar")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
            } else {
                Text(sheetTitle).foregroundColor(.white).font(.system(size: 22, weight: .bold))
                Text(sheetSubtitle).foregroundColor(.white.opacity(0.9)).font(.system(size: 14))
                Text(sheetPrice).foregroundColor(.green).font(.system(size: 20, weight: .bold))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.black))
        .offset(y: -18)
        .padding(.horizontal, 12)
        .overlay(alignment: .topTrailing) {
            Button(action: { isEditingInfo.toggle() }) {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 28, height: 28)
                    .overlay(Image(systemName: "pencil").foregroundColor(.gray))
            }
            .padding(4)
            .offset(x: -14, y: -12)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: PriceFrameKey.self, value: geo.frame(in: .named("dishScroll")))
            }
        )
    }

    private func editableRow(item: Binding<EditableItem>) -> some View {
        HStack {
            Button(action: { item.wrappedValue.editing = true }) {
                Text("Editar")
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            if item.wrappedValue.editing {
                TextField("Nombre", text: item.title)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                TextField("Precio", text: item.price)
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .semibold))
                Button(action: { item.wrappedValue.editing = false }) {
                    Text("Guardar")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Text(item.wrappedValue.title)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                Spacer()
                Text(item.wrappedValue.price)
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
    }

    private func addItemRow(forDrinks: Bool) -> some View {
        Button(action: {
            let new = EditableItem(title: "", price: "", editing: true)
            if forDrinks {
                drinkItems.append(new)
            } else {
                sideItems.append(new)
            }
        }) {
            HStack {
                Text("Añadir item")
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(Capsule())
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private var sheetCloseButton: some View {
        Button(action: { withAnimation(.easeOut(duration: 0.25)) { showDishSheet = false } }) {
            Circle().fill(Color.black.opacity(0.6)).frame(width: 32, height: 32)
                .overlay(Image(systemName: "xmark").foregroundColor(.white))
        }
    }

    private var sheetActionBar: some View {
        Button(action: {}) {
            Text("Agregar al carrito • \(sheetPrice)")
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var saveBar: some View {
        VStack {
            Spacer()
            Button(action: {
                guard !isSavingAll else { return }
                isSavingAll = true
                // Asegurar que se persistan las secciones seleccionadas en tabs aunque la hoja se haya cerrado
                let targetNames = tabs.filter { $0 != "Todo" }
                let existingNames = Set(sections.map { $0.name })
                let missingNames = targetNames.filter { !existingNames.contains($0) }
                let toEnable = catalogItems.filter { missingNames.contains($0.name) }
                let rid = effectiveRestaurantId
                let enableCompletion: (Error?) -> Void = { _ in
                    MenuService.shared.listEnabledSections(restaurantId: rid) { res in
                        let loadedSecs = (try? res.get()) ?? sections
                        sections = loadedSecs
                        tabs = ["Todo"] + loadedSecs.map { $0.name }
                        MenuService.shared.listMenuItems(restaurantId: rid, publishedOnly: false) { itemsRes in
                            if case .success(let items) = itemsRes {
                                var grouped: [String: [UIItem]] = [:]
                                for it in items {
                                    let ui = UIItem(title: it.name, url: it.imageUrls.first ?? "", itemId: it.id)
                                    let secName = loadedSecs.first(where: { $0.id == it.sectionId })?.name ?? "Otros"
                                    grouped[secName, default: []].append(ui)
                                }
                                menuData = grouped
                            }
                            isSavingAll = false
                            showSaveToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showSaveToast = false }
                        }
                    }
                }
                if !toEnable.isEmpty {
                    MenuService.shared.enableSections(restaurantId: rid, catalogItems: toEnable, completion: { e in
                        if let e = e {
                            errorMessage = "Error guardando secciones: \(e.localizedDescription)"
                            showErrorToast = true
                            isSavingAll = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { showErrorToast = false }
                        } else {
                            enableCompletion(nil)
                        }
                    })
                } else {
                    enableCompletion(nil)
                }
            }) {
                Text(isSavingAll ? "Guardando…" : "Guardar")
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var enableSectionsSheet: some View {
        NavigationView {
            List {
                ForEach(catalogItems, id: \.id) { item in
                    HStack {
                        Text(item.name).foregroundColor(.white)
                        Spacer()
                        let isOn = selectedCatalogIds.contains(item.id)
                        Button(action: {
                            if isOn { selectedCatalogIds.remove(item.id) } else { selectedCatalogIds.insert(item.id) }
                        }) {
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isOn ? .green : .white.opacity(0.6))
                        }
                    }
                    .listRowBackground(Color.black)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationBarTitle("Secciones del catálogo", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { showEnableSections = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSavingSections ? "Guardando…" : "Guardar") {
                        guard !isSavingSections else { return }
                        isSavingSections = true
                        let picked = catalogItems.filter { selectedCatalogIds.contains($0.id) }
                        tabs = ["Todo"] + picked.map { $0.name }
                        MenuService.shared.enableSections(restaurantId: effectiveRestaurantId, catalogItems: picked) { e in
                            if let e = e {
                                errorMessage = "Error guardando secciones: \(e.localizedDescription)"
                                showErrorToast = true
                                isSavingSections = false
                                return
                            }
                            MenuService.shared.listEnabledSections(restaurantId: effectiveRestaurantId) { res in
                                if case .success(let secs) = res {
                                    sections = secs
                                    let names = secs.map { $0.name }
                                    tabs = ["Todo"] + names
                                }
                                isSavingSections = false
                                showEnableSections = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { showErrorToast = false }
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if isSavingSections {
                    HStack(spacing: 8) {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .green))
                        Text("Guardando secciones…").foregroundColor(.white).font(.caption)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 12)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var addItemSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nombre", text: $newItemName)
                    TextField("Descripción", text: $newItemDescription)
                    TextField("Precio", text: $newItemPrice)
                        .keyboardType(.decimalPad)
                    TextField("Imagen URL", text: $newItemImageUrl)
                    Toggle("Publicar ahora", isOn: $newItemPublish)
                }
                Section {
                    Picker("Sección", selection: $newItemSectionId) {
                        ForEach(sections, id: \.id) { s in
                            Text(s.name).tag(s.id)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationBarTitle("Nuevo plato", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { showAddItem = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        let price = Double(newItemPrice) ?? 0.0
                        let img = newItemImageUrl.isEmpty ? [] : [newItemImageUrl]
                        let secId = newItemSectionId.isEmpty ? sections.first?.id ?? "" : newItemSectionId
                        MenuService.shared.createMenuItem(restaurantId: effectiveRestaurantId, sectionId: secId, name: newItemName, description: newItemDescription, price: price, currency: "USD", imageUrls: img, categoryCanonical: sections.first(where: { $0.id == secId })?.id, tags: [], isPublished: newItemPublish) { res in
                            if case .success(let item) = res {
                                let ui = UIItem(title: item.name, url: item.imageUrls.first ?? "", itemId: item.id)
                                let secName = sections.first(where: { $0.id == item.sectionId })?.name ?? "Otros"
                                menuData[secName, default: []].append(ui)
                                newItemName = ""
                                newItemDescription = ""
                                newItemPrice = ""
                                newItemImageUrl = ""
                                newItemSectionId = ""
                                newItemPublish = true
                                showAddItem = false
                            } else if case .failure(let e) = res {
                                errorMessage = "Error creando plato: \(e.localizedDescription)"
                                showErrorToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { showErrorToast = false }
                            }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private struct PriceFrameKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
    }
}
