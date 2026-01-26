import SwiftUI

struct AllAlertsView: View {
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
                
                Text("Alertas Críticas")
                    .font(.title3.bold())
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bell.badge.fill")
                        .font(.title3)
                        .foregroundColor(brandPink)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(bgGray)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    Text("Hoy")
                        .font(.headline.bold())
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    VStack(spacing: 16) {
                        alertDetailCard(icon: "cube.box.fill", title: "Baja en Inventario", message: "Solo quedan 12 unidades de \"Salmón Fresco\". Reponer antes de las 18:00h.", time: "Hace 10 min", color: .orange)
                        alertDetailCard(icon: "scooter", title: "Demoras en Reparto", message: "Tráfico pesado detectado en zona Polanco. Se estiman retrasos de 15 min.", time: "Hace 25 min", color: .purple)
                        alertDetailCard(icon: "exclamationmark.triangle.fill", title: "Pago Rechazado", message: "Orden #4821 falló al procesar pago. Contactar cliente.", time: "Hace 1h", color: .red)
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateList ? 1 : 0)
                    .offset(y: animateList ? 0 : 20)
                    
                    Text("Ayer")
                        .font(.headline.bold())
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    VStack(spacing: 16) {
                        alertDetailCard(icon: "person.fill.xmark", title: "Ausencia Personal", message: "Repartidor Juan P. reportó enfermedad.", time: "Ayer 09:00", color: .gray)
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
    
    private func alertDetailCard(icon: String, title: String, message: String, time: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 48, height: 48)
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
                
                Button(action: {}) {
                    Text("Resolver")
                        .font(.caption.bold())
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
