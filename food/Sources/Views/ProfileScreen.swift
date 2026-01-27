import SwiftUI
import SDWebImageSwiftUI

struct ProfileScreen: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var animateContent = false
    
    // Estados visuales
    @State private var scrollOffset: CGFloat = 0
    private let headerHeight: CGFloat = 280
    
    // Grid para fotos/videos
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            if let user = auth.user {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header con Parallax
                        header(user: user)
                        
                        VStack(spacing: 24) {
                            // Información del Perfil
                            profileInfo(user: user)
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1 : 0)
                            
                            // Botones de Acción
                            actionButtons
                                .offset(y: animateContent ? 0 : 30)
                                .opacity(animateContent ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
                            
                            // Bio / Descripción
                            if let bio = user.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(12)
                                    .offset(y: animateContent ? 0 : 40)
                                    .opacity(animateContent ? 1 : 0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
                            }
                            
                            // Grid de Contenido (Placeholder por ahora)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tus Videos")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                
                                LazyVGrid(columns: columns, spacing: 2) {
                                    ForEach(0..<9, id: \.self) { index in
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .aspectRatio(0.8, contentMode: .fill)
                                            .overlay(
                                                Image(systemName: "play.slash.fill")
                                                    .foregroundColor(.gray.opacity(0.5))
                                            )
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .offset(y: animateContent ? 0 : 50)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateContent)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Espacio para el TabBar
                    }
                    .background(
                        GeometryReader { geo -> Color in
                            let minY = geo.frame(in: .global).minY
                            DispatchQueue.main.async {
                                self.scrollOffset = minY
                            }
                            return Color.clear
                        }
                    )
                }
                .ignoresSafeArea(edges: .top)
            } else {
                // Estado de no autenticado o cargando
                VStack {
                    ProgressView()
                    Text("Cargando perfil...")
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Componentes Visuales
    
    private func header(user: AppUser) -> some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let height = minY > 0 ? headerHeight + minY : headerHeight
            
            ZStack(alignment: .bottom) {
                // Fondo / Cover Image
                if let coverUrl = user.photoURL { // Usando photoURL como placeholder si no hay cover
                    WebImage(url: coverUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: height)
                        .blur(radius: 20) // Efecto borroso artístico
                        .overlay(Color.black.opacity(0.1))
                        .clipped()
                        .offset(y: minY > 0 ? -minY : 0)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: height)
                        .offset(y: minY > 0 ? -minY : 0)
                }
                
                // Gradiente para suavizar la transición
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
        }
        .frame(height: headerHeight)
    }
    
    private func profileInfo(user: AppUser) -> some View {
        VStack(spacing: 4) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                if let url = user.photoURL {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 102, height: 102)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 102, height: 102)
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            .offset(y: -50)
            .padding(.bottom, -40)
            
            // Textos
            Text(user.name ?? "Usuario")
                .font(.title2.bold())
                .foregroundColor(.black)
            
            Text("@\(user.username ?? "usuario")")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let location = user.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(location)
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 4)
            }
            
            // Stats Rápidos
            HStack(spacing: 40) {
                statItem(value: "0", label: "Seguidores")
                statItem(value: "0", label: "Siguiendo")
                statItem(value: "0", label: "Likes")
            }
            .padding(.top, 16)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Acción de editar perfil
            }) {
                Text("Editar Perfil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 244/255, green: 37/255, blue: 123/255))
                    .cornerRadius(12)
                    .shadow(color: Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.3), radius: 5, x: 0, y: 3)
            }
            
            Button(action: {
                // Acción de configuración
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.black)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
