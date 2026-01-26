import SwiftUI

struct AllBranchesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
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
                    
                    Text("Todas las Sucursales")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
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
                    VStack(spacing: 16) {
                        branchRow(rank: 1, name: "Sucursal Polanco", ticket: "$385.00", growth: "+12%", isUp: true)
                        branchRow(rank: 2, name: "Sucursal Condesa", ticket: "$342.00", growth: "+8%", isUp: true)
                        branchRow(rank: 3, name: "Sucursal Roma", ticket: "$310.00", growth: "-2%", isUp: false)
                        branchRow(rank: 4, name: "Sucursal Santa Fe", ticket: "$295.00", growth: "+5%", isUp: true)
                        branchRow(rank: 5, name: "Sucursal Del Valle", ticket: "$280.00", growth: "-1%", isUp: false)
                        branchRow(rank: 6, name: "Sucursal Coyoacán", ticket: "$265.00", growth: "+3%", isUp: true)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 20)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    private func branchRow(rank: Int, name: String, ticket: String, growth: String, isUp: Bool) -> some View {
        HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.headline.bold())
                .foregroundColor(.gray.opacity(0.5))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                
                HStack {
                    Text("Ticket Promedio:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(ticket)
                        .font(.caption.bold())
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                Text(growth)
            }
            .font(.subheadline.bold())
            .foregroundColor(isUp ? .green : .red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isUp ? Color.green : Color.red).opacity(0.1))
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
