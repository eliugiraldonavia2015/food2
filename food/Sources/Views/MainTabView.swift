import SwiftUI

struct MainTabView: View {
    enum Tab {
        case feed, notifications, store, messages, profile
    }

    @State private var selected: Tab = .feed

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

            bottomBar
        }
        .preferredColorScheme(.dark)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            navButton(icon: "house.fill", title: "Home", tab: .feed)
            navButton(icon: "bell.fill", title: "Notifications", tab: .notifications)
            navButton(icon: "bag.fill", title: "Store", tab: .store)
            navButton(icon: "message.fill", title: "Messages", tab: .messages)
            navButton(icon: "person.fill", title: "Profile", tab: .profile)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)
        )
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