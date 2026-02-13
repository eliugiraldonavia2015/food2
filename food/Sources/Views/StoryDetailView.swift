import SwiftUI
import SDWebImageSwiftUI

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
                                // Action for flash offer
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
            }
        }
        .onAppear {
            isAnimating = true
        }
        .onReceive(timer) { _ in
            guard !isPaused else { return }
            if progress < 1.0 {
                progress += 0.05 / storyDuration
            } else {
                onClose()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Pause on touch down
                    isPaused = true
                    if value.translation.height < 0 {
                         // Handling swipe up logic if needed
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        onClose() // Swipe down to close
                    } else if value.translation.height < -50 {
                        // Swipe up action
                        print("Swiped up")
                    } else {
                        isPaused = false
                    }
                }
        )
    }
}
