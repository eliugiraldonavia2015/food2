import SwiftUI

struct FireTabBarBackground: View {
    var isDark: Bool
    
    // Altura extra para cubrir el safe area inferior si es necesario
    private let extraHeight: CGFloat = 100 
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Fondo base (Blanco)
            Color.white
            
            // Capa de "Fuego/Negro" que sube y baja
            ZStack(alignment: .top) {
                // El cuerpo negro que llena la barra
                Color.black
                
                // El borde de fuego en la parte superior
                // Solo visible cuando está subiendo/activo
                LinearGradient(
                    colors: [
                        .clear,
                        Color.red.opacity(0.8),
                        Color.orange.opacity(0.9),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40) // Altura del efecto de fuego
                .offset(y: -39) // Se asienta justo encima del bloque negro
                .opacity(isDark ? 0.6 : 0.8) // Un poco de transparencia para el efecto
            }
            // Cuando isDark es true, el offset es 0 (llena la vista).
            // Cuando es false, el offset es positivo (baja y desaparece).
            .offset(y: isDark ? 0 : 200)
            // Animación "Exquisita"
            .animation(
                .spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0),
                value: isDark
            )
        }
        // Nos aseguramos que no se salga de los bordes del tab bar (clipping)
        // pero permitimos que cubra el fondo
        .clipped()
        .edgesIgnoringSafeArea(.bottom)
    }
}
