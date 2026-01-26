import SwiftUI

struct PartnersView: View {
    var onMenuTap: () -> Void
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    @State private var animateViews = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onMenuTap) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2.bold())
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Programa de Socios")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Ayuda")
                            .font(.subheadline.bold())
                            .foregroundColor(brandPink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(brandPink.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
                .padding()
                .background(bgGray)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Greeting
                        HStack {
                            Text("Hola, Burgers & Co!")
                                .font(.title2.bold())
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Progress Card (Combined)
                        VStack(spacing: 16) {
                            HStack {
                                Text("Nivel Oro")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                Spacer()
                                Text("ACTUAL")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(brandPink)
                                    .cornerRadius(8)
                            }
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Progreso hacia Platino")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("350/500 pts")
                                        .font(.subheadline.bold())
                                        .foregroundColor(brandPink)
                                }
                                
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 12)
                                    
                                    Capsule()
                                        .fill(brandPink)
                                        .frame(width: UIScreen.main.bounds.width * 0.55, height: 12) // Simulated 70%
                                }
                                
                                HStack {
                                    Text("¡Casi ahí! Te faltan 150 puntos")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                            
                            // Info Box
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(brandPink)
                                    .font(.title3)
                                Text("Te faltan solo **50 pedidos** para desbloquear comisiones reducidas y mayor visibilidad.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        .offset(y: animateViews ? 0 : 20)
                        .opacity(animateViews ? 1 : 0)
                        
                        // Beneficios de tu Nivel (Horizontal Scroll)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Beneficios de tu Nivel")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    benefitCard(icon: "percent", title: "Comisión Reducida", description: "Disfruta de una tarifa preferencial del 15% en todos tus pedidos.", color: brandPink)
                                    benefitCard(icon: "chart.line.uptrend.xyaxis", title: "Mayor Visibilidad", description: "Aparece en la sección 'Recomendados' los fines de semana.", color: .orange)
                                    benefitCard(icon: "envelope.fill", title: "Soporte Prioritario", description: "Acceso a línea directa con soporte técnico 24/7.", color: .blue)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        }
                        .offset(y: animateViews ? 0 : 30)
                        .opacity(animateViews ? 1 : 0)
                        
                        // Niveles de Socio (Vertical List)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Niveles de Socio")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                Spacer()
                                NavigationLink(destination: AllLevelsView()) {
                                    Text("Ver todos")
                                        .font(.subheadline.bold())
                                        .foregroundColor(brandPink)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 20) {
                                // Next Level (Platino)
                                levelCard(
                                    level: "NIVEL 3",
                                    title: "Platino",
                                    status: "SIGUIENTE META",
                                    features: [
                                        "Comisión reducida (12%)",
                                        "Badge de Verificado",
                                        "Campañas de Marketing Gratuitas"
                                    ],
                                    isLocked: true,
                                    progress: 0.3
                                )
                                
                                // Future Level (Diamante)
                                levelCard(
                                    level: "NIVEL 4",
                                    title: "Diamante",
                                    status: "",
                                    features: [
                                        "Comisión mínima (10%)",
                                        "Account Manager Dedicado",
                                        "Prioridad absoluta en Feed"
                                    ],
                                    isLocked: true,
                                    progress: 0
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        .offset(y: animateViews ? 0 : 40)
                        .opacity(animateViews ? 1 : 0)
                        
                        // FAQ
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preguntas Frecuentes")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                faqRow(question: "¿Cómo mejoro mi posicionamiento?")
                                faqRow(question: "¿Cuándo recibo mis pagos?")
                                faqRow(question: "¿Qué es el Nivel Diamante?")
                            }
                            .padding(.horizontal, 20)
                        }
                        .offset(y: animateViews ? 0 : 50)
                        .opacity(animateViews ? 1 : 0)
                        
                        // Support Card
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("¿Necesitas ayuda?")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    Text("Nuestro equipo de soporte está disponible 24/7 para ti.")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                            }
                            
                            NavigationLink(destination: SupportView()) {
                                        HStack {
                                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                            Text("Contactar Soporte")
                                        }
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(brandPink)
                                        .cornerRadius(16)
                                    }
                        }
                        .padding(24)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                        .offset(y: animateViews ? 0 : 60)
                        .opacity(animateViews ? 1 : 0)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    animateViews = true
                }
            }
        }
    }
    
    private func benefitCard(icon: String, title: String, description: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                )
            
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.black)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func levelCard(level: String, title: String, status: String, features: [String], isLocked: Bool, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                // Avatar/Image Placeholder
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: isLocked ? "lock.fill" : "star.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(level)
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                        if !status.isEmpty {
                            Text(status)
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(isLocked ? .gray : .black)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: isLocked ? "lock.fill" : "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(isLocked ? .gray : .green)
                                Text(feature)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            if progress > 0 {
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                    Capsule().fill(brandPink).frame(width: UIScreen.main.bounds.width * 0.7 * progress, height: 6)
                }
                
                HStack {
                    Spacer()
                    Text("Faltan \(Int((1.0 - progress) * 500)) pts")
                        .font(.caption2.bold())
                        .foregroundColor(brandPink)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        // Make it look slightly disabled if locked, but still readable
        .opacity(isLocked ? 0.9 : 1.0)
    }
    
    private func faqRow(question: String) -> some View {
        DisclosureGroup(
            content: {
                Text("Esta es una respuesta de ejemplo para la pregunta frecuente. Aquí se explicarían los detalles pertinentes.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            },
            label: {
                Text(question)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
            }
        )
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}
