import SwiftUI

struct OrdersManagementView: View {
    var onMenuTap: () -> Void
    
    // MARK: - State
    @State private var selectedTab: String = "Todas las sucursales"
    @State private var animateCharts: Bool = false
    private let tabs = ["Todas las sucursales", "Polanco", "Condesa", "Roma"]
    
    private struct BranchData: Identifiable {
        let id = UUID()
        let name: String
        let active: Int
        let percentage: Double
        let pending: Int
        let cooking: Int
        let delivery: Int
        let delivered: Int
    }
    
    private let branches: [BranchData] = [
        BranchData(name: "Polanco", active: 42, percentage: 0.78, pending: 6, cooking: 10, delivery: 12, delivered: 14),
        BranchData(name: "Condesa", active: 38, percentage: 0.64, pending: 4, cooking: 8, delivery: 15, delivered: 11),
        BranchData(name: "Roma", active: 32, percentage: 0.85, pending: 3, cooking: 5, delivery: 8, delivered: 16)
    ]
    
    private var filteredBranches: [BranchData] {
        if selectedTab == "Todas las sucursales" {
            return branches
        } else {
            return branches.filter { $0.name == selectedTab }
        }
    }
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Filter Tabs
                    filterTabs
                    
                    // Global Status
                    globalStatusSection
                    
                    // Branch Status
                    branchStatusSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical, 16)
            }
        }
        .background(bgGray.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
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
            
            Text("Gestión de Pedidos")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                Button(action: {}) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(bgGray)
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? brandPink : Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var globalStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ESTADO GLOBAL HOY")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                    .tracking(1)
                Spacer()
                Text("Actualizado hace 2m")
                    .font(.caption.bold())
                    .foregroundColor(brandPink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(brandPink.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                globalStatusCard(title: "TOTAL", value: "128", icon: "list.bullet", color: .gray)
                globalStatusCard(title: "ENTREGADOS", value: "114", icon: "checkmark.circle.fill", color: .green)
                globalStatusCard(title: "CANCELADOS", value: "6", icon: "xmark.circle.fill", color: .red)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func globalStatusCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: icon).foregroundColor(color).font(.caption.bold()))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.black)
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var branchStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ESTADO POR SUCURSAL")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                    .tracking(1)
                Spacer()
                Button("GESTIONAR >") { }
                    .font(.caption.bold())
                    .foregroundColor(brandPink)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 20) {
                ForEach(filteredBranches) { branch in
                    branchCard(data: branch)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .animation(.spring(), value: selectedTab)
        }
    }
    
    private func branchCard(data: BranchData) -> some View {
        VStack(spacing: 24) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.name)
                        .font(.title2.bold())
                        .foregroundColor(.black)
                    HStack(spacing: 6) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("\(data.active) pedidos activos")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                
                // Donut Chart
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: animateCharts ? data.percentage : 0)
                        .stroke(
                            AngularGradient(gradient: Gradient(colors: [Color.blue, brandPink, Color.orange]), center: .center),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.5).delay(0.2), value: animateCharts)
                    
                    Text("\(Int(data.percentage * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                }
            }
            
            // Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statusDetailItem(title: "PENDIENTES", value: "\(data.pending)", icon: "timer", color: .orange)
                statusDetailItem(title: "EN COCINA", value: "\(data.cooking)", icon: "flame.fill", color: brandPink)
                statusDetailItem(title: "EN REPARTO", value: "\(data.delivery)", icon: "scooter", color: .blue)
                statusDetailItem(title: "ENTREGADOS", value: "\(data.delivered)", icon: "checkmark.circle", color: .green)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private func statusDetailItem(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: icon).foregroundColor(color).font(.caption.bold()))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.black)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.03))
        .cornerRadius(16)
    }
}
