import SwiftUI
import SDWebImageSwiftUI

struct RestaurantDashboardView: View {
    let bottomInset: CGFloat
    @State private var selectedLocation: String = "Todos"
    @State private var selectedRange: String = "Hoy"
    @State private var showLocationPicker = false
    @State private var showRangePicker = false
    @State private var selectedCity: DemandMapView.City = .guayaquil
    @State private var showCityPicker = false
    private let locations: [String] = ["Todos", "Sucursal Centro", "Condesa", "Roma", "Polanco"]
    private let ranges: [String] = ["Hoy", "Semana", "Mes", "Personalizado"]

    private func header() -> some View {
        HStack(spacing: 10) {
            Text("Panel Restaurante")
                .foregroundColor(.white)
                .font(.headline.weight(.bold))
            Spacer()
            filterPill(icon: "mappin.and.ellipse", text: selectedLocation) { showLocationPicker.toggle() }
            filterPill(icon: "calendar", text: selectedRange) { showRangePicker.toggle() }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.white)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer()
        }
    }

    private func filterPill(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.green)
                Text(text)
                    .foregroundColor(.white)
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.down").foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(minHeight: 32)
        }
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private func kpiCard(title: String, value: String, delta: String, positive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundColor(.white.opacity(0.9)).font(.caption)
            Text(value).foregroundColor(.white).font(.title2.bold())
            HStack(spacing: 6) {
                Image(systemName: positive ? "arrow.up.right" : "arrow.down.right").foregroundColor(positive ? .green : .red)
                Text(delta).foregroundColor(positive ? .green : .red).font(.caption.bold())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var kpiGrid: some View {
        VStack(spacing: 12) {
            sectionTitle("Indicadores")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                kpiCard(title: "Ingresos", value: "$12,450", delta: "+8% vs período", positive: true)
                kpiCard(title: "Órdenes activas", value: "24", delta: "+3 en 30m", positive: true)
                kpiCard(title: "Prep. promedio", value: "14m", delta: "-2m vs ayer", positive: true)
                kpiCard(title: "Cancelaciones", value: "1.8%", delta: "+0.3%", positive: false)
            }
        }
    }

    private enum OrderState: String, CaseIterable { case pendiente = "Pendiente", enCocina = "En cocina", listo = "Listo", enEntrega = "En entrega", despachado = "Despachado" }
    private struct OrderItem: Identifiable { let id = UUID(); let title: String; let state: OrderState; let time: String; let type: String; let branch: String }
    @State private var expandedStates: Set<OrderState> = []
    private let branches: [String] = ["Centro", "Condesa", "Roma", "Polanco"]
    private func makeOrders(for state: OrderState) -> [OrderItem] {
        (0..<15).map { i in
            let b = branches[i % branches.count]
            let name = ["Combo Burger", "Sushi Box", "Enchiladas", "Pasta Trufa", "Dragon Roll", "Smash Burger", "Taco Pack"][i % 7]
            let typ = ["Delivery", "Para llevar", "En salón"][i % 3]
            let t = "\(max(1, (i % 12) + 1))m"
            return .init(title: "#A\(1240 + i) • \(name)", state: state, time: t, type: typ, branch: b)
        }
    }

    private func orderRow(_ it: OrderItem) -> some View {
        HStack(spacing: 12) {
            Circle().fill(colorForState(it.state).opacity(0.2)).frame(width: 36, height: 36).overlay(Image(systemName: iconForState(it.state)).foregroundColor(colorForState(it.state)))
            VStack(alignment: .leading, spacing: 4) {
                Text(it.title).foregroundColor(.white).font(.subheadline.bold()).lineLimit(1)
                HStack(spacing: 8) {
                    Text(it.state.rawValue).foregroundColor(colorForState(it.state)).font(.caption.bold()).lineLimit(1)
                    Text("•").foregroundColor(.white.opacity(0.6))
                    Text(it.type).foregroundColor(.white.opacity(0.85)).font(.caption).lineLimit(1)
                    Text("•").foregroundColor(.white.opacity(0.6))
                    Text(it.branch).foregroundColor(.white.opacity(0.85)).font(.caption).lineLimit(1)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "timer").foregroundColor(.white.opacity(0.8))
                Text(it.time).foregroundColor(.white).font(.caption.bold())
            }
        }
        .padding()
        .frame(height: 72)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForState(_ s: OrderState) -> Color {
        switch s {
        case .pendiente: return .orange
        case .enCocina: return .green
        case .listo: return .blue
        case .enEntrega: return .purple
        case .despachado: return .gray
        }
    }

    private func iconForState(_ s: OrderState) -> String {
        switch s {
        case .pendiente: return "fork.knife"
        case .enCocina: return "fork.knife"
        case .listo: return "bag.fill"
        case .enEntrega: return "bicycle"
        case .despachado: return "checkmark.circle.fill"
        }
    }

    private func iconForType(_ t: String) -> String {
        switch t {
        case "Delivery": return "bicycle"
        case "Para llevar": return "bag.fill"
        case "En salón": return "fork.knife"
        default: return "bag"
        }
    }

    private func stateSection(_ state: OrderState) -> some View {
        let items = makeOrders(for: state)
        let isOpen = Binding<Bool>(
            get: { expandedStates.contains(state) },
            set: { v in withAnimation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2)) { if v { expandedStates.insert(state) } else { expandedStates.remove(state) } } }
        )
        return VStack(spacing: 8) {
            DisclosureGroup(isExpanded: isOpen) {
                VStack(spacing: 8) {
                    ForEach(items) { item in orderRow(item) }
                }
            } label: {
                HStack {
                    Text(emojiForState(state))
                        .font(.subheadline)
                        .padding(.trailing, 6)
                    Text(state.rawValue).foregroundColor(.white).font(.subheadline.bold())
                    Spacer()
                    Text("\(items.count)").foregroundColor(.white.opacity(0.8)).font(.caption.bold())
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accentColor(.white)
        }
    }

    private func emojiForState(_ s: OrderState) -> String {
        switch s {
        case .pendiente: return "🍴"
        case .enCocina: return "🍽️"
        case .listo: return "🛍️"
        case .enEntrega: return "🚴"
        case .despachado: return "✅"
        }
    }

    private var ordersNow: some View {
        VStack(spacing: 12) {
            sectionTitle("Órdenes en tiempo real")
            ForEach(OrderState.allCases, id: \.self) { s in stateSection(s) }
        }
    }

    private struct BranchPerf: Identifiable { let id = UUID(); let name: String; let orders: Int; let revenue: String; let avgTicket: String; let prep: String; let trendUp: Bool }
    private var branchItems: [BranchPerf] {
        [
            .init(name: "Centro", orders: 128, revenue: "$6,230", avgTicket: "$48.7", prep: "13m", trendUp: true),
            .init(name: "Condesa", orders: 96, revenue: "$4,020", avgTicket: "$41.9", prep: "16m", trendUp: false),
            .init(name: "Roma", orders: 84, revenue: "$3,110", avgTicket: "$37.0", prep: "12m", trendUp: true),
            .init(name: "Polanco", orders: 72, revenue: "$2,890", avgTicket: "$40.1", prep: "15m", trendUp: true)
        ]
    }

    private func branchRow(_ b: BranchPerf) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(b.name).foregroundColor(.white).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.85)
                HStack(spacing: 10) {
                    pill("Órdenes", "\(b.orders)")
                    pill("Ingresos", b.revenue)
                    pill("Ticket", b.avgTicket)
                    pill("Prep.", b.prep)
                }
            }
            Spacer()
            Image(systemName: b.trendUp ? "arrow.up.right" : "arrow.down.right").foregroundColor(b.trendUp ? .green : .red)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func pill(_ title: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(title).foregroundColor(.white.opacity(0.8)).font(.caption).lineLimit(1).minimumScaleFactor(0.85)
            Text(value).foregroundColor(.green).font(.caption.bold()).lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private var branchPerformance: some View {
        VStack(spacing: 12) {
            sectionTitle("Rendimiento por local")
            ForEach(branchItems) { item in branchRow(item) }
        }
    }

    private struct DemandZone: Identifiable { let id = UUID(); let name: String; let intensity: Double }
    private var zones: [DemandZone] {
        [
            .init(name: "Centro", intensity: 0.9),
            .init(name: "Condesa", intensity: 0.7),
            .init(name: "Roma", intensity: 0.5),
            .init(name: "Polanco", intensity: 0.8),
            .init(name: "Nápoles", intensity: 0.6),
            .init(name: "Del Valle", intensity: 0.4)
        ]
    }
    private func colorForIntensity(_ v: Double) -> Color {
        if v >= 0.75 { return .green }
        if v >= 0.5 { return .orange }
        return .red
    }
    private var demandMap: some View {
        VStack(spacing: 12) {
            sectionTitle("Mapa de demanda")
            HStack(spacing: 8) {
                filterPill(icon: "mappin", text: selectedCity.rawValue) { showCityPicker.toggle() }
                Spacer()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06))
                DemandMapView(city: selectedCity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(height: 220)
            HStack(spacing: 12) {
                Circle().fill(Color.green.opacity(0.25)).frame(width: 14, height: 14)
                Text("Alta demanda").foregroundColor(.white).font(.caption)
                Circle().fill(Color.orange.opacity(0.25)).frame(width: 14, height: 14)
                Text("Media").foregroundColor(.white).font(.caption)
                Circle().fill(Color.red.opacity(0.25)).frame(width: 14, height: 14)
                Text("Baja").foregroundColor(.white).font(.caption)
                Spacer()
            }
        }
    }

    private struct MenuItem: Identifiable { let id = UUID(); let name: String; let price: String; let stockLow: Bool; let rating: Double }
    private var menuItems: [MenuItem] {
        [
            .init(name: "Smash Burger", price: "$9.99", stockLow: false, rating: 4.8),
            .init(name: "Dragon Roll", price: "$12.50", stockLow: true, rating: 4.6),
            .init(name: "Pasta Trufa", price: "$14.00", stockLow: false, rating: 4.7),
            .init(name: "Enchiladas", price: "$8.50", stockLow: true, rating: 4.5)
        ]
    }

    private func menuRow(_ m: MenuItem) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "fork.knife").foregroundColor(.green))
            VStack(alignment: .leading, spacing: 4) {
                Text(m.name).foregroundColor(.white).font(.subheadline.bold()).lineLimit(1)
                HStack(spacing: 8) {
                    Text(m.price).foregroundColor(.green).font(.caption.bold())
                    Text("•").foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.1f", m.rating)).foregroundColor(.yellow).font(.caption.bold())
                }
            }
            Spacer()
            if m.stockLow { Text("Stock bajo").foregroundColor(.red).font(.caption.bold()).padding(.vertical, 6).padding(.horizontal, 10).background(Color.red.opacity(0.15)).clipShape(Capsule()) }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var menuStock: some View {
        VStack(spacing: 12) {
            sectionTitle("Menú y stock")
            ForEach(menuItems) { item in menuRow(item) }
        }
    }

    private struct ReviewItem: Identifiable { let id = UUID(); let user: String; let text: String; let rating: Int }
    private var reviewsItems: [ReviewItem] {
        (1...20).map { i in
            let users = ["@pizzalovers", "@sushimaster", "@foodie", "@burgerhouse", "@tacoselrey", "@saladbar", "@dessertheaven", "@tacoexpress", "@bbqkingdom", "@greendelight"]
            let texts = ["Excelente sabor y rapidez", "Muy bueno, porción podría ser mayor", "Tiempo de espera alto en pico", "Servicio amable", "Entrega puntual", "Salsa increíble", "Repetiría", "Buen precio", "Empaque mejorable", "Gran experiencia"]
            return .init(user: users[i % users.count], text: texts[i % texts.count], rating: (i % 5) + 1)
        }
    }

    private func reviewRow(_ r: ReviewItem) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.yellow.opacity(0.2)).frame(width: 36, height: 36).overlay(Image(systemName: "star.fill").foregroundColor(.yellow))
            VStack(alignment: .leading, spacing: 4) {
                Text(r.user).foregroundColor(.white).font(.subheadline.bold())
                Text(r.text).foregroundColor(.white.opacity(0.9)).font(.footnote)
            }
            Spacer()
            HStack(spacing: 2) {
                ForEach(0..<5) { i in Image(systemName: i < r.rating ? "star.fill" : "star").foregroundColor(.yellow) }
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var reviews: some View {
        VStack(spacing: 12) {
            sectionTitle("Clientes y reseñas")
            ForEach(reviewsItems) { item in reviewRow(item) }
        }
    }

    private struct StaffItem: Identifiable { let id = UUID(); let name: String; let role: String; let performance: String; let capacity: String }
    private var staffItems: [StaffItem] {
        [
            .init(name: "María", role: "Cocina", performance: "32 órdenes/h", capacity: "Alta"),
            .init(name: "Juan", role: "Empaque", performance: "27 órdenes/h", capacity: "Media"),
            .init(name: "Laura", role: "Delivery", performance: "12 rutas/h", capacity: "Media")
        ]
    }

    private func staffRow(_ s: StaffItem) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.green.opacity(0.2)).frame(width: 36, height: 36).overlay(Image(systemName: "person.fill").foregroundColor(.green))
            VStack(alignment: .leading, spacing: 4) {
                Text(s.name).foregroundColor(.white).font(.subheadline.bold())
                HStack(spacing: 8) {
                    Text(s.role).foregroundColor(.white.opacity(0.85)).font(.caption)
                    Text("•").foregroundColor(.white.opacity(0.6))
                    Text(s.performance).foregroundColor(.green).font(.caption.bold())
                }
            }
            Spacer()
            Text(s.capacity).foregroundColor(.white).font(.caption.bold()).padding(.vertical, 6).padding(.horizontal, 10).background(Color.white.opacity(0.08)).clipShape(Capsule())
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var teamShifts: some View {
        VStack(spacing: 12) {
            sectionTitle("Equipo y turnos")
            ForEach(staffItems) { item in staffRow(item) }
        }
    }

    private struct CampaignItem: Identifiable { let id = UUID(); let name: String; let conv: String; let revenue: String; let active: Bool }
    private var campaignItems: [CampaignItem] {
        [
            .init(name: "Promo Almuerzo", conv: "3.2%", revenue: "$1,230", active: true),
            .init(name: "Combo Cena", conv: "2.1%", revenue: "$890", active: true),
            .init(name: "Cupón Nuevo", conv: "0.9%", revenue: "$210", active: false)
        ]
    }

    private func campaignRow(_ c: CampaignItem) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.2)).frame(width: 48, height: 48).overlay(Image(systemName: "megaphone.fill").foregroundColor(.orange))
            VStack(alignment: .leading, spacing: 4) {
                Text(c.name).foregroundColor(.white).font(.subheadline.bold()).lineLimit(1)
                HStack(spacing: 8) {
                    Text("Conv.").foregroundColor(.white.opacity(0.8)).font(.caption)
                    Text(c.conv).foregroundColor(.green).font(.caption.bold())
                    Text("• Ingresos").foregroundColor(.white.opacity(0.8)).font(.caption)
                    Text(c.revenue).foregroundColor(.green).font(.caption.bold())
                }
            }
            Spacer()
            Text(c.active ? "Activa" : "Pausada").foregroundColor(c.active ? .green : .red).font(.caption.bold()).padding(.vertical, 6).padding(.horizontal, 10).background((c.active ? Color.green : Color.red).opacity(0.15)).clipShape(Capsule())
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var promotions: some View {
        VStack(spacing: 12) {
            sectionTitle("Promociones y marketing")
            ForEach(campaignItems) { item in campaignRow(item) }
        }
    }

    private struct AlertItem: Identifiable { let id = UUID(); let title: String; let detail: String; let severity: String }
    private var alertItems: [AlertItem] {
        [
            .init(title: "Stock bajo", detail: "Dragon Roll en 8 porciones", severity: "Alta"),
            .init(title: "SLA en riesgo", detail: "Condesa 19–21h", severity: "Media"),
            .init(title: "Reseña negativa", detail: "Tiempo de espera alto", severity: "Media")
        ]
    }

    private func alertRow(_ a: AlertItem) -> some View {
        HStack(spacing: 12) {
            Circle().fill(colorForSeverity(a.severity).opacity(0.2)).frame(width: 36, height: 36).overlay(Image(systemName: iconForAlert(a.title)).foregroundColor(colorForSeverity(a.severity)))
            VStack(alignment: .leading, spacing: 4) {
                Text(a.title).foregroundColor(.white).font(.subheadline.bold())
                Text(a.detail).foregroundColor(.white.opacity(0.9)).font(.footnote)
            }
            Spacer()
            Text(a.severity).foregroundColor(colorForSeverity(a.severity)).font(.caption.bold())
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForSeverity(_ s: String) -> Color {
        switch s {
        case "Alta": return .red
        case "Media": return .orange
        default: return .white
        }
    }

    private func iconForAlert(_ t: String) -> String {
        if t == "Stock bajo" { return "exclamationmark.triangle" }
        if t == "SLA en riesgo" { return "timer" }
        return "bell"
    }

    private var alerts: some View {
        VStack(spacing: 12) {
            sectionTitle("Alertas y notificaciones")
            ForEach(alertItems) { item in alertRow(item) }
        }
    }

    private var pickersOverlay: some View {
        ZStack(alignment: .top) {
            if showLocationPicker { pickerSheet(title: "Selecciona local", items: locations, selected: $selectedLocation, onClose: { showLocationPicker = false }) }
            if showRangePicker { pickerSheet(title: "Rango de tiempo", items: ranges, selected: $selectedRange, onClose: { showRangePicker = false }) }
            if showCityPicker { cityPicker }
        }
    }

    private var cityPicker: some View {
        let items = DemandMapView.City.allCases.map { $0.rawValue }
        return VStack(spacing: 12) {
            Capsule().fill(Color.white.opacity(0.2)).frame(width: 48, height: 5).padding(.top, 8)
            Text("Selecciona ciudad").foregroundColor(.white).font(.headline.bold())
            VStack(spacing: 8) {
                ForEach(items, id: \.self) { it in
                    Button {
                        selectedCity = DemandMapView.City(rawValue: it) ?? .guayaquil
                        showCityPicker = false
                    } label: {
                        HStack {
                            Text(it).foregroundColor(.white).font(.subheadline)
                            Spacer()
                            if selectedCity.rawValue == it { Image(systemName: "checkmark").foregroundColor(.green) }
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            Button(action: { showCityPicker = false }) {
                Text("Cerrar").fontWeight(.semibold).frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.black.opacity(0.6).ignoresSafeArea())
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func pickerSheet(title: String, items: [String], selected: Binding<String>, onClose: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Capsule().fill(Color.white.opacity(0.2)).frame(width: 48, height: 5).padding(.top, 8)
            Text(title).foregroundColor(.white).font(.headline.bold())
            VStack(spacing: 8) {
                ForEach(items, id: \.self) { it in
                    Button {
                        selected.wrappedValue = it
                        onClose()
                    } label: {
                        HStack {
                            Text(it).foregroundColor(.white).font(.subheadline)
                            Spacer()
                            if selected.wrappedValue == it { Image(systemName: "checkmark").foregroundColor(.green) }
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            Button(action: onClose) {
                Text("Cerrar").fontWeight(.semibold).frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.black.opacity(0.6).ignoresSafeArea())
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    header()
                    kpiGrid
                    ordersNow
                    branchPerformance
                    demandMap
                    menuStock
                    teamShifts
                    promotions
                    alerts
                    reviews
                }
                .padding()
                .padding(.bottom, bottomInset)
            }
            .background(Color.black.ignoresSafeArea())
            pickersOverlay
        }
        .preferredColorScheme(.dark)
    }
}

