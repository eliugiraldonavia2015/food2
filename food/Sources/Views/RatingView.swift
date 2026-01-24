import SwiftUI

struct RatingView: View {
    let onDismiss: () -> Void
    
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var tipAmount: Double? = nil
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    // Tips Options
    private let tips = [10.0, 15.0, 20.0, 30.0]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Image
                ZStack(alignment: .bottom) {
                    Image("food_delivery_bg") // Placeholder or use a system image/gradient
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.black.opacity(0.6), .transparent],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(y: 40)
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, -40)
                }
                .zIndex(1)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Spacer for Avatar
                        Spacer().frame(height: 40)
                        
                        // Title & Subtitle
                        VStack(spacing: 8) {
                            Text("¿Cómo estuvo tu entrega?")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("Califica a Juan Pérez")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        // Stars
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundColor(star <= rating ? .orange : .gray.opacity(0.3))
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            rating = star
                                        }
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                            }
                        }
                        .padding(.vertical, 10)
                        
                        // Quick Feedback Tags (Visible only if rated)
                        if rating > 0 {
                            VStack(spacing: 16) {
                                Text("¿Qué salió bien?")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                FlowLayout(spacing: 10) {
                                    ForEach(["Rápido", "Amable", "Cuidado", "Perfecto"], id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 14, weight: .semibold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        Divider().padding(.vertical, 8)
                        
                        // Tip Section
                        VStack(spacing: 16) {
                            Text("Agregar propina")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            HStack(spacing: 12) {
                                ForEach(tips, id: \.self) { amount in
                                    Button(action: {
                                        withAnimation {
                                            tipAmount = (tipAmount == amount) ? nil : amount
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Text("$\(Int(amount))")
                                                .font(.system(size: 16, weight: .bold))
                                            Text("MXN")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(tipAmount == amount ? Color.brandGreen : Color.white)
                                        .foregroundColor(tipAmount == amount ? .white : .black)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: tipAmount == amount ? 0 : 1)
                                        )
                                        .shadow(color: tipAmount == amount ? Color.brandGreen.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                                    }
                                }
                            }
                            
                            Button(action: {}) {
                                Text("Ingresar otro monto")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.brandGreen)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Comment Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Comentario (Opcional)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Escribe aquí...", text: $comment)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Bottom Button
                VStack {
                    Button(action: submitRating) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Enviar Calificación")
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(rating > 0 ? Color.brandGreen : Color.gray.opacity(0.3))
                        .cornerRadius(16)
                        .shadow(color: rating > 0 ? Color.brandGreen.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(rating == 0 || isSubmitting)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                    .background(Color.white)
                }
            }
            
            // Success Overlay
            if showSuccess {
                Color.brandGreen.ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(showSuccess ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)
                    
                    Text("¡Gracias por tu opinión!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func submitRating() {
        isSubmitting = true
        
        // Simulate API Call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSuccess = true
            }
            
            // Dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onDismiss()
            }
        }
    }
}

// Reusing FlowLayout helper from FoodDiscoveryView

