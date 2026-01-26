import SwiftUI

struct ProfitMarginView: View {
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
                    
                    Text("Margen de Utilidad")
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
                            Text("MARGEN ACTUAL")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("24%")
                                    .font(.system(size: 48, weight: .heavy))
                                    .foregroundColor(.black)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.down.right")
                                    Text("1.5%")
                                }
                                .font(.caption.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .offset(y: -15)
                            }
                            
                            Text("Tu rentabilidad ha disminuido ligeramente respecto al mes anterior.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 20)
                        
                        // Graph Card
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Ingresos vs Egresos")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                Spacer()
                                HStack(spacing: 12) {
                                    LegendItem(color: brandPink, text: "INGRESOS")
                                    LegendItem(color: Color.gray.opacity(0.3), text: "EGRESOS")
                                }
                            }
                            .padding(.horizontal)
                            
                            ZStack(alignment: .bottom) {
                                // Income Graph
                                IncomeGraphShape()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [brandPink.opacity(0.2), brandPink.opacity(0.0)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 150)
                                
                                IncomeGraphShape()
                                    .trim(from: 0, to: animateGraph ? 1 : 0)
                                    .stroke(brandPink, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                                    .frame(height: 150)
                                
                                // Expenses Graph (Dashed)
                                ExpensesGraphShape()
                                    .trim(from: 0, to: animateGraph ? 1 : 0)
                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [5, 5]))
                                    .frame(height: 150)
                                
                                // Point on Peak
                                 GeometryReader { proxy in
                                    Circle()
                                        .stroke(brandPink, lineWidth: 3)
                                        .background(Circle().fill(Color.white))
                                        .frame(width: 10, height: 10)
                                        .position(x: proxy.size.width * 0.7, y: proxy.size.height * 0.1) // Approximate peak
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
                        
                        // Principales Gastos
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Principales Gastos")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                Spacer()
                                NavigationLink(destination: MonthlyExpensesView()) {
                                    Text("Detalle mensual")
                                        .font(.subheadline.bold())
                                        .foregroundColor(brandPink)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                expenseRow(icon: "archivebox.fill", name: "Insumos", subtitle: "42% del total", value: "$4,250.00")
                                expenseRow(icon: "truck.box.fill", name: "Logística", subtitle: "18% del total", value: "$1,820.00")
                                expenseRow(icon: "banknote.fill", name: "Comisiones", subtitle: "15% del total", value: "$1,450.00")
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
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animateGraph = true
                }
                withAnimation(.spring().delay(0.3)) {
                    animateList = true
                }
            }
        }
    }
    
    private func LegendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption.bold()).foregroundColor(.gray)
        }
    }
    
    private func expenseRow(icon: String, name: String, subtitle: String, value: String) -> some View {
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

struct IncomeGraphShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h * 0.7))
        path.addCurve(
            to: CGPoint(x: w * 0.4, y: h * 0.5),
            control1: CGPoint(x: w * 0.15, y: h * 0.6),
            control2: CGPoint(x: w * 0.25, y: h * 0.4)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.1),
            control1: CGPoint(x: w * 0.55, y: h * 0.6),
            control2: CGPoint(x: w * 0.6, y: h * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.4),
            control1: CGPoint(x: w * 0.85, y: h * 0.1),
            control2: CGPoint(x: w * 0.9, y: h * 0.3)
        )
        
        return path
    }
}

struct ExpensesGraphShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h * 0.8))
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.7),
            control1: CGPoint(x: w * 0.2, y: h * 0.85),
            control2: CGPoint(x: w * 0.3, y: h * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.75),
            control1: CGPoint(x: w * 0.7, y: h * 0.65),
            control2: CGPoint(x: w * 0.9, y: h * 0.7)
        )
        
        return path
    }
}
