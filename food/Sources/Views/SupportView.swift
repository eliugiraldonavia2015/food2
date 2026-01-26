import SwiftUI

struct SupportView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    @State private var message: String = ""
    @State private var animateViews = false
    
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
                    
                    Text("Ayuda y Soporte")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                .background(bgGray)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Contact Options
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contáctanos")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                            
                            HStack(spacing: 16) {
                                contactOption(icon: "phone.fill", title: "Llamar", color: .green)
                                contactOption(icon: "envelope.fill", title: "Email", color: .blue)
                                contactOption(icon: "bubble.left.and.bubble.right.fill", title: "Chat", color: brandPink)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .offset(y: animateViews ? 0 : 20)
                        .opacity(animateViews ? 1 : 0)
                        
                        // Help Center Categories
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Centro de Ayuda")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                categoryCard(icon: "cart.fill", title: "Pedidos")
                                categoryCard(icon: "creditcard.fill", title: "Pagos")
                                categoryCard(icon: "person.crop.circle.fill", title: "Cuenta")
                                categoryCard(icon: "gearshape.fill", title: "Configuración")
                            }
                        }
                        .padding(.horizontal, 20)
                        .offset(y: animateViews ? 0 : 30)
                        .opacity(animateViews ? 1 : 0)
                        
                        // Send Message Form
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Enviar Mensaje")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                            
                            VStack(spacing: 16) {
                                TextField("Asunto", text: .constant(""))
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                
                                TextEditor(text: $message)
                                    .frame(height: 120)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.clear, lineWidth: 1)
                                    )
                                    
                                Button(action: {}) {
                                    Text("Enviar Mensaje")
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(brandPink)
                                        .cornerRadius(16)
                                        .shadow(color: brandPink.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 20)
                        .offset(y: animateViews ? 0 : 40)
                        .opacity(animateViews ? 1 : 0)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.vertical)
        }
        .background(bgGray.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateViews = true
            }
        }
    }
    
    private func contactOption(icon: String, title: String, color: Color) -> some View {
        Button(action: {}) {
            VStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    )
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
    }
    
    private func categoryCard(icon: String, title: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(brandPink)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
    }
}
