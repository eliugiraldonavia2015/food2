import SwiftUI

struct TotalOrdersView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    @State private var animateGraph = false
    @State private var animateList = false
    
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
                    
                    Text("Órdenes Totales")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                .background(bgGray)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Main Value
                        VStack(spacing: 8) {
                            Text("TOTAL DEL PERIODO")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("892")
                                    .font(.system(size: 48, weight: .heavy))
                                    .foregroundColor(.black)
                                
                                Text("+ 8.1%")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                    .offset(y: -15)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Bar Chart
                        VStack(alignment: .leading) {
                            HStack(alignment: .bottom, spacing: 12) {
                                barView(height: 60, day: "LUN")
                                barView(height: 80, day: "MAR")
                                barView(height: 120, day: "MIE", isSelected: true)
                                barView(height: 90, day: "JUE")
                                barView(height: 110, day: "VIE")
                                barView(height: 100, day: "SAB")
                                barView(height: 70, day: "DOM")
                            }
                            .frame(height: 160)
                            .padding(.vertical, 20)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        // Canal de Venta
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CANAL DE VENTA")
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .tracking(2)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                channelRow(icon: "iphone", name: "App Mobile", count: "580 órdenes", percentage: 0.65, color: brandPink)
                                channelRow(icon: "globe", name: "Sitio Web", count: "214 órdenes", percentage: 0.24, color: brandPink)
                                channelRow(icon: "storefront.fill", name: "Directo / POS", count: "98 órdenes", percentage: 0.11, color: brandPink)
                            }
                            .padding(.horizontal, 20)
                            .opacity(animateList ? 1 : 0)
                            .offset(y: animateList ? 0 : 20)
                        }
                        
                        // Insight
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(brandPink)
                                .font(.title3)
                            
                            Text("El volumen de órdenes aumentó un **12%** durante las horas pico de almuerzo (1:00 PM - 3:00 PM) comparado con la semana pasada.")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(brandPink.opacity(0.1))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring().delay(0.2)) {
                    animateGraph = true
                }
                withAnimation(.spring().delay(0.4)) {
                    animateList = true
                }
            }
        }
    }
    
    private func barView(height: CGFloat, day: String, isSelected: Bool = false) -> some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? brandPink : brandPink.opacity(0.3))
                .frame(height: animateGraph ? height : 0)
                .animation(.spring(dampingFraction: 0.6).delay(Double.random(in: 0...0.3)), value: animateGraph)
            
            Text(day)
                .font(.caption2.bold())
                .foregroundColor(isSelected ? brandPink : .gray)
        }
    }
    
    private func channelRow(icon: String, name: String, count: String, percentage: Double, color: Color) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Text(count)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: animateList ? percentage : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(percentage * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.black)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
