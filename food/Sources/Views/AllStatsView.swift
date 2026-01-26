import SwiftUI

struct AllStatsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
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
                    
                    Text("Todas las Estadísticas")
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
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Resumen General")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            statCard(icon: "receipt", title: "Ticket Promedio", value: "$345", color: brandPink)
                            statCard(icon: "cart.fill", title: "Órdenes Totales", value: "892", color: .blue)
                            statCard(icon: "percent", title: "Margen Utilidad", value: "24%", color: .green)
                            statCard(icon: "doc.text.fill", title: "Reportes", value: "4 Nuevos", color: .orange)
                            statCard(icon: "star.fill", title: "Estado Premium", value: "Nivel Oro", color: .purple)
                            statCard(icon: "person.2.fill", title: "Clientes", value: "1.2k", color: .red)
                            statCard(icon: "clock.fill", title: "Tiempo Entrega", value: "28 min", color: .cyan)
                            statCard(icon: "cube.box.fill", title: "Inventario", value: "98%", color: .indigo)
                        }
                        .padding(.horizontal, 20)
                        
                        // Recent Activity
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Actividad Reciente")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                activityRow(icon: "arrow.up.circle.fill", title: "Nuevo récord de ventas", time: "Hace 2h", color: .green)
                                Divider().padding(.leading, 60)
                                activityRow(icon: "exclamationmark.circle.fill", title: "Alerta de inventario", time: "Hace 5h", color: .orange)
                                Divider().padding(.leading, 60)
                                activityRow(icon: "person.fill.checkmark", title: "Nuevo cliente VIP", time: "Ayer", color: brandPink)
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.headline)
                )
            
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
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func activityRow(icon: String, title: String, time: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
    }
}
