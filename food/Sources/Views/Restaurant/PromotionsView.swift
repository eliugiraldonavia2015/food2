import SwiftUI

struct PromotionsView: View {
    var onMenuTap: () -> Void
    
    // MARK: - State
    @State private var animate = false
    @State private var selectedTab = 0 // 0: Activas, 1: Programadas, 2: Finalizadas
    
    // Colors
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    var body: some View {
        ZStack {
            bgGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        createPromoCard
                        
                        // New Sections
                        globalStatsSection
                        aiSuggestionsSection
                        templatesSection
                        
                        // Active Promotions Header
                        HStack {
                            Text("Tus Campañas")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                            Spacer()
                            filterTabs
                        }
                        .padding(.top, 10)
                        
                        promotionsList
                        
                        Spacer(minLength: 80)
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animate = true
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
            
            Text("Promociones")
                .font(.title3.bold())
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private var createPromoCard: some View {
        Button(action: {}) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Crear Nueva Promoción")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Text("Impulsa tus ventas con descuentos especiales")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                LinearGradient(colors: [brandPink, brandPink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(20)
            .shadow(color: brandPink.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .scaleEffect(animate ? 1 : 0.95)
        .opacity(animate ? 1 : 0)
    }
    
    // MARK: - Global Stats Section (New)
    private var globalStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resumen General")
                .font(.headline.bold())
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    detailedStatCard(title: "Ingresos Generados", value: "$12,450", change: "+15%", icon: "banknote.fill", color: .green)
                    detailedStatCard(title: "Retorno (ROI)", value: "320%", change: "+5%", icon: "chart.line.uptrend.xyaxis", color: .blue)
                    detailedStatCard(title: "Total Canjes", value: "1,240", change: "+12%", icon: "ticket.fill", color: .orange)
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 10) // Shadow space
            }
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animate)
    }
    
    private func detailedStatCard(title: String, value: String, change: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: icon).foregroundColor(color).font(.caption.bold()))
                Spacer()
                Text(change)
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.black)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(width: 160)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - AI Suggestions Section (New)
    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(brandPink)
                Text("Sugerencias de IA")
                    .font(.headline.bold())
                    .foregroundColor(.black)
            }
            
            VStack(spacing: 12) {
                aiSuggestionCard(
                    title: "Impulsa el Martes",
                    description: "Tus ventas bajan un 20% los martes. Lanza un 2x1 en Tacos para recuperar tráfico.",
                    action: "Crear 2x1"
                )
                aiSuggestionCard(
                    title: "Recupera Clientes",
                    description: "150 clientes no han pedido en 30 días. Envíales un cupón de $50.",
                    action: "Enviar Cupón"
                )
            }
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animate)
    }
    
    private func aiSuggestionCard(title: String, description: String, action: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text(action)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(brandPink)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandPink.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Templates Section (New)
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plantillas Rápidas")
                .font(.headline.bold())
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    templateCard(title: "2x1", icon: "person.2.fill", color: .orange)
                    templateCard(title: "Envío Gratis", icon: "bicycle", color: .blue)
                    templateCard(title: "Descuento %", icon: "percent", color: .purple)
                    templateCard(title: "Regalo", icon: "gift.fill", color: .red)
                    templateCard(title: "Happy Hour", icon: "clock.fill", color: .green)
                }
                .padding(.horizontal, 2)
            }
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.25), value: animate)
    }
    
    private func templateCard(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: icon).foregroundColor(color))
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.black)
        }
        .frame(width: 90, height: 90)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Active Promotions List (Redesigned)
    private var promotionsList: some View {
        VStack(spacing: 16) {
            if selectedTab == 0 {
                detailedPromoCard(
                    title: "2x1 en Hamburguesas",
                    date: "Vence: 15 Nov",
                    revenue: "$2,100",
                    roi: "450%",
                    redemptions: "142",
                    status: "Activa",
                    statusColor: .green,
                    color: .orange,
                    icon: "tag.fill"
                )
                
                detailedPromoCard(
                    title: "Envío Gratis > $200",
                    date: "Vence: 30 Nov",
                    revenue: "$5,400",
                    roi: "120%",
                    redemptions: "89",
                    status: "Activa",
                    statusColor: .green,
                    color: .blue,
                    icon: "bicycle"
                )
            } else if selectedTab == 1 {
                detailedPromoCard(
                    title: "Black Friday -30%",
                    date: "Inicia: 24 Nov",
                    revenue: "$0",
                    roi: "0%",
                    redemptions: "0",
                    status: "Programada",
                    statusColor: .orange,
                    color: .purple,
                    icon: "percent"
                )
            } else {
                detailedPromoCard(
                    title: "Promo Halloween",
                    date: "Finalizó: 31 Oct",
                    revenue: "$4,500",
                    roi: "210%",
                    redemptions: "320",
                    status: "Finalizada",
                    statusColor: .gray,
                    color: brandPink,
                    icon: "gift.fill"
                )
            }
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animate)
    }
    
    private func detailedPromoCard(title: String, date: String, revenue: String, roi: String, redemptions: String, status: String, statusColor: Color, color: Color, icon: String) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: icon).font(.title3).foregroundColor(color))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(status)
                    .font(.caption.bold())
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(16)
            
            Divider()
            
            // Metrics Grid
            HStack(spacing: 0) {
                metricCell(label: "Ingresos", value: revenue)
                Divider().frame(height: 30)
                metricCell(label: "ROI", value: roi)
                Divider().frame(height: 30)
                metricCell(label: "Canjes", value: redemptions)
            }
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.02))
            
            Divider()
            
            // Action
            Button(action: {}) {
                Text("Ver Detalles Completos")
                    .font(.subheadline.bold())
                    .foregroundColor(brandPink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private func metricCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.black)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var filterTabs: some View {
        HStack(spacing: 0) {
            tabButton(title: "Activas", index: 0)
            tabButton(title: "Futuras", index: 1)
            tabButton(title: "Pasadas", index: 2)
        }
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { withAnimation { selectedTab = index } }) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(selectedTab == index ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTab == index ? brandPink : Color.clear)
                .cornerRadius(6)
                .padding(2)
        }
    }
}
