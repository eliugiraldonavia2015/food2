import SwiftUI
import SDWebImageSwiftUI
import UIKit

struct OwnProfileView: View {
    @StateObject private var viewModel: PublicProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Estados visuales inspirados en RestaurantProfileView
    @State private var isFollowing = false
    @State private var showFullMenu = false
    @State private var showEditProfile = false
    @State private var showShareSheet = false
    @State private var pullOffset: CGFloat = 0
    @State private var headerMinY: CGFloat = 0
    @State private var animateContent = false
    @State private var showScreen = false // Control maestro de animación
    @State private var loadedCoverImage: UIImage? = nil // Para precargar FullMenuView
    private let showBackButton: Bool
    
    // Optimistic UI Data (Fallback inicial)
    private let initialUserData: PublicProfileViewModel.UserProfileData?
    
    private let headerHeight: CGFloat = 280
    private let refreshThreshold: CGFloat = UIScreen.main.bounds.height * 0.15
    private let photoColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    private let hardcodedDescriptionText =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco."
    
    init(userId: String, initialCoverUrl: String? = nil, initialAvatarUrl: String? = nil, initialName: String? = nil, cachedImage: UIImage? = nil, showBackButton: Bool = true) {
        self.showBackButton = showBackButton
        
        // Construimos el initialData una vez y lo guardamos
        let data: PublicProfileViewModel.UserProfileData? = {
            if let name = initialName {
                return .init(
                    id: userId,
                    username: name.replacingOccurrences(of: " ", with: "").lowercased(),
                    name: name,
                    bio: "...",
                    photoUrl: initialAvatarUrl ?? "",
                    coverUrl: initialCoverUrl ?? "",
                    followers: 0,
                    location: ""
                )
            }
            return nil
        }()
        self.initialUserData = data
        
        _viewModel = StateObject(wrappedValue: PublicProfileViewModel(userId: userId, initialData: data))
        if let img = cachedImage {
            _loadedCoverImage = State(initialValue: img)
        }
    }
    
    // Computada segura que usa viewModel.user o fallback a initialUserData
    private var safeUser: PublicProfileViewModel.UserProfileData? {
        viewModel.user ?? initialUserData
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("profileScroll")).minY)
                            }
                        )
                        .padding(.bottom, -16)
                    
                    // USAR SIEMPRE LA VISTA REAL SI HAY DATOS MINIMOS
                    if let user = safeUser {
                        header(user: user)
                        
                        VStack(spacing: 24) {
                            profileInfo(user: user)
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1 : 0)
                            
                            descriptionCard
                                .offset(y: animateContent ? 0 : 30)
                                .opacity(animateContent ? 1 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)

                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("Restaurantes y platos concurridos")
                                UserActivitySection()
                            }
                            .offset(y: animateContent ? 0 : 40)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                        .padding(.top, 16)
                    } else {
                        // Skeleton solo si no hay NI SIQUIERA datos iniciales (raro)
                        skeletonLoadingView
                    }
                }
            }
            
            // Skeleton Overlay que desaparece suavemente cuando carga la data REAL completa
            if viewModel.user == nil && initialUserData != nil {
                skeletonLoadingView
                    .transition(.opacity)
                    .zIndex(2) // Asegurar que esté encima
            }
        }
        .opacity(showScreen ? 1 : 0)
        .offset(y: showScreen ? 0 : 15)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showScreen)
        .coordinateSpace(name: "profileScroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { y in
            pullOffset = max(0, y)
        }
        .onPreferenceChange(HeaderOffsetPreferenceKey.self) { v in
            headerMinY = v
            pullOffset = max(0, v)
        }
        .overlay(alignment: .topLeading) {
            if showBackButton {
                Button(action: { dismiss() }) {
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 38, height: 38)
                        .overlay(Image(systemName: "chevron.left").foregroundColor(.white).font(.system(size: 14, weight: .bold)))
                }
                .padding(.leading, 16)
                .padding(.top, 10)
                .opacity(showScreen ? 1 : 0)
                .animation(.easeIn.delay(0.3), value: showScreen)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .tint(Color.fuchsia)
        .preferredColorScheme(.light)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            showScreen = true // Animación inmediata del contenedor
            
            // Carga diferida de datos pesados para no bloquear la animación UI
            if viewModel.user == nil {
                // Precarga simulada rápida si no hay datos
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.3)) {
                         // Aquí se actualizará el estado interno del viewModel
                         // La animación cross-dissolve la maneja el ZStack
                    }
                    viewModel.loadData()
                    
                    // Animar contenido interno
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateContent = true
                    }
                }
            } else {
                animateContent = true
            }
        }
        .fullScreenCover(isPresented: $showFullMenu) {
            if let user = viewModel.user {
                FullMenuView(
                    restaurantId: user.username.replacingOccurrences(of: " ", with: "").lowercased(),
                    restaurantName: user.name,
                    coverUrl: user.coverUrl,
                    avatarUrl: user.photoUrl,
                    location: user.location.isEmpty ? "CDMX, México" : user.location,
                    branchName: user.location.isEmpty ? "CDMX, México" : user.location,
                    distanceKm: 2.3,
                    cachedCoverImage: loadedCoverImage,
                    onDismissToRoot: {
                        showFullMenu = false
                    }
                )
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView(onClose: { showEditProfile = false })
        }
        .sheet(isPresented: $showShareSheet) {
            if let user = viewModel.user {
                ShareProfileView(user: user)
            }
        }
    }
    
    // MARK: - Componentes Visuales
    
    private func header(user: PublicProfileViewModel.UserProfileData) -> some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let height = minY > 0 ? headerHeight + minY : headerHeight
            
            ZStack(alignment: .topLeading) {
                // 🛑 FIX: Fondo blanco absoluto para evitar franja gris al hacer pull
                Color.white.ignoresSafeArea()
                
                // 1. Placeholder Layer (Always visible underneath)
                ShimmerView()
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .offset(y: minY > 0 ? -minY : 0) // 🛑 FIX: Mover el shimmer también
                
                // 2. Image Layer
                if let img = loadedCoverImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: height)
                        .blur(radius: minY > 0 ? min(12, minY / 18) : 0, opaque: true)
                        .clipped()
                        .overlay(coverGradient)
                        .offset(y: minY > 0 ? -minY : 0)
                } else {
                    WebImage(url: URL(string: user.coverUrl))
                        .onSuccess { image, _, _ in
                            self.loadedCoverImage = image
                        }
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5)) // Fade suave al cargar
                        .aspectRatio(contentMode: .fill)
                        .frame(height: height)
                        .blur(radius: minY > 0 ? min(12, minY / 18) : 0, opaque: true)
                        .clipped()
                        .overlay(coverGradient)
                        .offset(y: minY > 0 ? -minY : 0)
                }
                
                Color.clear
                    .preference(key: HeaderOffsetPreferenceKey.self, value: minY)
            }
            .frame(height: headerHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(height: headerHeight)
        .background(Color.white) // 🛑 FIX: Fondo blanco para el contenedor
    }

    struct ShimmerView: View {
        @State private var startPoint = UnitPoint(x: -1.8, y: -1.2)
        @State private var endPoint = UnitPoint(x: 0, y: -0.2)
        
        var body: some View {
            ZStack {
                Color.white // 🛑 FIX: Fondo base blanco
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color.gray.opacity(0.15),
                        Color.white
                    ]),
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    startPoint = UnitPoint(x: 1, y: 0)
                    endPoint = UnitPoint(x: 2.8, y: 1.0)
                }
            }
        }
    }
    
    private var coverGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: 0.6),
                .init(color: Color.white, location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func profileInfo(user: PublicProfileViewModel.UserProfileData) -> some View {
        VStack(spacing: 0) {
            // Avatar con Placeholder
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                if let url = URL(string: user.photoUrl), !user.photoUrl.isEmpty {
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
                        .foregroundColor(.gray.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .offset(y: -75) // Subido de -55 a -75
            .padding(.bottom, -60) // Ajustado de -40 a -60 para compensar
            
            VStack(spacing: 8) {
                Text(user.name)
                    .foregroundColor(.black)
                    .font(.system(size: 24, weight: .bold))
                
                Text("@\(user.username)")
                    .foregroundColor(.gray)
                    .font(.system(size: 15))
                
                HStack(spacing: 32) {
                    // Rating (Reemplaza Categoría)
                    VStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Text("4.8")
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                            Image(systemName: "star.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 18))
                        }
                        Text("Calificación")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                    
                    // Seguidores
                    VStack(spacing: 0) {
                        Text(formatCount(user.followers))
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                        Text("Seguidores")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                    }
                }
                .padding(.top, 12)
                
                // Botones
                HStack(spacing: 12) {
                    Button(action: { showEditProfile = true }) {
                        HStack(spacing: 8) {
                            Text("Editar perfil")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .fixedSize()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.fuchsia)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button(action: { showShareSheet = true }) {
                        HStack(spacing: 8) {
                            Text("Compartir perfil").foregroundColor(.black).font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.top, 12)

            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 0)
    }
    
    // Estilo de botón con animación de rebote (Spring)
    struct BouncyButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
                .opacity(configuration.isPressed ? 0.9 : 1.0)
        }
    }
    
    private var descriptionCard: some View {
        Text(hardcodedDescriptionText)
            .foregroundColor(.gray)
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
    }

    // MARK: - User Activity Section
    struct UserActivitySection: View {
        @State private var selectedSegment = 0 // 0: Restaurantes, 1: Platos
        @State private var showRestaurantProfile = false
        @State private var selectedRestaurant: VisitedRestaurant? = nil
        
        // Mock Data for Visited Restaurants
        let visitedRestaurants = [
            VisitedRestaurant(
                name: "Burgers & Co.",
                image: "https://images.unsplash.com/photo-1550547660-d9450f859349",
                visits: 12,
                lastVisit: "Hace 2 días",
                category: "Hamburguesas"
            ),
            VisitedRestaurant(
                name: "Pizza Paradise",
                image: "https://images.unsplash.com/photo-1513104890138-7c749659a591",
                visits: 8,
                lastVisit: "Hace 1 semana",
                category: "Italiana"
            ),
            VisitedRestaurant(
                name: "Sushi Master",
                image: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c",
                visits: 5,
                lastVisit: "Hace 2 semanas",
                category: "Japonesa"
            ),
            VisitedRestaurant(
                name: "Tacos El Rey",
                image: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47",
                visits: 15,
                lastVisit: "Ayer",
                category: "Mexicana"
            )
        ]
        
        // Mock Data for Favorite Dishes
        let favoriteDishes = [
            FavoriteDish(
                name: "Hamburguesa Doble",
                restaurant: "Burgers & Co.",
                image: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
                orders: 8,
                price: "$12.50"
            ),
            FavoriteDish(
                name: "Pepperoni Pizza",
                restaurant: "Pizza Paradise",
                image: "https://images.unsplash.com/photo-1628840042765-356cda07504e",
                orders: 5,
                price: "$18.00"
            ),
            FavoriteDish(
                name: "Dragon Roll",
                restaurant: "Sushi Master",
                image: "https://images.unsplash.com/photo-1553621042-f6e147245754",
                orders: 3,
                price: "$14.00"
            ),
            FavoriteDish(
                name: "Tacos al Pastor",
                restaurant: "Tacos El Rey",
                image: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b",
                orders: 10,
                price: "$2.50"
            )
        ]
        
        var body: some View {
            VStack(spacing: 20) {
                // Segmented Control Customizado
                HStack(spacing: 0) {
                    segmentButton(title: "Restaurantes", index: 0)
                    segmentButton(title: "Platos", index: 1)
                }
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 4)
                
                // Content
                if selectedSegment == 0 {
                    restaurantList
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    dishList
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .fullScreenCover(item: $selectedRestaurant) { restaurant in
                // Simulación de navegación al perfil del restaurante
                // Aquí deberíamos usar RestaurantProfileView, pero como no tengo acceso directo al modelo completo
                // usaré FullMenuView como proxy visual o un placeholder que simule la navegación
                FullMenuView(
                    restaurantId: restaurant.name.replacingOccurrences(of: " ", with: "").lowercased(),
                    restaurantName: restaurant.name,
                    coverUrl: restaurant.image,
                    avatarUrl: restaurant.image, // Usando la misma para demo
                    location: "Ubicación Simulada",
                    branchName: "Sucursal Principal",
                    distanceKm: 1.2,
                    onDismissToRoot: { selectedRestaurant = nil }
                )
            }
        }
        
        private func segmentButton(title: String, index: Int) -> some View {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedSegment = index
                }
            }) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selectedSegment == index ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .padding(2)
                            .opacity(selectedSegment == index ? 1 : 0)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
            }
        }
        
        private var restaurantList: some View {
            VStack(spacing: 16) {
                ForEach(visitedRestaurants) { restaurant in
                    Button(action: { selectedRestaurant = restaurant }) {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: restaurant.image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(restaurant.name)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                Text(restaurant.category)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("Última vez: \(restaurant.lastVisit)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(restaurant.visits)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.fuchsia)
                                Text("Visitas")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
        }
        
        private var dishList: some View {
            VStack(spacing: 16) {
                ForEach(favoriteDishes) { dish in
                    HStack(spacing: 16) {
                        WebImage(url: URL(string: dish.image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dish.name)
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Text(dish.restaurant)
                                .font(.caption)
                                .foregroundColor(.fuchsia)
                            
                            Text(dish.price)
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("\(dish.orders)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            Text("Pedidos")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
            }
        }
    }
    
    struct VisitedRestaurant: Identifiable {
        let id = UUID()
        let name: String
        let image: String
        let visits: Int
        let lastVisit: String
        let category: String
    }
    
    struct FavoriteDish: Identifiable {
        let id = UUID()
        let name: String
        let restaurant: String
        let image: String
        let orders: Int
        let price: String
    }

    private var mediaGrid: some View {
        LazyVGrid(columns: photoColumns, spacing: 2) {
            ForEach(0..<15, id: \.self) { index in
                // Si hay videos reales, úsalos; si no, usa placeholders hardcodeados
                if index < viewModel.videos.count {
                    PhotoTileView(video: viewModel.videos[index], index: index)
                } else {
                    // Placeholder hardcodeado con diseño bonito
                    HardcodedTileView(index: index)
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).foregroundColor(.black).font(.headline)
            Spacer()
        }
    }
    
    private var skeletonLoadingView: some View {
        VStack(spacing: 0) {
            // Header Skeleton
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: headerHeight)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 24) {
                // Info Skeleton
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 102, height: 102)
                        .offset(y: -50)
                        .padding(.bottom, -50)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 150, height: 24)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 100, height: 16)
                    
                    HStack(spacing: 32) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.1)).frame(width: 60, height: 40)
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.1)).frame(width: 60, height: 40)
                    }
                }
                .padding(.top, -20)
                
                // Buttons Skeleton
                HStack {
                    RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.1)).frame(height: 50)
                    RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.1)).frame(height: 50)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count)/1_000_000) }
        else if count >= 1_000 { return String(format: "%.1fK", Double(count)/1_000) }
        else { return "\(count)" }
    }
    
    // Componente interno para las celdas de video con animación
    struct PhotoTileView: View {
        let video: Video
        let index: Int
        @State private var appear = false
        
        var body: some View {
            GeometryReader { geo in
                let url = URL(string: video.thumbnailUrl)
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.4))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .overlay(
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text("\(video.likes)")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                        , alignment: .bottomLeading
                    )
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.9)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05)) {
                            appear = true
                        }
                    }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color.gray.opacity(0.1))
        }
    }

    // Componente Placeholder Hardcodeado (Diseño Bonito)
    struct HardcodedTileView: View {
        let index: Int
        @State private var appear = false
        
        // Imágenes de ejemplo de Unsplash (Comida atractiva)
        let sampleImages = [
            "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
            "https://images.unsplash.com/photo-1604908176997-431199f7c209",
            "https://images.unsplash.com/photo-1600891964599-f61ba0e24092",
            "https://images.unsplash.com/photo-1555939594-58d7cb561ad1",
            "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38",
            "https://images.unsplash.com/photo-1565958011703-44f9829ba187",
            "https://images.unsplash.com/photo-1482049016688-2d3e1b311543",
            "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
            "https://images.unsplash.com/photo-1484723091739-30a097e8f929",
            "https://images.unsplash.com/photo-1467003909585-2f8a7270028d",
            "https://images.unsplash.com/photo-1473093295043-cdd812d0e601",
            "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f",
            "https://images.unsplash.com/photo-1476224203421-9ac39bcb3327",
            "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd",
            "https://images.unsplash.com/photo-1496417263034-38ec4f0d665a"
        ]
        
        var body: some View {
            GeometryReader { geo in
                let urlString = sampleImages[index % sampleImages.count]
                let url = URL(string: urlString + "?auto=format&fit=crop&w=400&q=80")
                
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.4))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .overlay(
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text("\(Int.random(in: 100...5000))")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                        , alignment: .bottomLeading
                    )
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.9)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05)) {
                            appear = true
                        }
                    }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color.gray.opacity(0.1))
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}
