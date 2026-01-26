import SwiftUI

struct PremiumReportsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    private let goldColor = Color(red: 1.0, green: 0.84, blue: 0.0)
    
    @State private var animateCharts = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Reportes Premium")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    Text("FOODTOOK ANALYTICS")
                        .font(.caption2.bold())
                        .foregroundColor(brandPink)
                        .tracking(1)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(Color.white)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Top Sucursales Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Sucursales por Rendimiento")
                            .font(.title3.bold())
                        Text("Desempeño mensual vs. meta de ventas")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 24) {
                            tierRow(tier: "GOLD TIER", tierColor: brandPink, name: "Sucursal Polanco", value: "$142,500", percentage: 0.85, isUp: true)
                            tierRow(tier: "SILVER TIER", tierColor: .gray, name: "Sucursal Santa Fe", value: "$118,200", percentage: 0.72, isUp: false)
                            tierRow(tier: "SILVER TIER", tierColor: .gray, name: "Sucursal Condesa", value: "$105,900", percentage: 0.65, isUp: false)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Demand Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comportamiento de la Demanda")
                            .font(.title3.bold())
                        Text("Pedidos por hora (Promedio semanal)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(alignment: .bottom, spacing: 16) {
                            demandBar(height: 50, time: "12:00")
                            demandBar(height: 80, time: "14:00")
                            demandBar(height: 60, time: "16:00")
                            demandBar(height: 100, time: "18:00")
                            demandBar(height: 140, time: "20:00", isPeak: true)
                            demandBar(height: 90, time: "22:00")
                        }
                        .frame(height: 180)
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Export Button
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                            Text("Exportar Informe PDF")
                        }
                        .font(.headline.bold())
                        .foregroundColor(brandPink)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(brandPink, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Products List
                    VStack(spacing: 16) {
                        productRow(image: "leaf.fill", name: "Salmon Poke Premium", count: "842 vendidos este mes", roi: "42% ROI", roiColor: brandPink, trend: "+12%", trendColor: .green)
                        productRow(image: "flame.fill", name: "Truffle Beef Burger", count: "756 vendidos este mes", roi: "38% ROI", roiColor: brandPink, trend: "+8%", trendColor: .green)
                        productRow(image: "circle.grid.cross.fill", name: "Pizza Margherita Art", count: "612 vendidos este mes", roi: "35% ROI", roiColor: brandPink, trend: "Stable", trendColor: .gray)
                    }
                    .padding(.horizontal, 20)
                    
                    // Efficiency
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Eficiencia de Operación")
                            .font(.title3.bold())
                        Text("Indicadores clave de servicio")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            efficiencyCard(title: "TIEMPO PREP", value: "12", unit: "MINUTOS", percentage: 0.8)
                            efficiencyCard(title: "CALIFICACIÓN", value: "4.8", unit: "★", percentage: 0.96)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .background(bgGray.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateCharts = true
            }
        }
    }
    
    private func tierRow(tier: String, tierColor: Color, name: String, value: String, percentage: Double, isUp: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tier)
                .font(.caption2.bold())
                .foregroundColor(tierColor)
            
            HStack {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Spacer()
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.black)
            }
            
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.2)).frame(height: 8)
                Capsule().fill(tierColor).frame(width: UIScreen.main.bounds.width * 0.8 * (animateCharts ? percentage : 0), height: 8)
            }
            
            HStack {
                Text("\(Int(percentage * 100))% DE LA META MENSUAL")
                    .font(.caption2.bold())
                    .foregroundColor(tierColor)
                Spacer()
                if isUp {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private func demandBar(height: CGFloat, time: String, isPeak: Bool = false) -> some View {
        VStack {
            if isPeak {
                Text("PICO")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black)
                    .cornerRadius(4)
                    .offset(y: 5)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(isPeak ? brandPink : brandPink.opacity(0.3))
                .frame(height: animateCharts ? height : 0)
                .frame(width: 30)
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private func productRow(image: String, name: String, count: String, roi: String, roiColor: Color, trend: String, trendColor: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: image)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                Text(count)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trend)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(trendColor.opacity(0.1))
                    .foregroundColor(trendColor)
                    .cornerRadius(4)
                
                Text(roi)
                    .font(.headline.bold())
                    .foregroundColor(roiColor)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func efficiencyCard(title: String, value: String, unit: String, percentage: Double) -> some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(brandPink.opacity(0.1), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: animateCharts ? percentage : 0)
                    .stroke(brandPink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text(value)
                        .font(.title2.bold())
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 100)
            
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}
