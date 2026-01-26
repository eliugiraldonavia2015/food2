import SwiftUI

struct AllStatsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Text("Todas las Métricas")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
                .background(bgGray)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            statCard(title: "Ticket Promedio", value: "$385.00", trend: "+12%", trendUp: true, icon: "banknote", color: brandPink)
                            statCard(title: "Órdenes Totales", value: "892", trend: "+8.1%", trendUp: true, icon: "bag.fill", color: .blue)
                            statCard(title: "Margen Utilidad", value: "24%", trend: "-1.5%", trendUp: false, icon: "chart.pie.fill", color: .purple)
                            statCard(title: "Satisfacción", value: "4.8", trend: "+0.2", trendUp: true, icon: "star.fill", color: .yellow)
                            statCard(title: "Tiempo Promedio", value: "28m", trend: "-2m", trendUp: true, icon: "clock.fill", color: .orange)
                            statCard(title: "Nuevos Clientes", value: "145", trend: "+15%", trendUp: true, icon: "person.2.fill", color: .green)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    private func statCard(title: String, value: String, trend: String, trendUp: Bool, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(color)
                    )
                Spacer()
                Text(trend)
                    .font(.caption.bold())
                    .foregroundColor(trendUp ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((trendUp ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(4)
            }
            
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
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
