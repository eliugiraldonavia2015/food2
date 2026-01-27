import SwiftUI

struct AllAlertsView: View {
    var onMenuTap: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    @State private var animateViews = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Critical Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Críticas")
                                .font(.headline.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                            
                            alertItem(icon: "cube.box.fill", title: "Baja en Inventario", message: "Solo quedan 12 unidades de 'Salmón Fresco'.", time: "Hace 15 min", color: .orange)
                            alertItem(icon: "exclamationmark.triangle.fill", title: "Fallo en Cocina", message: "Horno 2 reporta temperatura inestable.", time: "Hace 45 min", color: .red)
                        }
                        
                        // Warnings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Advertencias")
                                .font(.headline.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 20)
                            
                            alertItem(icon: "scooter", title: "Demoras en Reparto", message: "Tráfico pesado en zona Polanco.", time: "Hace 1h", color: .purple)
                            alertItem(icon: "person.fill.questionmark", title: "Turno Incompleto", message: "Falta confirmar asistencia de turno vespertino.", time: "Hace 2h", color: .blue)
                        }
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Informativas")
                                .font(.headline.bold())
                                .foregroundColor(.blue)
                                .padding(.horizontal, 20)
                            
                            alertItem(icon: "star.fill", title: "Nueva Reseña", message: "Recibiste 5 estrellas de Andrea M.", time: "Hace 3h", color: .yellow)
                            alertItem(icon: "arrow.up.circle.fill", title: "Meta Alcanzada", message: "Ventas superaron el objetivo diario.", time: "Hace 5h", color: .green)
                        }
                        
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
    
    private var header: some View {
        HStack {
            if let onMenuTap = onMenuTap {
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
            } else {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            Text("Notificaciones")
                .font(.title3.bold())
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private func alertItem(icon: String, title: String, message: String, time: String, color: Color) -> some View {
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
                HStack {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    Spacer()
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}
