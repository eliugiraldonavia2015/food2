import SwiftUI

struct MonthlyExpensesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    @State private var animateList = false
    
    var body: some View {
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
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(bgGray)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Month Selector
                    HStack {
                        Image(systemName: "chevron.left")
                        Spacer()
                        Text("ENERO 2026")
                            .font(.headline.bold())
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Summary
                    HStack(spacing: 16) {
                        summaryCard(title: "Total Gastos", value: "$12,450", color: .red)
                        summaryCard(title: "Presupuesto", value: "$15,000", color: .green)
                    }
                    .padding(.horizontal, 20)
                    
                    // Detailed List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Desglose por Categoría")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            expenseDetailRow(icon: "archivebox.fill", name: "Insumos", date: "Ene 24, 2026", value: "-$4,250.00", percentage: "34%")
                            expenseDetailRow(icon: "truck.box.fill", name: "Logística", date: "Ene 22, 2026", value: "-$1,820.00", percentage: "15%")
                            expenseDetailRow(icon: "banknote.fill", name: "Comisiones", date: "Ene 20, 2026", value: "-$1,450.00", percentage: "12%")
                            expenseDetailRow(icon: "bolt.fill", name: "Servicios", date: "Ene 15, 2026", value: "-$980.00", percentage: "8%")
                            expenseDetailRow(icon: "person.2.fill", name: "Nómina Extra", date: "Ene 10, 2026", value: "-$3,950.00", percentage: "31%")
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
            withAnimation(.spring().delay(0.1)) {
                animateList = true
            }
        }
    }
    
    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.gray)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func expenseDetailRow(icon: String, name: String, date: String, value: String, percentage: String) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .font(.headline)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.red)
                Text(percentage)
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
