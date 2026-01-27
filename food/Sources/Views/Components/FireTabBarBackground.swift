import SwiftUI

struct FireTabBarBackground: View {
    var isDark: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // 1. Fondo Base (Blanco Puro)
                Color.white
                
                // 2. Capa de "Oscuridad" (Black Liquid)
                // Usamos drawingGroup() para rasterizar en GPU y evitar lag en animaciones complejas
                ZStack(alignment: .top) {
                    // El cuerpo sólido negro
                    Color.black
                    
                    // El "Borde de Fuego" (Heat Edge)
                    // Un gradiente más sutil y elegante que simula incandescencia
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: Color(red: 1.0, green: 0.2, blue: 0.1).opacity(0.6), location: 0.4), // Rojo Fuego sutil
                            .init(color: Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.8), location: 0.7), // Naranja Intenso
                            .init(color: .black, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 50) // Altura del resplandor
                    .offset(y: -49) // Se asienta justo encima del negro (1pt de overlap para evitar líneas blancas)
                    .blur(radius: 4) // Desenfoque gaussiano para "suavizar" y parecer gas/luz
                }
                .frame(height: geo.size.height + 100) // Altura extra para cubrir safe area
                .offset(y: isDark ? 0 : geo.size.height + 100) // Animación de desplazamiento
                .drawingGroup() // <--- CLAVE: Renderizado Metal para 60/120 FPS estables
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        // Animación personalizada "Exquisita"
        // Spring interpolating: Rápido al inicio, frenado suave al final.
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0),
            value: isDark
        )
    }
}
