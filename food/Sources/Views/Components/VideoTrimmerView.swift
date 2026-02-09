import SwiftUI
import AVFoundation

struct VideoTrimmerView: View {
    let asset: AVAsset
    let onComplete: (CMTimeRange) -> Void
    let onCancel: () -> Void
    
    // State
    @State private var startProgress: CGFloat = 0.0
    @State private var endProgress: CGFloat = 1.0
    @State private var duration: Double = 0
    @State private var thumbnails: [UIImage] = []
    
    // Preview State
    @State private var player: AVPlayer?
    @State private var isDragging = false
    @State private var timeObserver: Any?
    
    // Constants
    private let maxDuration: Double = 15.0
    private let thumbnailCount = 8
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Cancelar", action: onCancel)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Recortar Video")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Button("Listo") {
                        let start = duration * Double(startProgress)
                        let end = duration * Double(endProgress)
                        let range = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600),
                                              duration: CMTime(seconds: end - start, preferredTimescale: 600))
                        onComplete(range)
                    }
                    .foregroundColor(isValidDuration ? .fuchsia : .gray)
                    .disabled(!isValidDuration)
                }
                .padding()
                
                Spacer()
                
                // Preview Area
                Group {
                    if let player = player {
                        TrimmerPlayerView(player: player)
                            .aspectRatio(9/16, contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(9/16, contentMode: .fit)
                            .frame(maxHeight: 400)
                            .overlay(ProgressView().tint(.white))
                    }
                }
                
                Spacer()
                
                // Trimmer Controls
                VStack(spacing: 12) {
                    Text(timeString)
                        .foregroundColor(isValidDuration ? .white : .red)
                        .font(.system(size: 14, weight: .medium))
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Thumbnails Background
                            HStack(spacing: 0) {
                                ForEach(thumbnails, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width / CGFloat(thumbnailCount), height: 60)
                                        .clipped()
                                }
                            }
                            .cornerRadius(8)
                            
                            // Dimmed Areas
                            HStack(spacing: 0) {
                                Color.black.opacity(0.6)
                                    .frame(width: geo.size.width * startProgress)
                                Spacer()
                                Color.black.opacity(0.6)
                                    .frame(width: geo.size.width * (1.0 - endProgress))
                            }
                            
                            // Handles Frame
                            HStack(spacing: 0) {
                                Spacer()
                                    .frame(width: geo.size.width * startProgress)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(isValidDuration ? Color.fuchsia : Color.red, lineWidth: 2)
                                    .frame(width: geo.size.width * (endProgress - startProgress))
                                    .contentShape(Rectangle())
                                
                                Spacer()
                                    .frame(width: geo.size.width * (1.0 - endProgress))
                            }
                            
                            // Left Handle
                            HandleView()
                                .offset(x: geo.size.width * startProgress - 10)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDragging = true
                                            player?.pause()
                                            let newProgress = max(0, min(endProgress - 0.1, value.location.x / geo.size.width))
                                            startProgress = newProgress
                                            seekTo(progress: newProgress)
                                        }
                                        .onEnded { _ in
                                            isDragging = false
                                            startLoop()
                                        }
                                )
                            
                            // Right Handle
                            HandleView()
                                .offset(x: geo.size.width * endProgress - 10)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDragging = true
                                            player?.pause()
                                            let newProgress = min(1, max(startProgress + 0.1, value.location.x / geo.size.width))
                                            endProgress = newProgress
                                            seekTo(progress: newProgress)
                                        }
                                        .onEnded { _ in
                                            isDragging = false
                                            startLoop()
                                        }
                                )
                        }
                    }
                    .frame(height: 60)
                    .padding(.horizontal)
                    
                    Text("Máximo 15 segundos")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            setupPlayer()
            loadDuration()
            generateThumbnails()
        }
        .onDisappear {
            stopPlayer()
        }
    }
    
    private var isValidDuration: Bool {
        let currentDuration = duration * Double(endProgress - startProgress)
        return currentDuration <= maxDuration + 0.5 // 0.5s tolerance
    }
    
    private var timeString: String {
        let currentDuration = duration * Double(endProgress - startProgress)
        return String(format: "%.1f s", currentDuration)
    }
    
    private func setupPlayer() {
        let item = AVPlayerItem(asset: asset)
        let p = AVPlayer(playerItem: item)
        p.isMuted = true // Mute for preview if desired, or keep audio
        self.player = p
        
        // Loop logic
        startLoop()
    }
    
    private func stopPlayer() {
        player?.pause()
        if let ob = timeObserver {
            player?.removeTimeObserver(ob)
            timeObserver = nil
        }
        player = nil
    }
    
    private func startLoop() {
        guard let p = player else { return }
        
        // Remove existing observer
        if let ob = timeObserver {
            p.removeTimeObserver(ob)
            timeObserver = nil
        }
        
        let startTime = duration * Double(startProgress)
        p.seek(to: CMTime(seconds: startTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        p.play()
        
        // Observe time to loop
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            guard !self.isDragging else { return }
            
            let currentSeconds = time.seconds
            let endSeconds = self.duration * Double(self.endProgress)
            let startSeconds = self.duration * Double(self.startProgress)
            
            if currentSeconds >= endSeconds || currentSeconds < startSeconds {
                p.seek(to: CMTime(seconds: startSeconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                p.play()
            }
        }
    }
    
    private func seekTo(progress: CGFloat) {
        let seconds = duration * Double(progress)
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func loadDuration() {
        Task {
            if let d = try? await asset.load(.duration).seconds {
                self.duration = d
                // Initial trim to 15s if longer
                if d > maxDuration {
                    self.endProgress = maxDuration / d
                }
                // Restart loop with new duration info
                await MainActor.run {
                    self.startLoop()
                }
            }
        }
    }
    
    private func generateThumbnails() {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 200, height: 200)
        
        Task {
            let duration = try? await asset.load(.duration)
            guard let duration = duration else { return }
            let totalSeconds = duration.seconds
            
            var times: [CMTime] = []
            let step = totalSeconds / Double(thumbnailCount)
            
            for i in 0..<thumbnailCount {
                let time = CMTime(seconds: Double(i) * step, preferredTimescale: 600)
                times.append(time)
            }
            
            for await image in generator.images(for: times) {
                if let cgImage = try? image.image {
                    self.thumbnails.append(UIImage(cgImage: cgImage))
                }
            }
        }
    }
    
    struct HandleView: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: 20, height: 60)
                .overlay(
                    VStack(spacing: 2) {
                        ForEach(0..<3) { _ in
                            Circle()
                                .fill(Color.black)
                                .frame(width: 2, height: 2)
                        }
                    }
                )
                .shadow(radius: 2)
        }
    }
    
    struct TrimmerPlayerView: UIViewRepresentable {
        let player: AVPlayer
        
        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
            return view
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {
            if let layer = uiView.layer.sublayers?.first as? AVPlayerLayer {
                layer.player = player
                layer.frame = uiView.bounds
            }
        }
    }
}
