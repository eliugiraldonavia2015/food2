import SwiftUI

struct MonthlyExpensesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    @State private var animateViews = false
    
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
                    
                    Text("Detalle Mensual")
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
                    VStack(spacing: 20) {
                        // Summary Card
                        VStack(spacing: 8) {
                            Text("TOTAL GASTOS")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(2)
                            Text("$10,450.00")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundColor(.black)
                        }
                        .padding(.vertical, 20)
                        
                        // Expenses List
                        VStack(spacing: 16) {
                            expenseItem(icon: "archivebox.fill", name: "Insumos", date: "24 Ene", amount: "$4,250.00", category: "Operativo", color: .orange)
                            expenseItem(icon: "truck.box.fill", name: "Logística", date: "23 Ene", amount: "$1,820.00", category: "Envíos", color: .blue)
                            expenseItem(icon: "banknote.fill", name: "Comisiones", date: "22 Ene", amount: "$1,450.00", category: "Plataforma", color: brandPink)
                            expenseItem(icon: "bolt.fill", name: "Servicios", date: "20 Ene", amount: "$980.00", category: "Local", color: .yellow)
                            expenseItem(icon: "person.2.fill", name: "Nómina Extra", date: "18 Ene", amount: "$1,200.00", category: "Personal", color: .purple)
                            expenseItem(icon: "wrench.fill", name: "Mantenimiento", date: "15 Ene", amount: "$750.00", category: "Reparaciones", color: .gray)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                    .offset(y: animateViews ? 0 : 20)
                    .opacity(animateViews ? 1 : 0)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateViews = true
                }
            }
        }
    }
    
    private func expenseItem(icon: String, name: String, date: String, amount: String, category: String, color: Color) -> some View {
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
                
                HStack {
                    Text(category)
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text("• " + date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(amount)
                .font(.headline.bold())
                .foregroundColor(.black)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
