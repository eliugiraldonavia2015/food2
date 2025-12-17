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
    private struct UIItem: Identifiable { let id = UUID(); let title: String; let url: String }
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
            MenuService.shared.listEnabledSections(restaurantId: restaurantId) { res in
                if case .success(let secs) = res {
                    let names = secs.map { $0.name }
                    tabs = ["Todo"] + names
                    MenuService.shared.listMenuItems(restaurantId: restaurantId, publishedOnly: false) { itemsRes in
                        if case .success(let items) = itemsRes {
                            var grouped: [String: [UIItem]] = [:]
                            for it in items {
                                let ui = UIItem(title: it.name, url: it.imageUrls.first ?? "")
                                let secName = secs.first(where: { $0.id == it.sectionId })?.name ?? "Otros"
                                grouped[secName, default: []].append(ui)
                            }
                            menuData = grouped
                        }
                    }
                }
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
            section("Todo", items: allItems)
            ForEach(tabs.filter { $0 != "Todo" }, id: \.self) { t in
                section(t, items: menuData[t] ?? [])
            }
        }
    }

    private func section(_ title: String, items: [UIItem]) -> some View {
        VStack(spacing: 12) {
            sectionTitle(title)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { it in
                        optionDealCard(title: it.title, url: it.url, merchant: restaurantName, time: String(format: "%.0f min", (distanceKm ?? 48)))
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func optionDealCard(title: String, url: String, merchant: String, time: String) -> some View {
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
            }
            .padding(.leading, 12)
            .padding(.trailing, 26)
            .padding(.top, 8)
            Spacer()
        }
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
                    Button(action: { isEditingInfo = false }) {
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
            Button(action: {}) {
                Text("Guardar")
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

    private struct PriceFrameKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
    }
}
