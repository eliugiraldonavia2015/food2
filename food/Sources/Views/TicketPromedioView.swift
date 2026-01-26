import SwiftUI

struct TicketPromedioView: View {
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
                    
                    Text("Ticket Promedio")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                .background(bgGray)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Main Value
                        VStack(spacing: 8) {
                            Text("VALOR PROMEDIO")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$345.00")
                                    .font(.system(size: 48, weight: .heavy))
                                    .foregroundColor(.black)
                                
                                Text("+5.2%")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                    .offset(y: -15)
                            }
                            
                            Text("Tu ticket promedio ha aumentado favorablemente este mes.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 20)
                        
                        // Graph Card
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Ticket Promedio Semanal")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                Spacer()
                                HStack(spacing: 4) {
                                    Circle().fill(brandPink).frame(width: 8, height: 8)
                                    Text("PROMEDIO").font(.caption.bold()).foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                            
                            ZStack(alignment: .bottom) {
                                // Gradient Fill
                                TicketGraphShape()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [brandPink.opacity(0.2), brandPink.opacity(0.0)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 150)
                                
                                // Line Stroke
                                TicketGraphShape()
                                    .trim(from: 0, to: animateGraph ? 1 : 0)
                                    .stroke(brandPink, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                                    .frame(height: 150)
                                
                                // Point at end
                                GeometryReader { proxy in
                                    Circle()
                                        .fill(brandPink)
                                        .frame(width: 8, height: 8)
                                        .position(x: proxy.size.width, y: proxy.size.height * 0.15) // Approximate end point
                                        .opacity(animateGraph ? 1 : 0)
                                }
                                .frame(height: 150)
                            }
                            .padding(.top, 20)
                            
                            HStack {
                                Text("SEM 1")
                                Spacer()
                                Text("SEM 2")
                                Spacer()
                                Text("SEM 3")
                                Spacer()
                                Text("SEM 4")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        // Top Sucursales List
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Top Sucursales")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                Spacer()
                                NavigationLink(destination: AllBranchesView()) {
                                    Text("Ver todas")
                                        .font(.subheadline.bold())
                                        .foregroundColor(brandPink)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                sucursalRow(icon: "mappin.circle.fill", name: "Polanco", subtitle: "42% del volumen", value: "$410.00")
                                sucursalRow(icon: "building.2.fill", name: "Condesa", subtitle: "35% del volumen", value: "$380.00")
                                sucursalRow(icon: "building.fill", name: "Santa Fe", subtitle: "23% del volumen", value: "$315.00")
                            }
                            .padding(.horizontal, 20)
                            .opacity(animateList ? 1 : 0)
                            .offset(y: animateList ? 0 : 20)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animateGraph = true
            }
            withAnimation(.spring().delay(0.3)) {
                animateList = true
            }
        }
    }
    
    private func sucursalRow(icon: String, name: String, subtitle: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.gray)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.black)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct TicketGraphShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h * 0.8))
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.6),
            control1: CGPoint(x: w * 0.2, y: h * 0.75),
            control2: CGPoint(x: w * 0.3, y: h * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.15),
            control1: CGPoint(x: w * 0.7, y: h * 0.55),
            control2: CGPoint(x: w * 0.9, y: h * 0.4)
        )
        
        return path
    }
}
