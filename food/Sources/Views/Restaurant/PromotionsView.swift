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
                        
                        statsOverview
                        
                        filterTabs
                        
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
    
    private var statsOverview: some View {
        HStack(spacing: 12) {
            statCard(title: "Canjes Hoy", value: "24", icon: "ticket.fill", color: .orange)
            statCard(title: "Ingresos Promo", value: "$850", icon: "banknote.fill", color: .green)
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animate)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).foregroundColor(color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.black)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
    
    private var filterTabs: some View {
        HStack(spacing: 0) {
            tabButton(title: "Activas", index: 0)
            tabButton(title: "Programadas", index: 1)
            tabButton(title: "Finalizadas", index: 2)
        }
        .padding(4)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5)
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animate)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { withAnimation { selectedTab = index } }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedTab == index ? brandPink : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == index ? brandPink.opacity(0.1) : Color.clear)
                .cornerRadius(8)
        }
    }
    
    private var promotionsList: some View {
        VStack(spacing: 16) {
            if selectedTab == 0 {
                promoCard(
                    title: "2x1 en Hamburguesas",
                    type: "Descuento",
                    date: "Vence: 15 Nov",
                    stats: "142 canjes • $2,100 ventas",
                    status: "Activa",
                    statusColor: .green,
                    icon: "tag.fill",
                    color: .orange
                )
                
                promoCard(
                    title: "Envío Gratis",
                    type: "Envío",
                    date: "Vence: 30 Nov",
                    stats: "89 canjes • $0 ventas directas",
                    status: "Activa",
                    statusColor: .green,
                    icon: "bicycle",
                    color: .blue
                )
            } else if selectedTab == 1 {
                promoCard(
                    title: "Black Friday -30%",
                    type: "Descuento Global",
                    date: "Inicia: 24 Nov",
                    stats: "Programada para 24 horas",
                    status: "Programada",
                    statusColor: .orange,
                    icon: "percent",
                    color: .purple
                )
            } else {
                promoCard(
                    title: "Promo Halloween",
                    type: "Regalo",
                    date: "Finalizó: 31 Oct",
                    stats: "320 canjes • $4,500 ventas",
                    status: "Finalizada",
                    statusColor: .gray,
                    icon: "gift.fill",
                    color: brandPink
                )
            }
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animate)
    }
    
    private func promoCard(title: String, type: String, date: String, stats: String, status: String, statusColor: Color, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: icon).font(.title3).foregroundColor(color))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    
                    Text(type)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.1))
                        .foregroundColor(color)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(status)
                    .font(.caption.bold())
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date)
                        .font(.caption.bold())
                        .foregroundColor(.black)
                    Text(stats)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Gestionar")
                        .font(.subheadline.bold())
                        .foregroundColor(brandPink)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}
