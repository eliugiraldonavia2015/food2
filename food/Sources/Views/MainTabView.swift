import SwiftUI
import SDWebImageSwiftUI

struct MainTabView: View {
    enum Tab {
        case feed, notifications, store, messages, profile
    }

    @State private var selected: Tab = .feed
    @State private var showShopLoading = false
    @State private var showShop = false
    @State private var inDiscoveryMode = false
    private let tabBarHeight: CGFloat = 52
    @State private var showCommentsOverlay = false
    @State private var commentsCount: Int = 0
    @State private var currentFeedImageUrl: String = ""

    var body: some View {
        GeometryReader { geo in
        ZStack(alignment: .bottom) {
            // CONTENIDO PRINCIPAL
            Group {
                switch selected {
                case .feed: FeedView(bottomInset: tabBarHeight, onGlobalShowComments: { count, url in
                        commentsCount = count
                        currentFeedImageUrl = url
                        withAnimation(.easeOut(duration: 0.25)) { showCommentsOverlay = true }
                    }, isCommentsOverlayActive: showCommentsOverlay)
                case .notifications: NotificationsScreen()
                case .store: StoreScreen()
                case .messages: MessagesListView()
                case .profile: ProfileScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .padding(.bottom, tabBarHeight) // ← ESPACIO FIJO para el tab bar

            if showShopLoading {
                VStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.green)
                        .scaleEffect(1.2)
                    Text("Abriendo Tienda")
                        .foregroundColor(.white)
                        .font(.footnote)
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.3), radius: 12)
                .transition(.opacity)
                .zIndex(3)
            }

            if showShop {
                FoodDiscoveryView(onClose: { withAnimation { showShop = false } })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }

            // TAB BAR
            if inDiscoveryMode {
                bottomBarDiscovery
                    .background(Color.black)
                    .zIndex(4)
            } else {
                bottomBar
                    .background(Color.black)
                    .zIndex(4)
            }

            // Overlay de comentarios por encima del tab bar
            if selected == .feed, showCommentsOverlay {
                CommentsOverlayView(count: commentsCount, onClose: { withAnimation(.easeOut(duration: 0.25)) { showCommentsOverlay = false } })
                    .zIndex(6)
            }
        }
        .animation(.easeInOut, value: showShopLoading)
        .animation(.easeInOut, value: showShop)
        .animation(.easeOut(duration: 0.25), value: showCommentsOverlay)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var bottomBar: some View {
        ZStack(alignment: .top) {
            HStack(spacing: -2) {
                navButton(icon: "house", title: "Inicio", tab: .feed)
                navButton(icon: "bell", title: "Notif", tab: .notifications)
                cartButton
                navButton(icon: "message", title: "Mensajes", tab: .messages)
                navButton(icon: "person", title: "Perfil", tab: .profile)
            }
            .padding(.horizontal, 6)
            .padding(.top, 6)
            .padding(.bottom, 0)
        }
        .background(Color.black)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5), alignment: .top
        )
        .frame(height: tabBarHeight)
    }

    private var bottomBarDiscovery: some View {
        ZStack(alignment: .top) {
            HStack(spacing: -2) {
                backButtonDiscovery
                navButtonDiscovery(icon: "bell", title: "Notif", tab: .notifications)
                fireButton
                navButtonDiscovery(icon: "message", title: "Mensajes", tab: .messages)
                navButtonDiscovery(icon: "person", title: "Perfil", tab: .profile)
            }
            .padding(.horizontal, 6)
            .padding(.top, 6)
            .padding(.bottom, 0)
        }
        .background(Color.black)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5), alignment: .top
        )
        .frame(height: tabBarHeight)
    }

    private var cartButton: some View {
        centerAccentButton(icon: "cart.fill", title: "Carrito", color: .green) {
            withAnimation { showShopLoading = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    showShopLoading = false
                    showShop = true
                    inDiscoveryMode = true
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var backButtonDiscovery: some View {
        VStack(spacing: 1) {
            Button {
                withAnimation {
                    showShop = true
                }
            } label: {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(1.0)
            }
            Text("Regresar")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .cornerRadius(6)
    }

    private var fireButton: some View {
        centerAccentButton(icon: "flame.fill", title: "Fuego", color: .orange) {
            withAnimation {
                showShop = false
                selected = .feed
                inDiscoveryMode = false
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func navButton(icon: String, title: String, tab: Tab) -> some View {
        let isSelected = selected == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                    .symbolVariant(isSelected ? .fill : .none)
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                
                Text(title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(isSelected ? Color.white.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
    }

    private func navButtonDiscovery(icon: String, title: String, tab: Tab) -> some View {
        let isSelected = !showShop && selected == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = tab
                showShop = false
                inDiscoveryMode = true
            }
        } label: {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                    .symbolVariant(isSelected ? .fill : .none)
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                
                Text(title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(isSelected ? Color.white.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
    }

    private func centerAccentButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [color.opacity(0.25), color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle().stroke(color, lineWidth: 2)
                        )
                        .shadow(color: color.opacity(0.7), radius: 10, x: 0, y: 2)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 1)
                }
            }
            .offset(y: -10)
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Placeholder Screens (sin lógica por ahora)
private struct NotificationsScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sectionHeader("Notifications")
                ForEach(0..<8) { i in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "bell.fill").foregroundColor(.orange))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nueva promoción disponible")
                                .foregroundColor(.white)
                                .font(.subheadline.bold())
                            Text("Aprovecha descuentos hoy en tu zona")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        Spacer()
                        Text("hace \(i + 1)h").foregroundColor(.secondary).font(.caption2)
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct StoreScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sectionHeader("Store")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(0..<8) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.2))
                                .frame(height: 120)
                                .overlay(Image(systemName: "bag.fill").foregroundColor(.green))
                            Text("Combo Especial")
                                .foregroundColor(.white).font(.subheadline.bold())
                            Text("$9.99")
                                .foregroundColor(.green).font(.footnote.bold())
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}


private struct ProfileScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sectionHeader("Profile")
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.green.opacity(0.25))
                        .frame(width: 56, height: 56)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.green))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tu Nombre")
                            .foregroundColor(.white).font(.headline)
                        Text("Cliente")
                            .foregroundColor(.secondary).font(.caption)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 12) {
                    statCard("Pedidos", "124")
                    statCard("Favoritos", "32")
                    statCard("Reseñas", "18")
                }
                Button(action: { AuthService.shared.signOut() }) {
                    Text("Cerrar sesión")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func statCard(_ title: String, _ value: String) -> some View {
        VStack(spacing: 6) {
            Text(value).foregroundColor(.white).font(.title3.bold())
            Text(title).foregroundColor(.secondary).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private func sectionHeader(_ title: String) -> some View {
    HStack {
        Text(title).foregroundColor(.white).font(.title3.bold())
        Spacer()
    }
}
