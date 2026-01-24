import SwiftUI

struct RatingView: View {
    let onDismiss: () -> Void
    
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            // Background
            Color.white.ignoresSafeArea()
            
            if showSuccess {
                // Minimalist Success State
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.brandGreen)
                        .scaleEffect(showSuccess ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)
                    
                    Text("¡Gracias!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                .transition(.opacity)
            } else {
                // Main Rating UI
                VStack(spacing: 0) {
                    // Close Button (Top Right)
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                    }
                    .padding()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            
                            // Avatar & Info
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(spacing: 4) {
                                    Text("Juan Pérez")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    Text("Repartidor • Toyota Prius")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 20)
                            
                            Divider()
                                .padding(.horizontal, 40)
                            
                            // Question
                            Text("¿Qué tal estuvo tu pedido?")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            
                            // Big Stars
                            HStack(spacing: 16) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 40))
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
                            
                            // Comment Field (Optional)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Comentario (Opcional)")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                TextEditor(text: $comment)
                                    .frame(height: 100)
                                    .padding(12)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 24)
                            
                            Spacer(minLength: 40)
                        }
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
                                        .font(.headline)
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
                    }
                    .background(Color.white)
                }
            }
        }
    }
    
    private func submitRating() {
        isSubmitting = true
        
        // Simulate API Call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showSuccess = true
            }
            
            // Dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}
