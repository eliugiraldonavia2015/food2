import SwiftUI
import SDWebImageSwiftUI

struct AdvertisingView: View {
    var onMenuTap: () -> Void
    
    // MARK: - State
    @State private var selectedTab = 0 // 0: Activas, 1: Historial
    @State private var showCreateCampaign = false
    
    // Navigation States
    @State private var showAllCampaigns = false
    @State private var showPaymentSettings = false
    @State private var selectedCampaignForStats: String? = nil
    
    // Animation States
    @State private var animateContent = false
    @State private var animateCharts = false
    
    // Colors
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    var body: some View {
        ZStack {
            bgGray.ignoresSafeArea()
            
            // Hidden Navigation Links
            NavigationLink(destination: AllCampaignsView(), isActive: $showAllCampaigns) { EmptyView() }
            NavigationLink(destination: PaymentSettingsView(), isActive: $showPaymentSettings) { EmptyView() }
            NavigationLink(destination: CampaignStatisticsView(campaignId: selectedCampaignForStats ?? ""), isActive: Binding(
                get: { selectedCampaignForStats != nil },
                set: { if !$0 { selectedCampaignForStats = nil } }
            )) { EmptyView() }
            
            VStack(spacing: 0) {
                // Header
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Tabs
                        customSegmentedControl
                            .padding(.top, 10)
                        
                        // Performance Cards
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RENDIMIENTO ACTUAL")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            performanceSection
                        }
                        
                        // Campaigns List (Active vs History)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(selectedTab == 0 ? "TUS CAMPAÑAS" : "HISTORIAL")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                Spacer()
                                Button("Ver todas") { showAllCampaigns = true }
                                    .font(.caption.bold())
                                    .foregroundColor(brandPink)
                            }
                            .padding(.horizontal, 4)
                            
                            if selectedTab == 0 {
                                campaignList
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                            } else {
                                historyList
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                        }
                        
                        // AI Suggestions Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SUGERENCIAS DE IA")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            aiSuggestionsList
                        }
                        
                        // Audience Reach Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ALCANCE POR AUDIENCIA")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            audienceReachCard
                        }
                        
                        // Upcoming Invoices Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRÓXIMAS FACTURAS")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            upcomingInvoiceCard
                        }
                        
                        // Download Report Button
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Descargar Reporte Mensual")
                            }
                            .font(.headline.bold())
                            .foregroundColor(brandPink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(brandPink.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.top, 10)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            
            // Floating/Fixed Bottom Button
            VStack {
                Spacer()
                Button(action: { showCreateCampaign = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Crear Nueva Campaña")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(brandPink)
                    .clipShape(Capsule())
                    .shadow(color: brandPink.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateCharts = true
            }
        }
    }
    
    // MARK: - Components
    
    private var header: some View {
        HStack {
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("Publicidad")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            Button(action: { withAnimation { selectedTab = 0 } }) {
                Text("Campañas Activas")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedTab == 0 ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == 0 ? Color.white : Color.clear)
                    .cornerRadius(12)
                    .shadow(color: selectedTab == 0 ? .black.opacity(0.05) : .clear, radius: 2, x: 0, y: 1)
            }
            
            Button(action: { withAnimation { selectedTab = 1 } }) {
                Text("Historial")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedTab == 1 ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == 1 ? Color.white : Color.clear)
                    .cornerRadius(12)
                    .shadow(color: selectedTab == 1 ? .black.opacity(0.05) : .clear, radius: 2, x: 0, y: 1)
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var performanceSection: some View {
        VStack(spacing: 16) {
            // Main Card (Impressions)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Impresiones")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("+12%")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text("12.4k")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                // Graph
                GeometryReader { geo in
                    Path { path in
                        let width = geo.size.width
                        let height = geo.size.height
                        
                        path.move(to: CGPoint(x: 0, y: height * 0.8))
                        path.addCurve(
                            to: CGPoint(x: width, y: height * 0.4),
                            control1: CGPoint(x: width * 0.4, y: height * 0.2),
                            control2: CGPoint(x: width * 0.6, y: height * 0.9)
                        )
                    }
                    .trim(from: 0, to: animateCharts ? 1 : 0)
                    .stroke(brandPink, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
                .frame(height: 50)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
            
            // Secondary Cards (Clicks, CTR)
            HStack(spacing: 16) {
                smallPerformanceCard(title: "Clicks", value: "842", graphY: 0.6)
                smallPerformanceCard(title: "CTR %", value: "6.8%", graphY: 0.4)
            }
        }
    }
    
    private func smallPerformanceCard(title: String, value: String, graphY: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.black)
            
            GeometryReader { geo in
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height * 0.8))
                    path.addCurve(
                        to: CGPoint(x: width, y: height * 0.5),
                        control1: CGPoint(x: width * 0.3, y: height * (1 - graphY)),
                        control2: CGPoint(x: width * 0.7, y: height)
                    )
                }
                .trim(from: 0, to: animateCharts ? 1 : 0)
                .stroke(brandPink, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 30)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var campaignList: some View {
        VStack(spacing: 16) {
            campaignCard(
                id: "1",
                title: "Promo Tacos 2x1",
                budget: "$150.00 / día",
                total: "$1,240.00",
                status: "En curso",
                statusColor: brandPink,
                image: "fork.knife",
                color: Color.orange
            )
            
            campaignCard(
                id: "2",
                title: "Banner Cena Romántica",
                budget: "$80.00 / día",
                total: "$560.00",
                status: "En curso",
                statusColor: brandPink,
                image: "wineglass.fill",
                color: Color.black
            )
        }
    }
    
    private var historyList: some View {
        VStack(spacing: 16) {
            campaignCard(
                id: "3",
                title: "Descuento Verano",
                budget: "Finalizado",
                total: "$2,100.00",
                status: "Finalizada",
                statusColor: .gray,
                image: "sun.max.fill",
                color: .yellow
            )
            
            campaignCard(
                id: "4",
                title: "Lanzamiento App",
                budget: "Finalizado",
                total: "$5,000.00",
                status: "Finalizada",
                statusColor: .gray,
                image: "iphone",
                color: .blue
            )
        }
    }
    
    private func campaignCard(id: String, title: String, budget: String, total: String, status: String, statusColor: Color, image: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: image)
                        .foregroundColor(.white)
                        .font(.title2)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.caption2.bold())
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text(status == "En curso" ? "Presupuesto: \(budget)" : "Gastado: \(total)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inversión total:")
                            .font(.caption2)
                            .foregroundColor(.black)
                        Text(total)
                            .font(.subheadline.bold())
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: { selectedCampaignForStats = id }) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Ver")
                                .font(.caption.bold())
                            Text("Estadísticas >")
                                .font(.caption.bold())
                        }
                        .foregroundColor(brandPink)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var aiSuggestionsList: some View {
        VStack(spacing: 16) {
            aiSuggestionCard(
                title: "Aumenta el presupuesto en horas pico",
                description: "Detectamos un incremento de interacción entre las 19:00 y 21:00. Un ajuste del 15% podría duplicar tus clicks.",
                actionText: "Aplicar cambio",
                icon: "chart.line.uptrend.xyaxis",
                color: Color.pink.opacity(0.1),
                iconColor: brandPink
            )
            
            aiSuggestionCard(
                title: "Nueva imagen para 'Promo Tacos'",
                description: "Las gráficas con fondos claros están rindiendo un 22% mejor este mes. Prueba actualizar tu material creativo.",
                actionText: "Subir imagen",
                icon: "photo.fill",
                color: Color.blue.opacity(0.1),
                iconColor: .blue
            )
        }
    }
    
    private func aiSuggestionCard(title: String, description: String, actionText: String, icon: String, color: Color, iconColor: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).foregroundColor(iconColor).font(.headline))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                
                Button(action: {}) {
                    Text(actionText)
                        .font(.caption.bold())
                        .foregroundColor(brandPink)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var audienceReachCard: some View {
        HStack(spacing: 24) {
            // Animated Donut Chart
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: animateCharts ? 0.45 : 0)
                    .stroke(brandPink, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: animateCharts ? 0.30 : 0)
                    .stroke(brandPink.opacity(0.6), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90 + (360 * 0.45) + 10)) // Offset + gap
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: animateCharts ? 0.25 : 0)
                    .stroke(brandPink.opacity(0.3), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90 + (360 * 0.75) + 20)) // Offset + gap
                    .frame(width: 100, height: 100)
                
                VStack(spacing: 2) {
                    Text("10.2k")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            
            // Legend
            VStack(alignment: .leading, spacing: 12) {
                audienceLegendItem(color: brandPink, label: "Gen Z", value: "45%")
                audienceLegendItem(color: brandPink.opacity(0.6), label: "Millennials", value: "30%")
                audienceLegendItem(color: brandPink.opacity(0.3), label: "Gen X", value: "25%")
            }
            Spacer()
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private func audienceLegendItem(color: Color, label: String, value: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.black)
        }
        .frame(minWidth: 140)
    }
    
    private var upcomingInvoiceCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CICLO DE FACTURACIÓN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    Text("01 Oct - 31 Oct, 2023")
                        .font(.subheadline.bold())
                        .foregroundColor(.black)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("MONTO ESTIMADO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    Text("$1,780.00")
                        .font(.title3.bold())
                        .foregroundColor(brandPink)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.gray)
                Text("Visa terminada en 4421")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Button(action: { showPaymentSettings = true }) {
                    Text("Configurar Pago")
                        .font(.caption.bold())
                        .foregroundColor(brandPink)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

// MARK: - New Sub-Views

struct AllCampaignsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    var body: some View {
        ZStack {
            Color(red: 249/255, green: 249/255, blue: 249/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                searchBar
                
                ScrollView {
                    VStack(spacing: 16) {
                        campaignItem(title: "Promo Tacos 2x1", status: "Activa", date: "Inicio: 12 Oct", amount: "$150/día")
                        campaignItem(title: "Banner Cena Romántica", status: "Activa", date: "Inicio: 10 Oct", amount: "$80/día")
                        campaignItem(title: "Descuento Verano", status: "Finalizada", date: "Finalizó: 30 Sep", amount: "$2,100 total", isActive: false)
                        campaignItem(title: "Lanzamiento App", status: "Finalizada", date: "Finalizó: 15 Ago", amount: "$5,000 total", isActive: false)
                        campaignItem(title: "Promo Día del Niño", status: "Finalizada", date: "Finalizó: 30 Abr", amount: "$1,200 total", isActive: false)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            Spacer()
            Text("Todas las Campañas")
                .font(.headline.bold())
            Spacer()
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Buscar campaña...", text: $searchText)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding()
    }
    
    func campaignItem(title: String, status: String, date: String, amount: String, isActive: Bool = true) -> some View {
        HStack {
            Circle()
                .fill(isActive ? brandPink.opacity(0.1) : Color.gray.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: isActive ? "megaphone.fill" : "archivebox.fill")
                        .foregroundColor(isActive ? brandPink : .gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                Text(status)
                    .font(.caption.bold())
                    .foregroundColor(isActive ? .green : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background((isActive ? Color.green : Color.gray).opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct CampaignStatisticsView: View {
    let campaignId: String
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let graphValues: [CGFloat] = [40, 60, 35, 80, 55, 90, 120]
    
    var body: some View {
        ZStack {
            Color(red: 249/255, green: 249/255, blue: 249/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: 24) {
                        titleSection
                        graphSection
                        statsGrid
                        actionButtons
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animate = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            Spacer()
            Text("Estadísticas")
                .font(.headline.bold())
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "square.and.arrow.up")
        }
        .padding()
        .background(Color.white)
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Promo Tacos 2x1")
                .font(.title2.bold())
                .foregroundColor(.black)
            Text("Campaña Activa • ID: #8492")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.top)
    }
    
    private var graphSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rendimiento (Últimos 7 días)")
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<7) { i in
                    barView(index: i)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    private func barView(index: Int) -> some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(index == 6 ? brandPink : brandPink.opacity(0.3))
                .frame(height: animate ? graphValues[index] : 0)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statBox(title: "Inversión", value: "$1,240", icon: "dollarsign.circle.fill", color: .green)
            statBox(title: "Clicks", value: "842", icon: "cursorarrow.click.2", color: .blue)
            statBox(title: "CPC", value: "$1.47", icon: "divide.circle", color: .orange)
            statBox(title: "Conversión", value: "3.2%", icon: "chart.bar.fill", color: .purple)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {}) {
                Text("Pausar Campaña")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Button(action: {}) {
                Text("Editar Presupuesto")
                    .fontWeight(.bold)
                    .foregroundColor(brandPink)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(brandPink, lineWidth: 1))
            }
        }
    }
    
    func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: icon).foregroundColor(color))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.black)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
}

struct PaymentSettingsView: View {
    @Environment(\.dismiss) var dismiss
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    var body: some View {
        ZStack {
            Color(red: 249/255, green: 249/255, blue: 249/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        cardsSection
                        billingSection
                        historySection
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            Spacer()
            Text("Configurar Pagos")
                .font(.headline.bold())
                .foregroundColor(.black)
            Spacer()
            Button("Guardar") { dismiss() }
                .font(.subheadline.bold())
                .foregroundColor(brandPink)
        }
        .padding()
        .background(Color.white)
    }
    
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MÉTODOS DE PAGO")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                cardRow(last4: "4421", brand: "Visa", isDefault: true)
                Divider()
                cardRow(last4: "8892", brand: "Mastercard", isDefault: false)
                Divider()
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(brandPink)
                        Text("Agregar nueva tarjeta")
                            .foregroundColor(brandPink)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5)
        }
    }
    
    private var billingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DATOS DE FACTURACIÓN")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                billingField(label: "Razón Social", value: "Tacos El Rey S.A. de C.V.")
                billingField(label: "RFC", value: "TRE190203H42")
                billingField(label: "Dirección Fiscal", value: "Av. Reforma 222, CDMX")
                billingField(label: "Correo", value: "facturas@tacoselrey.com")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5)
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HISTORIAL DE PAGOS")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                invoiceRow(date: "01 Oct 2023", amount: "$1,780.00", status: "Pagado")
                Divider()
                invoiceRow(date: "01 Sep 2023", amount: "$1,650.00", status: "Pagado")
                Divider()
                invoiceRow(date: "01 Ago 2023", amount: "$1,900.00", status: "Pagado")
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5)
        }
    }
    
    func cardRow(last4: String, brand: String, isDefault: Bool) -> some View {
        HStack {
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(.black)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(brand) •••• \(last4)")
                    .font(.body.bold())
                    .foregroundColor(.black)
                if isDefault {
                    Text("Predeterminada")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if isDefault {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(brandPink)
            }
        }
        .padding()
    }
    
    func billingField(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
        .font(.subheadline)
    }
    
    func invoiceRow(date: String, amount: String, status: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(date)
                    .font(.body.bold())
                    .foregroundColor(.black)
                Text(status)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            Spacer()
            Text(amount)
                .font(.subheadline)
                .foregroundColor(.gray)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
