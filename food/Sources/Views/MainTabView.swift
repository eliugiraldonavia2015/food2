import SwiftUI

struct MainTabView: View {
    enum Tab {
        case feed, notifications, store, messages, profile
    }

    @State private var selected: Tab = .feed
    @State private var showShopLoading = false
    @State private var showShop = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .feed: FeedView().padding(.bottom, 80)
                case .notifications: NotificationsScreen().padding(.bottom, 80)
                case .store: StoreScreen().padding(.bottom, 80)
                case .messages: MessagesScreen().padding(.bottom, 80)
                case .profile: ProfileScreen().padding(.bottom, 80)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())

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
            }

            if showShop {
                ShopOverlay(onClose: { withAnimation { showShop = false } })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .animation(.easeInOut, value: showShopLoading)
        .animation(.easeInOut, value: showShop)
        .preferredColorScheme(.dark)
    }

    private var bottomBar: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.9)
            HStack(spacing: 0) {
                navButton(icon: "house.fill", title: "Inicio", tab: .feed)
                navButton(icon: "bell.fill", title: "Notif", tab: .notifications)
                cartButton
                navButton(icon: "message.fill", title: "Mensajes", tab: .messages)
                navButton(icon: "person.fill", title: "Perfil", tab: .profile)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1), alignment: .top
        )
    }

    private var cartButton: some View {
        VStack(spacing: 4) {
            Button {
                withAnimation { showShopLoading = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        showShopLoading = false
                        showShop = true
                    }
                }
            } label: {
                Image(systemName: "cart.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.green)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .offset(y: -6)
            }
            Text("Carrito")
                .font(.caption2)
                .foregroundColor(.green)
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .green : .gray)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .green : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private struct ShopOverlay: View {
        let onClose: () -> Void
        var body: some View {
            VStack(spacing: 12) {
                Capsule().fill(Color.white.opacity(0.2)).frame(width: 48, height: 5).padding(.top, 8)
                Text("Tienda").foregroundColor(.white).font(.headline.bold())
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<8) { _ in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 64, height: 64)
                                    .overlay(Image(systemName: "bag.fill").foregroundColor(.green))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Combo del Día").foregroundColor(.white).font(.subheadline.bold())
                                    Text("Delicioso y económico").foregroundColor(.secondary).font(.caption)
                                }
                                Spacer()
                                Text("$9.99").foregroundColor(.green).font(.subheadline.bold())
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
                Button(action: onClose) {
                    Text("Cerrar")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .background(Color.black.opacity(0.6).ignoresSafeArea())
        }
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

private struct MessagesScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sectionHeader("Messages")
                ForEach(0..<10) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.25))
                            .frame(width: 42, height: 42)
                            .overlay(Image(systemName: "person.fill").foregroundColor(.blue))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Restaurante La Plaza")
                                .foregroundColor(.white).font(.subheadline.bold())
                            Text("Tu pedido está en camino 🚗")
                                .foregroundColor(.secondary).font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.gray)
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