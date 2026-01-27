import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

struct ShareProfileView: View {
    let user: PublicProfileViewModel.UserProfileData
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var animateContent = false
    
    // Configuración
    private let backgroundColor = Color(hex: "F8F8F8") // Gris muy claro
    private let cardColor = Color.white
    
    var body: some View {
        ZStack {
            // Fondo con patrón de emojis
            EmojiPatternBackground()
                .ignoresSafeArea()
                .opacity(0.6)
            
            // Botón cerrar
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                    
                    Text("EMOJI")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Spacer()
            }
            .zIndex(10)

            VStack(spacing: 24) {
                Spacer()
                
                // Tarjeta Central QR
                VStack(spacing: 24) {
                    if let qr = qrImage {
                        Image(uiImage: qr)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .overlay(
                                // Hamburguesa central
                                Image(systemName: "hamburger") // Fallback
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.orange)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .overlay(
                                        Text("🍔")
                                            .font(.system(size: 32))
                                    )
                            )
                    } else {
                        ProgressView()
                            .frame(width: 220, height: 220)
                    }
                    
                    Text("@\(user.username.uppercased())")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .tracking(1.5)
                }
                .padding(40)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .scaleEffect(animateContent ? 1 : 0.9)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateContent)
                
                // Botones de acción
                HStack(spacing: 12) {
                    ActionButton(icon: "square.and.arrow.up", label: "Compartir perfil") {
                        shareProfile()
                    }
                    
                    ActionButton(icon: "link", label: "Copiar enlace") {
                        copyLink()
                    }
                    
                    ActionButton(icon: "arrow.down.to.line", label: "Descargar") {
                        saveToGallery()
                    }
                }
                .padding(.horizontal, 20)
                .offset(y: animateContent ? 0 : 50)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            generateQR()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateContent = true
            }
        }
    }
    
    private func generateQR() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let profileLink = "https://foodapp.com/u/\(user.username)"
        
        filter.message = Data(profileLink.utf8)
        filter.correctionLevel = "H" // High error correction for center image
        
        if let outputImage = filter.outputImage {
            // Escalar la imagen QR para que no se vea borrosa
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            // Cambiar color a naranja (opcional, si se quiere QR de color)
            // Por ahora mantenemos negro/blanco clásico con centro personalizado
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                self.qrImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    private func shareProfile() {
        let link = "https://foodapp.com/u/\(user.username)"
        let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        
        // Hack para presentar UIActivityViewController desde SwiftUI
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true, completion: nil)
        }
    }
    
    private func copyLink() {
        UIPasteboard.general.string = "https://foodapp.com/u/\(user.username)"
    }
    
    private func saveToGallery() {
        // Implementación simplificada
        guard let qr = qrImage else { return }
        UIImageWriteToSavedPhotosAlbum(qr, nil, nil, nil)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

struct EmojiPatternBackground: View {
    let emojis = ["😏", "😉", "🍔", "😋"]
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let cols = Int(width / 60) + 2
            let rows = Int(height / 60) + 2
            
            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<cols, id: \.self) { col in
                            Text(emojis[(row + col) % emojis.count])
                                .font(.system(size: 32))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(Double.random(in: -10...10)))
                        }
                    }
                }
            }
            .position(x: width/2, y: height/2)
        }
        .background(Color(hex: "FFF8F0")) // Fondo crema suave
    }
}

// Extension auxiliar si no existe
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
