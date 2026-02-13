import SwiftUI
import SDWebImageSwiftUI
import Combine

struct StoryDetailView: View {
    // MARK: - Properties
    let update: NotificationsScreen.RestaurantUpdate
    var onClose: () -> Void
    
    // State
    @State private var progress: CGFloat = 0.0
    @State private var isPaused = false
    @State private var showDetails = false
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var showFlashOffer = false
    
    // Constants
    private let storyDuration: TimeInterval = 5.0
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    // Mock Data for the story content (since we don't have it in the model yet)
    private let storyImage = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd" // Burger image
    private let storyTitle = "The Burger Joint"
    private let storySubtitle = "Sponsored"
    
    var body: some View {
        ZStack {
            // Background (Dark)
            Color.black.ignoresSafeArea()
            
            // Main Content Layer
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    // Story Image
                    WebImage(url: URL(string: storyImage))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.6),
                                    Color.clear,
                                    Color.clear,
                                    Color.black.opacity(0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.linear(duration: storyDuration), value: isAnimating)
                    
                    // Controls & Overlays
                    VStack(spacing: 0) {
                        // Top Progress Bar
                        HStack(spacing: 4) {
                            ForEach(0..<1) { index in
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.3))
                                        
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(width: geo.size.width * progress)
                                    }
                                }
                                .frame(height: 2)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16) // Safe area top
                        
                        // Header
                        HStack(spacing: 12) {
                            // Avatar
                            WebImage(url: URL(string: update.logo))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            
                            // Text
                            VStack(alignment: .leading, spacing: 2) {
                                Text(update.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(storySubtitle)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            // Close Button
                            Button(action: onClose) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        Spacer()
                        
                        // Bottom Content
                        VStack(spacing: 16) {
                            // Swipe Up Hint
                            VStack(spacing: 4) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("SWIPE UP FOR DETAILS")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .offset(y: isAnimating ? -8 : 0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                            
                            // Flash Offer Button
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showFlashOffer = true
                                    isPaused = true
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text("View Flash Offer")
                                        .font(.system(size: 15, weight: .bold))
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            }
                            .padding(.bottom, 30)
                        }
                    }
                }
                .offset(y: dragOffset)
                // Simplificamos la animación: solo movimiento vertical, sin escala ni rotación ni opacidad gradual
                // .scaleEffect(1.0 - (dragOffset / 1000.0))
                // .rotation3DEffect(.degrees(Double(dragOffset / 20)), axis: (x: 1, y: 0, z: 0))
                // .opacity(1.0 - (dragOffset / 500.0))
            }
            
            // Flash Offer Overlay
            if showFlashOffer {
                FlashOfferView(isPresented: $showFlashOffer, update: update) {
                    isPaused = false
                }
                .transition(.move(edge: .bottom))
                .zIndex(100)
            }
        }
        .onAppear {
            isAnimating = true
        }
        .onReceive(timer) { _ in
            guard !isPaused && !showFlashOffer else { return }
            if progress < 1.0 {
                progress += 0.05 / storyDuration
            } else {
                onClose()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !showFlashOffer else { return }
                    // Pause on touch down
                    isPaused = true
                    
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    guard !showFlashOffer else { return }
                    
                    if value.translation.height > 100 {
                        onClose() // Swipe down to close
                    } else if value.translation.height < -50 {
                        // Swipe up action for flash offer
                         withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showFlashOffer = true
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                            isPaused = false
                        }
                    }
                }
        )
    }
}

struct FlashOfferView: View {
    @Binding var isPresented: Bool
    let update: NotificationsScreen.RestaurantUpdate
    var onDismiss: () -> Void
    
    // Añadimos gesto de arrastre a la FlashOfferView
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                        onDismiss()
                    }
                }
            
            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("FLASH OFFER")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.orange)
                            
                            Text("50% OFF")
                                .font(.system(size: 48, weight: .heavy))
                                .foregroundColor(.primary)
                            
                            Text("Classic Cheese Burger")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        // Hero Image
                        WebImage(url: URL(string: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd"))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                        
                        // Timer / Details
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("EXPIRES IN")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text("04:59")
                                    .font(.title2)
                                    .fontDesign(.monospaced)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(spacing: 4) {
                                Text("CODE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text("BURGER50")
                                    .font(.title2)
                                    .fontDesign(.monospaced)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Action Button
                        Button(action: {
                            // Claim action
                        }) {
                            Text("Redeem Now")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        
                        Text("Valid only for today. Cannot be combined with other offers.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
            .shadow(radius: 20)
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            offset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            withAnimation {
                                isPresented = false
                                onDismiss()
                            }
                        } else {
                            withAnimation(.spring()) {
                                offset = 0
                            }
                        }
                    }
            )
            .transition(.move(edge: .bottom))
        }
    }
}
