import SwiftUI

struct PremiumStatusView: View {
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
                    
                    VStack(spacing: 2) {
                        Text("Estado Premium")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                        Text("FOODTOOK ANALYTICS")
                            .font(.caption2.bold())
                            .foregroundColor(brandPink)
                            .tracking(1)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(brandPink)
                            .padding(8)
                            .background(brandPink.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color.white)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // Critical Alerts
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Alertas Críticas")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                Spacer()
                                NavigationLink(destination: AllAlertsView()) {
                                    Text("Ver todas")
                                        .font(.subheadline.bold())
                                        .foregroundColor(brandPink)
                                }
                            }
                            Text("Acciones inmediatas requeridas")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            alertCard(icon: "cube.box.fill", title: "Baja en Inventario", message: "Solo quedan 12 unidades de \"Salmón Fresco\". Reponer antes de las 18:00h.", color: .orange)
                            
                            alertCard(icon: "scooter", title: "Demoras en Reparto", message: "Tráfico pesado detectado en zona Polanco. Se estiman retrasos de 15 min.", color: .purple)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Comentarios Destacados
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Comentarios Destacados")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                            Text("Lo que dicen tus clientes hoy")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    commentCard(name: "Andrea M.", text: "\"El Poke de Salmón llegó fresquísimo y la presentación fue impecable. ¡Repetiré seguro!\"", rating: "5.0")
                                    commentCard(name: "Carlos R.", text: "\"La burger estaba un poco fría, pero el tiempo de entrega fue rápido.\"", rating: "4.0")
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Weekly Goals
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Metas Semanales")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                            Text("Progreso de facturación vs. objetivo")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Text("LUNES")
                                Spacer()
                                Text("HOY").foregroundColor(brandPink)
                                Spacer()
                                Text("DOMINGO")
                            }
                            .font(.caption2.bold())
                            .foregroundColor(.gray)
                            
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                                Capsule().fill(brandPink).frame(width: UIScreen.main.bounds.width * 0.6, height: 6)
                                
                                // Marker
                                VStack(spacing: 4) {
                                    Capsule().fill(brandPink).frame(width: 2, height: 10)
                                    Text("68%")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(brandPink)
                                        .cornerRadius(4)
                                }
                                .offset(x: UIScreen.main.bounds.width * 0.6 - 15, y: 20)
                            }
                            .padding(.vertical, 10)
                            
                            HStack(alignment: .firstTextBaseline) {
                                Spacer()
                                Text("$32,450")
                                    .font(.title.bold())
                                    .foregroundColor(.black)
                                Text("/ $48,000")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.top, 20)
                            
                            HStack {
                                Spacer()
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Text("VAS POR BUEN CAMINO")
                                Spacer()
                            }
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)
                        
                        // Support Card
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "message.fill")
                                        .font(.title)
                                        .foregroundColor(brandPink)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Text("¿Necesitas ayuda premium?")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                            
                            Text("Tu Account Manager está disponible para cualquier duda técnica o de negocio.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {}) {
                                Text("Contactar Account Manager")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(brandPink)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    private func alertCard(icon: String, title: String, message: String, color: Color) -> some View {
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
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(color)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(20)
    }
    
    private func commentCard(name: String, text: String, rating: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 32, height: 32)
                Text(name).font(.headline.bold())
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundColor(brandPink).font(.caption)
                    Text(rating).font(.caption.bold()).foregroundColor(brandPink)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(brandPink.opacity(0.1))
                .cornerRadius(8)
            }
            
            Text(text)
                .font(.subheadline)
                .italic()
                .foregroundColor(.gray)
                .lineLimit(4)
        }
        .padding()
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
