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
                
                // Preview Area (Placeholder)
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(9/16, contentMode: .fit)
                    .frame(maxHeight: 400)
                    .overlay(
                        Text("Vista Previa del Recorte")
                            .foregroundColor(.white.opacity(0.5))
                    )
                
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
                                            let newProgress = max(0, min(endProgress - 0.1, value.location.x / geo.size.width))
                                            startProgress = newProgress
                                        }
                                )
                            
                            // Right Handle
                            HandleView()
                                .offset(x: geo.size.width * endProgress - 10)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let newProgress = min(1, max(startProgress + 0.1, value.location.x / geo.size.width))
                                            endProgress = newProgress
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
            loadDuration()
            generateThumbnails()
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
    
    private func loadDuration() {
        Task {
            if let d = try? await asset.load(.duration).seconds {
                self.duration = d
                // Initial trim to 15s if longer
                if d > maxDuration {
                    self.endProgress = maxDuration / d
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
}
