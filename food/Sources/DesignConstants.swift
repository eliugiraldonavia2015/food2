import SwiftUI

struct DesignConstants {
    struct Animation {
        /// Animación de resorte estándar para presentaciones de hojas (sheets) y modales.
        /// - Response: 0.4 (Rápido pero perceptible)
        /// - DampingFraction: 0.75 (Rebote suave, sin oscilar demasiado)
        /// - BlendDuration: 0.0 (Sin mezcla inicial)
        static let sheetPresentation = SwiftUI.Animation.spring(
            response: 0.4,
            dampingFraction: 0.75,
            blendDuration: 0.0
        )
        
        /// Animación para elementos que aparecen escalonados
        static let stagedContent = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.8
        )
        
        /// Transición de movimiento estándar desde el borde inferior
        static let sheetTransition = AnyTransition.move(edge: .bottom)
    }
    
    struct Layout {
        static let cornerRadius: CGFloat = 18.0
        static let sheetShadowColor = Color.black.opacity(0.18)
        static let sheetShadowRadius: CGFloat = 12.0
        static let sheetShadowY: CGFloat = -4.0
    }
}
