import SwiftUI
import AVFoundation
import UIKit

// MARK: - Feed Video Player (Custom implementation for AspectFill)
struct FeedVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        view.playerLayer.videoGravity = .resizeAspectFill // ✅ Clave para evitar deformación y bordes negros
        view.backgroundColor = .black // Fondo negro para evitar flashes
        return view
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) {
        if uiView.player != player {
            uiView.player = player
        }
    }
    
    class PlayerView: UIView {
        var player: AVPlayer? {
            get { playerLayer.player }
            set { playerLayer.player = newValue }
        }
        
        var playerLayer: AVPlayerLayer {
            return layer as! AVPlayerLayer
        }
        
        override class var layerClass: AnyClass {
            return AVPlayerLayer.self
        }
    }
}
