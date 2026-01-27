import SwiftUI

struct DashboardProfileView: View {
    var onMenuTap: () -> Void
    
    // Colors
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    // Animation States
    @State private var animateContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                bgGray.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    header
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Profile Card
                            profileCard
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1 : 0)
                            
                            // Stats/Info Section
                            statsSection
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1 : 0)
                                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
                            
                            // Settings Groups
                            VStack(spacing: 20) {
                                settingsGroup(title: "Configuración de Cuenta", items: [
                                    SettingsItem(icon: "person.text.rectangle", title: "Editar Perfil", subtitle: "Cambia tu foto y datos"),
                                    SettingsItem(icon: "lock.shield", title: "Seguridad", subtitle: "Contraseña y autenticación"),
                                    SettingsItem(icon: "bell.badge", title: "Notificaciones", subtitle: "Gestiona tus alertas")
                                ])
                                
                                settingsGroup(title: "Restaurante", items: [
                                    SettingsItem(icon: "fork.knife.circle", title: "Datos del Restaurante", subtitle: "Horarios, dirección y contacto"),
                                    SettingsItem(icon: "creditcard", title: "Métodos de Pago", subtitle: "Tarjetas y cuentas bancarias"),
                                    SettingsItem(icon: "doc.text", title: "Facturación", subtitle: "Historial y datos fiscales")
                                ])
                                
                                settingsGroup(title: "Soporte", items: [
                                    SettingsItem(icon: "questionmark.circle", title: "Ayuda y Soporte", subtitle: "Centro de ayuda y contacto"),
                                    SettingsItem(icon: "doc.plaintext", title: "Términos y Condiciones", subtitle: "Legales y políticas")
                                ])
                                
                                // Logout
                                Button(action: {
                                    AuthService.shared.signOut()
                                }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Cerrar Sesión")
                                    }
                                    .font(.headline.bold())
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(16)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                                .padding(.bottom, 40)
                            }
                            .offset(y: animateContent ? 0 : 20)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
        .preferredColorScheme(.light)
    }
    
    private var header: some View {
        HStack {
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("Mi Perfil")
                .font(.title3.bold())
                .foregroundColor(.black)
            
            Spacer()
            
            // Placeholder to balance the header
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private var profileCard: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.brown)
                    .frame(width: 100, height: 100)
                    .overlay(Image(systemName: "person.fill").resizable().scaledToFit().padding(20).foregroundColor(.white.opacity(0.8)))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Button(action: {}) {
                    Circle()
                        .fill(brandPink)
                        .frame(width: 32, height: 32)
                        .overlay(Image(systemName: "camera.fill").font(.caption).foregroundColor(.white))
                        .shadow(radius: 2)
                }
                .offset(x: 0, y: 0)
            }
            
            VStack(spacing: 4) {
                Text("Burger King")
                    .font(.title2.bold())
                    .foregroundColor(.black)
                
                Text("Administrador")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("Sucursal Centro")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            statItem(value: "4.8", label: "Rating", icon: "star.fill", color: .orange)
            statItem(value: "1.2k", label: "Pedidos", icon: "bag.fill", color: brandPink)
            statItem(value: "98%", label: "A tiempo", icon: "clock.fill", color: .blue)
        }
        .padding(.horizontal, 20)
    }
    
    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.black)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func settingsGroup(title: String, items: [SettingsItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    Button(action: {}) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(brandPink.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(Image(systemName: item.icon).foregroundColor(brandPink))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.black)
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(16)
                        .background(Color.white)
                    }
                    
                    if index < items.count - 1 {
                        Divider().padding(.leading, 72)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 20)
    }
    
    struct SettingsItem {
        let icon: String
        let title: String
        let subtitle: String
    }
}
