import SwiftUI
import SDWebImageSwiftUI

struct NotificationsScreen: View {
    // MARK: - Models
    enum NotificationKind: CaseIterable {
        case like, follow, comment, order, promo, system
    }

    struct NotificationItem: Identifiable {
        let id = UUID()
        let kind: NotificationKind
        let user: String
        let message: String
        let time: String
        let thumbnail: String?
        var unread: Bool
    }

    // MARK: - State
    @State private var items: [NotificationItem] = [
        .init(kind: .order, user: "Food2 Delivery", message: "Tu pedido de Sushi Master ha sido entregado. ¡Disfruta!", time: "Ahora", thumbnail: nil, unread: true),
        .init(kind: .like, user: "camila_eats", message: "le gustó tu reseña de Tacos El Califa", time: "Hace 5 min", thumbnail: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80", unread: true),
        .init(kind: .follow, user: "chef_diego", message: "comenzó a seguirte", time: "Hace 20 min", thumbnail: "https://images.unsplash.com/photo-1583394838336-acd977736f90", unread: true),
        .init(kind: .comment, user: "pizzalover99", message: "comentó: '¿Dónde es esto? Se ve increíble 😍'", time: "Hace 1 hora", thumbnail: "https://images.unsplash.com/photo-1599566150163-29194dcaad36", unread: false),
        .init(kind: .promo, user: "Burger King", message: "¡2x1 en Whoppers hoy! 🍔", time: "Hace 3 horas", thumbnail: "https://images.unsplash.com/photo-1571091718767-18b5b1457add", unread: false),
        .init(kind: .system, user: "Soporte", message: "Bienvenido a la nueva experiencia Food2", time: "Ayer", thumbnail: nil, unread: false),
        .init(kind: .like, user: "andrea_f", message: "le gustó tu foto", time: "Ayer", thumbnail: "https://images.unsplash.com/photo-1494790108377-be9c29b29330", unread: false),
        .init(kind: .follow, user: "carlos_g", message: "comenzó a seguirte", time: "Ayer", thumbnail: nil, unread: false)
    ]
    
    @State private var animateList = false

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Section: New
                    if items.contains(where: { $0.unread }) {
                        sectionHeader("Nuevas")
                        ForEach(items.filter { $0.unread }) { item in
                            NotificationRow(item: item)
                                .transition(.opacity.combined(with: .slide))
                        }
                    }
                    
                    // Section: Earlier
                    if items.contains(where: { !$0.unread }) {
                        sectionHeader("Anteriores")
                            .padding(.top, 10)
                        ForEach(items.filter { !$0.unread }) { item in
                            NotificationRow(item: item)
                                .transition(.opacity.combined(with: .slide))
                        }
                    }
                }
                .padding(.bottom, 80) // Space for TabBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: markAllAsRead) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                animateList = true
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private func markAllAsRead() {
        withAnimation {
            for i in 0..<items.count {
                items[i].unread = false
            }
        }
    }
}

// MARK: - Subviews
struct NotificationRow: View {
    let item: NotificationsScreen.NotificationItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icon / Avatar
            ZStack(alignment: .bottomTrailing) {
                if let thumb = item.thumbnail, let url = URL(string: thumb) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                // Badge Type
                NotificationTypeBadge(kind: item.kind)
                    .offset(x: 4, y: 4)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(item.user)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(item.time)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Text(item.message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary) // Gray for read
                    .foregroundColor(item.unread ? .primary : .secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Unread Indicator
            if item.unread {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(item.unread ? Color.blue.opacity(0.05) : Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct NotificationTypeBadge: View {
    let kind: NotificationsScreen.NotificationKind
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
                .shadow(radius: 1)
            
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(4)
                .background(iconColor)
                .clipShape(Circle())
        }
    }
    
    private var iconName: String {
        switch kind {
        case .like: return "heart.fill"
        case .follow: return "person.fill"
        case .comment: return "bubble.left.fill"
        case .order: return "bag.fill"
        case .promo: return "tag.fill"
        case .system: return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch kind {
        case .like: return .red
        case .follow: return .blue
        case .comment: return .green
        case .order: return .orange
        case .promo: return .purple
        case .system: return .gray
        }
    }
}
