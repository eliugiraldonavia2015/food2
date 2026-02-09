import SwiftUI
import AVFoundation
import UIKit

// MARK: - Feed Video Player (Custom implementation for AspectFill)
struct FeedVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    // Recibimos la orientación lógica para decidir el modo de renderizado
    // "landscape" o "square" -> .resizeAspectFit (para ver el video completo con letterbox ya quemado o natural)
    // "portrait" -> .resizeAspectFill (para llenar pantalla)
    // PERO: Como ahora quemamos las bandas negras en el servidor (TikTok style),
    // el video FÍSICO siempre es 9:16.
    // Si era landscape, tiene bandas negras quemadas.
    // Si lo ponemos en AspectFill, hará zoom y cortará las bandas negras (y el video).
    // Si lo ponemos en AspectFit, se verá perfecto porque las bandas son parte de la imagen.
    
    // CORRECCIÓN:
    // Si normalizamos todo a 720x1280, entonces SIEMPRE debemos usar .resizeAspectFill
    // porque el contenedor del video (720x1280) coincide exactamente con la pantalla del teléfono.
    // El "Fit" visual ya viene dibujado dentro de los píxeles del video.
    
    // Por lo tanto, mantenemos .resizeAspectFill para garantizar que el contenedor 720x1280
    // cubra toda la pantalla sin bordes blancos del sistema.
    
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        view.playerLayer.videoGravity = .resizeAspectFill 
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
