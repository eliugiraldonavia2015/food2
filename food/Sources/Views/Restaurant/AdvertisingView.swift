import SwiftUI
import SDWebImageSwiftUI

struct AdvertisingView: View {
    var onMenuTap: () -> Void
    
    // MARK: - State
    @State private var selectedTab = 0 // 0: Activas, 1: Historial
    @State private var showCreateCampaign = false
    
    // Animation States
    @State private var animateContent = false
    @State private var animateCharts = false
    
    // Colors
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    var body: some View {
        ZStack {
            bgGray.ignoresSafeArea()
            
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
                        
                        // Campaigns List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("TUS CAMPAÑAS")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                Spacer()
                                Button("Ver todas") { }
                                    .font(.caption.bold())
                                    .foregroundColor(brandPink)
                            }
                            .padding(.horizontal, 4)
                            
                            campaignList
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
                title: "Promo Tacos 2x1",
                budget: "$150.00 / día",
                total: "$1,240.00",
                status: "En curso",
                image: "fork.knife", // Placeholder system image
                color: Color.orange
            )
            
            campaignCard(
                title: "Banner Cena Romántica",
                budget: "$80.00 / día",
                total: "$560.00",
                status: "En curso",
                image: "wineglass.fill", // Placeholder system image
                color: Color.black
            )
        }
    }
    
    private func campaignCard(title: String, budget: String, total: String, status: String, image: String, color: Color) -> some View {
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
                        .foregroundColor(brandPink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(brandPink.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text("Presupuesto: \(budget)")
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
                    
                    Button(action: {}) {
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
                Button("Configurar Pago") { }
                    .font(.caption.bold())
                    .foregroundColor(brandPink)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}
