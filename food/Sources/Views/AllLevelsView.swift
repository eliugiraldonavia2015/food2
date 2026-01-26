import SwiftUI

struct AllLevelsView: View {
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
                    
                    Text("Niveles de Socio")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                .background(bgGray)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Level 1 - Completed
                        fullLevelCard(
                            level: 1,
                            name: "Principiante",
                            status: "COMPLETADO",
                            statusColor: .green,
                            features: [
                                "Comisión estándar (15%)",
                                "Soporte por email",
                                "Acceso al panel básico"
                            ],
                            image: "hand.thumbsup.fill",
                            color: .blue
                        )
                        .offset(y: animateList ? 0 : 20)
                        .opacity(animateList ? 1 : 0)
                        
                        // Level 2 - Current
                        fullLevelCard(
                            level: 2,
                            name: "Oro",
                            status: "ACTUAL",
                            statusColor: brandPink,
                            features: [
                                "Comisión preferencial (14%)",
                                "Soporte prioritario",
                                "Acceso a analíticas avanzadas",
                                "Promociones mensuales"
                            ],
                            image: "crown.fill",
                            color: .yellow
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(brandPink, lineWidth: 2)
                        )
                        .offset(y: animateList ? 0 : 20)
                        .opacity(animateList ? 1 : 0)
                        .animation(.spring().delay(0.1), value: animateList)
                        
                        // Level 3 - Locked
                        fullLevelCard(
                            level: 3,
                            name: "Platino",
                            status: "BLOQUEADO",
                            statusColor: .gray,
                            features: [
                                "Comisión reducida (12%)",
                                "Badge de Verificado",
                                "Campañas de Marketing Gratuitas",
                                "Account Manager dedicado"
                            ],
                            image: "star.circle.fill",
                            color: .gray
                        )
                        .offset(y: animateList ? 0 : 20)
                        .opacity(animateList ? 1 : 0)
                        .animation(.spring().delay(0.2), value: animateList)
                        
                        // Level 4 - Locked
                        fullLevelCard(
                            level: 4,
                            name: "Diamante",
                            status: "BLOQUEADO",
                            statusColor: .gray,
                            features: [
                                "Comisión mínima (10%)",
                                "Soporte VIP 24/7",
                                "Prioridad absoluta en Feed",
                                "Invitaciones a eventos exclusivos"
                            ],
                            image: "diamond.fill",
                            color: .gray
                        )
                        .offset(y: animateList ? 0 : 20)
                        .opacity(animateList ? 1 : 0)
                        .animation(.spring().delay(0.3), value: animateList)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 20)
                }
            }
            .background(bgGray.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring()) {
                    animateList = true
                }
            }
        }
    }
    
    private func fullLevelCard(level: Int, name: String, status: String, statusColor: Color, features: [String], image: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: image)
                            .font(.title2)
                            .foregroundColor(color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("NIVEL \(level)")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                        
                        Text(status)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor)
                            .cornerRadius(4)
                    }
                    
                    Text(name)
                        .font(.title2.bold())
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            .padding(20)
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 12) {
                Text("Beneficios")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.bottom, 4)
                
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(status == "BLOQUEADO" ? .gray : .green)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
