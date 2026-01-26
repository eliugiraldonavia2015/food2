import SwiftUI

struct EfficiencyMetricsView: View {
    var onMenuTap: () -> Void
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    // Animation State
    @State private var animateGraph: Bool = false
    @State private var animateList: Bool = false
    
    // Navigation State
    enum ActiveSheet: Identifiable {
        case ticketPromedio
        case totalOrders
        case profitMargin
        case premiumReports
        case premiumStatus
        
        var id: Int {
            hashValue
        }
    }
    
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Average Time Card
                    averageTimeCard
                    
                    // Quick Stats Section
                    quickStatsSection
                    
                    // Top Branches Section
                    topBranchesSection
                    
                    // Incidents Section
                    incidentsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 16)
            }
        }
        .background(bgGray.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animateGraph = true
            }
            withAnimation(.spring().delay(0.3)) {
                animateList = true
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .ticketPromedio:
                TicketPromedioView()
            case .totalOrders:
                TotalOrdersView()
            case .profitMargin:
                ProfitMarginView()
            case .premiumReports:
                PremiumReportsView()
            case .premiumStatus:
                PremiumStatusView()
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("Métricas de Eficiencia")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(bgGray)
    }
    
    // MARK: - Average Time Card
    private var averageTimeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TIEMPO PROMEDIO")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("18.4")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.black)
                        Text("min")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.down")
                            Text("12%")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(brandPink.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "stopwatch.fill")
                            .foregroundColor(brandPink)
                            .font(.title3)
                    )
            }
            
            // Graph
            ZStack(alignment: .bottom) {
                // Gradient Fill
                MetricsGraphShape()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [brandPink.opacity(0.2), brandPink.opacity(0.0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
                    .clipShape(Rectangle())
                
                // Line Stroke
                MetricsGraphShape()
                    .trim(from: 0, to: animateGraph ? 1 : 0)
                    .stroke(brandPink, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(height: 120)
            }
            .overlay(
                HStack {
                    Text("08:00")
                    Spacer()
                    Text("12:00")
                    Spacer()
                    Text("16:00")
                    Spacer()
                    Text("20:00")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .offset(y: 20)
                , alignment: .bottom
            )
            .padding(.bottom, 20)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Stats")
                    .font(.title3.bold())
                    .foregroundColor(.black)
                Spacer()
                Button("VER TODO") { }
                    .font(.caption.bold())
                    .foregroundColor(brandPink)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Button(action: { activeSheet = .ticketPromedio }) {
                        quickStatsCard(icon: "doc.text", title: "TICKET PROMEDIO", value: "$345", trend: "+5.2%", trendColor: .green)
                    }
                    Button(action: { activeSheet = .totalOrders }) {
                        quickStatsCard(icon: "bag.fill", title: "ÓRDENES TOTALES", value: "892", trend: "+8.1%", trendColor: .green)
                    }
                    Button(action: { activeSheet = .profitMargin }) {
                        quickStatsCard(icon: "percent", title: "MARGEN DE UTILIDAD", value: "24%", trend: "-1.5%", trendColor: .orange)
                    }
                    Button(action: { activeSheet = .premiumReports }) {
                        quickStatsCard(icon: "chart.bar.fill", title: "REPORTES", value: "12", trend: "+3.0%", trendColor: .green, isPremium: true)
                    }
                    Button(action: { activeSheet = .premiumStatus }) {
                        quickStatsCard(icon: "checkmark.circle.fill", title: "ESTADO", value: "ACTIVO", trend: "0%", trendColor: .gray, isPremium: true)
                    }
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(animateList ? 1 : 0)
            .offset(y: animateList ? 0 : 20)
        }
    }
    
    private func quickStatsCard(icon: String, title: String, value: String, trend: String, trendColor: Color, isPremium: Bool = false) -> some View {
        let goldColor = Color(red: 1.0, green: 0.84, blue: 0.0)
        
        return ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Circle()
                    .fill(isPremium ? goldColor.opacity(0.1) : brandPink.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(isPremium ? goldColor : brandPink)
                            .font(.title3)
                    )
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                HStack(spacing: 2) {
                    Image(systemName: trend.starts(with: "+") ? "arrow.up" : trend.starts(with: "-") ? "arrow.down" : "minus")
                        .font(.caption2)
                    Text(trend)
                        .font(.caption2.bold())
                }
                .foregroundColor(trendColor)
            }
            .padding(16)
            .frame(width: 140)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isPremium ? goldColor : Color.clear, lineWidth: 1)
            )
            .shadow(color: isPremium ? goldColor.opacity(0.2) : .black.opacity(0.03), radius: isPremium ? 8 : 5, x: 0, y: isPremium ? 4 : 2)
            
            if isPremium {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundColor(goldColor)
                    .padding(10)
            }
        }
    }

    // MARK: - Top Branches Section
    private var topBranchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Sucursales hoy")
                    .font(.title3.bold())
                    .foregroundColor(.black)
                Spacer()
                Text("En tiempo real")
                    .font(.caption.bold())
                    .foregroundColor(brandPink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(brandPink.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                branchRankingRow(rank: 1, name: "Sucursal Condesa", completed: 142, efficiency: 98, color: Color(red: 255/255, green: 248/255, blue: 225/255), rankColor: Color(red: 255/255, green: 215/255, blue: 0/255))
                branchRankingRow(rank: 2, name: "Sucursal Polanco", completed: 128, efficiency: 92, color: Color(red: 245/255, green: 247/255, blue: 250/255), rankColor: Color.gray.opacity(0.5))
                branchRankingRow(rank: 3, name: "Sucursal Roma", completed: 95, efficiency: 89, color: Color(red: 255/255, green: 243/255, blue: 235/255), rankColor: Color.orange.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .opacity(animateList ? 1 : 0)
            .offset(y: animateList ? 0 : 20)
        }
    }
    
    private func branchRankingRow(rank: Int, name: String, completed: Int, efficiency: Int, color: Color, rankColor: Color) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(rank)")
                        .font(.headline.bold())
                        .foregroundColor(rankColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Text("\(completed) pedidos completados")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(efficiency)% efec.")
                    .font(.subheadline.bold())
                    .foregroundColor(brandPink)
                
                // Progress Bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 4)
                    Capsule()
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [Color.green, Color.yellow]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 60 * (CGFloat(efficiency) / 100), height: 4)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Incidents Section
    private var incidentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Incidencias recientes")
                    .font(.title3.bold())
                    .foregroundColor(.black)
                Spacer()
                Button("Ver todas") { }
                    .font(.subheadline.bold())
                    .foregroundColor(brandPink)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Critical Incident Card
                HStack(alignment: .top, spacing: 16) {
                    Rectangle()
                        .fill(brandPink)
                        .frame(width: 4)
                        .cornerRadius(2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(brandPink)
                            Text("Retraso crítico en Polanco")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                            Spacer()
                            Text("10 min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("Pedido #4912 excede tiempo límite de preparación (+15 min).")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                Text("Contactar gerente")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(brandPink)
                                    .cornerRadius(20)
                            }
                            
                            Button(action: {}) {
                                Text("Ignorar")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                // Warning Card
                HStack(alignment: .top, spacing: 16) {
                    Rectangle()
                        .fill(brandPink.opacity(0.5))
                        .frame(width: 4)
                        .cornerRadius(2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bicycle")
                                .foregroundColor(brandPink.opacity(0.8))
                            Text("Sin repartidores en Santa Fe")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                            Spacer()
                            Text("45 min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("Alta demanda en la zona. 4 pedidos están esperando recolecta por más de 10 min.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 20)
            .opacity(animateList ? 1 : 0)
            .offset(y: animateList ? 0 : 20)
        }
    }
}

// MARK: - Graph Shape
struct MetricsGraphShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Start
        path.move(to: CGPoint(x: 0, y: height * 0.8))
        
        // Curve points
        path.addCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.4),
            control1: CGPoint(x: width * 0.1, y: height * 0.7),
            control2: CGPoint(x: width * 0.2, y: height * 0.5)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.6),
            control1: CGPoint(x: width * 0.5, y: height * 0.35),
            control2: CGPoint(x: width * 0.6, y: height * 0.65)
        )
        
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.2),
            control1: CGPoint(x: width * 0.85, y: height * 0.5),
            control2: CGPoint(x: width * 0.9, y: height * 0.3)
        )
        
        return path
    }
}
