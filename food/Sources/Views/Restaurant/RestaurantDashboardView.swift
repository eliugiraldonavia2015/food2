import SwiftUI
import SDWebImageSwiftUI

private struct FilterBarFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

struct RestaurantDashboardView: View {
    var bottomInset: CGFloat = 0
    
    // MARK: - State
    @State private var selectedRange: String = "Hoy"
    @State private var selectedMenu: String = "Tablero"
    @State private var showMenu = false
    @State private var showUploadVideo = false
    
    // Animation States
    @State private var animateContent = false
    @State private var animateGraph = false
    @Namespace private var animation
    
    // Colors based on user request ("fucsia de la app desvanecido")
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    // Mock Data Preserved
    private let ranges: [String] = ["Hoy", "Ayer", "7 días", "30 días"]
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Main Content
            Group {
                if selectedMenu == "Pedidos" {
                    NavigationView {
                        OrdersManagementView(onMenuTap: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } })
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                } else if selectedMenu == "Reportes" {
                    NavigationView {
                        EfficiencyMetricsView(onMenuTap: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } })
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                } else if selectedMenu == "Socios" {
                    NavigationView {
                        PartnersView(onMenuTap: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } })
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                } else if selectedMenu == "Menú" {
                    NavigationView {
                        RestaurantEditableMenuView(onMenuTap: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } })
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                } else if selectedMenu == "Publicidad en la app" {
                    NavigationView {
                        AdvertisingView(onMenuTap: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } })
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                } else if selectedMenu == "Evaluación y opiniones" {
                    NavigationView {
                        ReviewsView(onMenuTap: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } })
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                } else if selectedMenu == "Promociones" {
                    NavigationView {
                        PromotionsView(onMenuTap: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } })
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                } else if selectedMenu == "Horarios" {
                    NavigationView {
                        SchedulesView(onMenuTap: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } })
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                } else {
                    mainContent
                }
            }
                .offset(x: showMenu ? 280 : 0)
                .disabled(showMenu)
                .scaleEffect(showMenu ? 0.9 : 1)
                .shadow(color: .black.opacity(showMenu ? 0.1 : 0), radius: 20, x: -10, y: 0)
                .rotation3DEffect(.degrees(showMenu ? -10 : 0), axis: (x: 0, y: 1, z: 0))
            
            // Side Menu
            if showMenu {
                SideMenuView(showMenu: $showMenu, selectedMenu: $selectedMenu, brandPink: brandPink)
                    .transition(.move(edge: .leading))
                    .zIndex(2)
            }
            
            // Darken overlay when menu is open
            if showMenu {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { showMenu = false } }
                    .zIndex(1)
            }
        }
        .background(bgGray.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: showMenu)
        .onAppear {
            startAnimations()
        }
        .onChange(of: selectedMenu) { newValue in
            if newValue == "Tablero" {
                animateContent = false
                animateGraph = false
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateContent = true
        }
        withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
            animateGraph = true
        }
    }
    
    // MARK: - Main Content Views
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { withAnimation(.spring()) { showMenu.toggle() } }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
                Spacer()
                Text("Tablero")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                
                // Profile Avatar Placeholder
                Circle()
                    .fill(Color.brown)
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white.opacity(0.8)))
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(bgGray)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Greeting Section
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 0) {
                            Text("Hola, ")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.black)
                            Text("Burger King")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(brandPink)
                            Text(" 👋")
                                .font(.system(size: 26))
                        }
                        Text("Aquí tienes tu resumen de hoy.")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1 : 0)
                    
                    // Time Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ranges, id: \.self) { range in
                                Button(action: { selectedRange = range }) {
                                    Text(range)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(selectedRange == range ? .white : .gray)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(selectedRange == range ? brandPink : Color.white)
                                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: animateContent)
                    
                    // KPI Cards
                    HStack(spacing: 16) {
                        kpiCardNew(title: "Pedidos", value: "124", badge: "+12%", icon: "bag.fill")
                        kpiCardNew(title: "Ingresos", value: "$1,240", badge: "+5%", icon: "banknote.fill")
                    }
                    .padding(.horizontal, 20)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                    
                    // Graph Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tendencia de Pedidos")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Actividad en vivo")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Text("Alta")
                            }
                            .font(.caption.bold())
                            .foregroundColor(brandPink)
                        }
                        
                        // Wave Graph Mockup
                        WaveShape()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [brandPink.opacity(0.4), brandPink.opacity(0.0)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 100)
                            .overlay(
                                WaveShape()
                                    .trim(from: 0, to: animateGraph ? 1 : 0)
                                    .stroke(brandPink, lineWidth: 2)
                            )
                            .overlay(
                                HStack {
                                    Text("8am").font(.caption2).foregroundColor(.gray)
                                    Spacer()
                                    Text("12pm").font(.caption2).foregroundColor(.gray)
                                    Spacer()
                                    Text("4pm").font(.caption2).foregroundColor(.gray)
                                    Spacer()
                                    Text("8pm").font(.caption2).foregroundColor(.gray)
                                }
                                .offset(y: 60)
                            )
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                    
                    // Status Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Estado actual")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                            Spacer()
                            Button("Ver todo") { }
                                .font(.subheadline.bold())
                                .foregroundColor(brandPink)
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            statusCard(title: "Locales no disponibles", value: "2", icon: "slash.circle.fill", color: .red)
                            statusCard(title: "Pedidos cancelados", value: "3", icon: "xmark.circle.fill", color: .orange)
                            statusCard(title: "Pedidos con demora", value: "5", icon: "clock.fill", color: .yellow)
                            statusCard(title: "Evaluación 1 estrella", value: "1", icon: "star.fill", color: brandPink)
                        }
                        .padding(.horizontal, 20)
                    }
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    
                    // Popular Dishes
                    popularDishesSection
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
                    
                    // Ratings Summary
                    ratingsSection
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                    
                    // Payouts
                    payoutsSection
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.7), value: animateContent)
                    
                    // Tips
                    tipsSection
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
                    
                    Spacer(minLength: bottomInset)
                }
            }
        }
        .fullScreenCover(isPresented: $showUploadVideo) {
            UploadVideoView(onClose: { showUploadVideo = false })
        }
    }
    
    // MARK: - UI Components
    
    private func kpiCardNew(title: String, value: String, badge: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(brandPink.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: icon).foregroundColor(brandPink).font(.caption.bold()))
                Spacer()
                Text(badge)
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.black)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private func statusCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: icon).foregroundColor(color).font(.caption.bold()))
                Spacer()
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(color)
            }
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.gray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - New Sections Components
    
    private var popularDishesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Platos más populares")
                    .font(.title3.bold())
                    .foregroundColor(.black)
                Spacer()
                Button("Ver ranking") { }
                    .font(.subheadline.bold())
                    .foregroundColor(brandPink)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                popularDishRow(rank: 1, name: "Classic Cheese Burger", count: "420 órdenes este mes", image: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd")
                popularDishRow(rank: 2, name: "Double Bacon Combo", count: "315 órdenes este mes", image: "https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5")
                popularDishRow(rank: 3, name: "Onion Rings XL", count: "280 órdenes este mes", image: "https://images.unsplash.com/photo-1639024471283-03518883512d")
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
        }
    }
    
    private func popularDishRow(rank: Int, name: String, count: String, image: String) -> some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: image))
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .background(Circle().fill(Color.gray.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Text(count)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("#\(rank)")
                .font(.headline.bold())
                .foregroundColor(rank == 1 ? .green : (rank == 2 ? brandPink : .orange))
        }
    }
    
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resumen de Calificaciones")
                .font(.title3.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("4.8")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)
                    HStack(spacing: 2) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(brandPink)
                        }
                    }
                    Text("1,240 ratings")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 8) {
                    ratingBar(star: 5, value: 0.8)
                    ratingBar(star: 4, value: 0.15)
                    ratingBar(star: 3, value: 0.03)
                    ratingBar(star: 2, value: 0.01)
                    ratingBar(star: 1, value: 0.01)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
        }
    }
    
    private func ratingBar(star: Int, value: CGFloat) -> some View {
        HStack(spacing: 8) {
            Text("\(star)")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .frame(width: 12)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.1))
                    Capsule().fill(brandPink).frame(width: geo.size.width * value)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var payoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Liquidaciones")
                .font(.title3.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "banknote.fill").foregroundColor(.green))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Próximo Pago")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                        Text("Estimado para el 24 de Oct.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("$4,850.00")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Saldo confirmado para transferencia")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: {}) {
                    Text("Ver detalles")
                        .font(.headline.bold())
                        .foregroundColor(brandPink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(brandPink.opacity(0.1))
                        .cornerRadius(16)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
        }
    }
    
    private var tipsSection: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(brandPink)
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "lightbulb.fill").foregroundColor(.white).font(.title3))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Consejos para hoy")
                    .font(.headline.bold())
                    .foregroundColor(brandPink)
                Text("Optimiza tus tiempos de preparación: reducir el tiempo de despacho en 2 minutos podría aumentar tus pedidos un 15% este fin de semana.")
                    .font(.caption)
                    .foregroundColor(.black)
                    .lineLimit(4)
            }
        }
        .padding(20)
        .background(brandPink.opacity(0.1))
        .cornerRadius(24)
        .padding(.horizontal, 20)
    }

    // MARK: - Logic & Data (Preserved)
    // These are kept to ensure no logic is lost, even if not currently used in the visual redesign
    private enum OrderState: String, CaseIterable { case pendiente = "Pendiente", enCocina = "En cocina", listo = "Listo", enEntrega = "En entrega", despachado = "Despachado" }
    private struct OrderItem: Identifiable { let id = UUID(); let title: String; let state: OrderState; let time: String; let type: String; let branch: String }
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
    private struct BranchPerf: Identifiable { let id = UUID(); let name: String; let orders: Int; let revenue: String; let avgTicket: String; let prep: String; let trendUp: Bool }
    private var branchItems: [BranchPerf] {
        [
            .init(name: "Centro", orders: 128, revenue: "$6,230", avgTicket: "$48.7", prep: "13m", trendUp: true),
            .init(name: "Condesa", orders: 96, revenue: "$4,020", avgTicket: "$41.9", prep: "16m", trendUp: false),
            .init(name: "Roma", orders: 84, revenue: "$3,110", avgTicket: "$37.0", prep: "12m", trendUp: true),
            .init(name: "Polanco", orders: 72, revenue: "$2,890", avgTicket: "$40.1", prep: "15m", trendUp: true)
        ]
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
}

// MARK: - Wave Shape for Graph
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.7))
        
        path.addCurve(
            to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.4),
            control1: CGPoint(x: rect.width * 0.1, y: rect.height * 0.9),
            control2: CGPoint(x: rect.width * 0.3, y: rect.height * 0.3)
        )
        
        path.addCurve(
            to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.6),
            control1: CGPoint(x: rect.width * 0.5, y: rect.height * 0.5),
            control2: CGPoint(x: rect.width * 0.6, y: rect.height * 0.8)
        )
        
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.5),
            control1: CGPoint(x: rect.width * 0.8, y: rect.height * 0.4),
            control2: CGPoint(x: rect.width * 0.9, y: rect.height * 0.6)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Side Menu View
struct SideMenuView: View {
    @Binding var showMenu: Bool
    @Binding var selectedMenu: String
    let brandPink: Color
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Circle()
                        .fill(brandPink)
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "fork.knife").foregroundColor(.white))
                    Text("FoodTook Admin")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                
                // Restaurant Selector
                HStack {
                    Circle().fill(Color.brown).frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tacos El Rey").font(.subheadline.bold()).foregroundColor(.black)
                        Text("Sucursal Centro").font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.down").font(.caption).foregroundColor(.gray)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                
                // Menu Items
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRINCIPAL").font(.caption.bold()).foregroundColor(.gray).padding(.horizontal, 24).padding(.bottom, 8)
                        
                        menuItem(icon: "square.grid.2x2.fill", text: "Tablero")
                        menuItem(icon: "list.bullet.clipboard", text: "Pedidos")
                        menuItem(icon: "book.closed", text: "Menú")
                        
                        Text("OPERACIONES").font(.caption.bold()).foregroundColor(.gray).padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)
                        
                        menuItem(icon: "person.3.fill", text: "Socios")
                        menuItem(icon: "chart.bar.fill", text: "Reportes")
                        menuItem(icon: "star.fill", text: "Evaluación y opiniones")
                        menuItem(icon: "megaphone.fill", text: "Publicidad en la app")
                        menuItem(icon: "tag.fill", text: "Promociones")
                        menuItem(icon: "clock.fill", text: "Horarios")
                    }
                }
                
                // Logout
                Button(action: { }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar Sesión")
                    }
                    .foregroundColor(.gray)
                    .font(.subheadline.bold())
                    .padding(24)
                }
            }
            .frame(width: 280)
            .background(Color.white)
            .ignoresSafeArea()
            
            Spacer()
        }
    }
    
    private func menuItem(icon: String, text: String, badge: String? = nil) -> some View {
        let isActive = selectedMenu == text
        return Button(action: {
            selectedMenu = text
            withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isActive ? .white : .gray)
                    .frame(width: 24)
                Text(text)
                    .font(.subheadline.weight(isActive ? .bold : .medium))
                    .foregroundColor(isActive ? .white : .black)
                Spacer()
                if let badge = badge {
                    Text(badge)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(6)
                        .background(brandPink)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isActive ? brandPink : Color.clear)
            .cornerRadius(12)
            .padding(.horizontal, 12)
        }
    }
}
