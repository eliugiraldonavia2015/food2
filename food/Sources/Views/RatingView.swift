import SwiftUI

struct RatingView: View {
    let onDismiss: () -> Void
    
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var selectedTags: Set<String> = []
    @State private var appearAnimation = false
    
    private let feedbackTags = ["Rápido ⚡️", "Amable 😊", "Cuidado 📦", "Perfecto 🌟", "A tiempo ⏰"]
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                colors: [Color.white, Color(hex: "F8F9FA")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if showSuccess {
                successView
            } else {
                VStack(spacing: 0) {
                    // Custom Nav Bar
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black.opacity(0.6))
                                .padding(8)
                                .background(Color.black.opacity(0.05))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            
                            // 1. Driver Profile (Hero)
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 90, height: 90)
                                        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
                                    
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                }
                                .scaleEffect(appearAnimation ? 1 : 0.8)
                                .opacity(appearAnimation ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                                
                                VStack(spacing: 6) {
                                    Text("Juan Pérez")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                    
                                    Text("Tu repartidor")
                                        .font(.system(size: 15, weight: .medium, design: .default))
                                        .foregroundColor(.gray)
                                }
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 10)
                                .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimation)
                            }
                            .padding(.top, 10)
                            
                            // 2. Rating Section
                            VStack(spacing: 20) {
                                Text("¿Cómo estuvo tu entrega?")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.black)
                                
                                HStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(star <= rating ? .orange : Color(hex: "E0E0E0"))
                                            .scaleEffect(star <= rating ? 1.1 : 1.0)
                                            .shadow(color: star <= rating ? .orange.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                                    rating = star
                                                }
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            }
                                    }
                                }
                            }
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appearAnimation)
                            
                            // 3. Tags (Conditional)
                            if rating > 0 {
                                VStack(spacing: 16) {
                                    Text("¿Qué salió bien?")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.7))
                                    
                                    FlowLayout(spacing: 10) {
                                        ForEach(feedbackTags, id: \.self) { tag in
                                            Button(action: { toggleTag(tag) }) {
                                                Text(tag)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .padding(.horizontal, 18)
                                                    .padding(.vertical, 10)
                                                    .background(selectedTags.contains(tag) ? Color.black : Color.white)
                                                    .foregroundColor(selectedTags.contains(tag) ? .white : .black)
                                                    .cornerRadius(20)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                                    )
                                                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                            }
                                            .buttonStyle(RatingScaleButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            
                            // 4. Comment Input
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Comentario")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                
                                ZStack(alignment: .topLeading) {
                                    if comment.isEmpty {
                                        Text("Escribe aquí...")
                                            .foregroundColor(.gray.opacity(0.5))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                    }
                                    
                                    TextEditor(text: $comment)
                                        .scrollContentBackground(.hidden)
                                        .padding(8)
                                        .frame(height: 100)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                                }
                            }
                            .padding(.horizontal, 24)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 30)
                            .animation(.easeOut(duration: 0.6).delay(0.5), value: appearAnimation)
                            
                            Spacer(minLength: 100)
                        }
                    }
                    
                    // Floating Action Button
                    VStack {
                        Button(action: submitRating) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Enviar Calificación")
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(colors: [.brandGreen, .brandGreen.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(20)
                            .shadow(color: .brandGreen.opacity(0.4), radius: 12, x: 0, y: 6)
                            .scaleEffect(rating > 0 ? 1 : 0.95)
                            .opacity(rating > 0 ? 1 : 0.6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: rating > 0)
                        }
                        .disabled(rating == 0 || isSubmitting)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 34)
                    }
                    .background(
                        LinearGradient(colors: [Color.white.opacity(0), Color.white], startPoint: .top, endPoint: .bottom)
                            .frame(height: 100)
                    )
                }
            }
        }
        .onAppear {
            appearAnimation = true
        }
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.brandGreen.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showSuccess ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1), value: showSuccess)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .black))
                    .foregroundColor(.brandGreen)
                    .scaleEffect(showSuccess ? 1 : 0)
                    .rotationEffect(.degrees(showSuccess ? 0 : -90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showSuccess)
            }
            
            VStack(spacing: 8) {
                Text("¡Gracias!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .opacity(showSuccess ? 1 : 0)
                    .offset(y: showSuccess ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showSuccess)
                
                Text("Tu opinión nos ayuda a mejorar.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .opacity(showSuccess ? 1 : 0)
                    .offset(y: showSuccess ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: showSuccess)
            }
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func submitRating() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { isSubmitting = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring()) {
                showSuccess = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onDismiss()
            }
        }
    }
}

// MARK: - Helpers

struct RatingScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Reusing FlowLayout helper from FoodDiscoveryView
// Using private FlowLayout implementation instead of shared one to ensure independence
private struct RatingFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flow(subviews: subviews, containerWidth: proposal.width ?? .infinity)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flow(subviews: subviews, containerWidth: bounds.width)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func flow(subviews: Subviews, containerWidth: CGFloat) -> (size: CGSize, points: [CGPoint]) {
        var points: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            points.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), points)
    }
}
