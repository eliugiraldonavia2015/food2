import SwiftUI

struct AllBranchesView: View {
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
                
                Text("Todas las Sucursales")
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
                }
            }
            .padding()
            .background(bgGray)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        Text("Buscar sucursal...")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    
                    // List
                    VStack(spacing: 16) {
                        branchCard(rank: 1, name: "Sucursal Polanco", revenue: "$410.00", volume: "42%", status: "Abierto", color: brandPink)
                        branchCard(rank: 2, name: "Sucursal Condesa", revenue: "$380.00", volume: "35%", status: "Abierto", color: .purple)
                        branchCard(rank: 3, name: "Sucursal Santa Fe", revenue: "$315.00", volume: "23%", status: "Abierto", color: .orange)
                        branchCard(rank: 4, name: "Sucursal Roma", revenue: "$290.00", volume: "18%", status: "Cerrado", color: .gray)
                        branchCard(rank: 5, name: "Sucursal Del Valle", revenue: "$210.00", volume: "12%", status: "Abierto", color: .blue)
                        branchCard(rank: 6, name: "Sucursal Coyoacán", revenue: "$180.00", volume: "8%", status: "Mantenimiento", color: .red)
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateList ? 1 : 0)
                    .offset(y: animateList ? 0 : 20)
                    
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
    
    private func branchCard(rank: Int, name: String, revenue: String, volume: String, status: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.headline.bold())
                .foregroundColor(.gray.opacity(0.5))
                .frame(width: 30)
            
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .foregroundColor(color)
                        .font(.headline)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                HStack {
                    Circle()
                        .fill(status == "Abierto" ? Color.green : (status == "Cerrado" ? Color.gray : Color.orange))
                        .frame(width: 6, height: 6)
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(revenue)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                Text(volume)
                    .font(.caption.bold())
                    .foregroundColor(brandPink)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
