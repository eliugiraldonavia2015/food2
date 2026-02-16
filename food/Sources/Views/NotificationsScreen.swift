import SwiftUI
import SDWebImageSwiftUI

struct NotificationsScreen: View {
    // MARK: - Models
    enum NotificationCategory: String, CaseIterable {
        case all = "Todo"
        case orders = "Pedidos"
        case interactions = "Interacciones"
        case system = "Sistema"
    }
    
    enum NotificationKind: CaseIterable {
        case like, follow, comment, order, promo, system
    }

    struct NotificationItem: Identifiable, Equatable {
        let id = UUID()
        let kind: NotificationKind
        let user: String
        let message: String
        let time: String
        let thumbnail: String?
        var unread: Bool
        
        var category: NotificationCategory {
            switch kind {
            case .order, .promo: return .orders
            case .like, .follow, .comment: return .interactions
            case .system: return .system
            }
        }
    }

    // MARK: - State
    @State private var selectedCategory: NotificationCategory = .all
    @State private var items: [NotificationItem] = [
        .init(kind: .order, user: "Food2 Delivery", message: "Tu pedido de Sushi Master ha sido entregado. ¡Disfruta!", time: "Ahora", thumbnail: nil, unread: true),
        .init(kind: .like, user: "camila_eats", message: "le gustó tu reseña de Tacos El Califa", time: "5 min", thumbnail: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80", unread: true),
        .init(kind: .follow, user: "chef_diego", message: "comenzó a seguirte", time: "20 min", thumbnail: "https://images.unsplash.com/photo-1583394838336-acd977736f90", unread: true),
        .init(kind: .comment, user: "pizzalover99", message: "comentó: '¿Dónde es esto? Se ve increíble 😍'", time: "1h", thumbnail: "https://images.unsplash.com/photo-1599566150163-29194dcaad36", unread: false),
        .init(kind: .promo, user: "Burger King", message: "¡2x1 en Whoppers hoy! 🍔", time: "3h", thumbnail: "https://images.unsplash.com/photo-1571091718767-18b5b1457add", unread: false),
        .init(kind: .system, user: "Soporte", message: "Bienvenido a la nueva experiencia Food2", time: "Ayer", thumbnail: nil, unread: false),
        .init(kind: .like, user: "andrea_f", message: "le gustó tu foto", time: "Ayer", thumbnail: "https://images.unsplash.com/photo-1494790108377-be9c29b29330", unread: false),
        .init(kind: .follow, user: "carlos_g", message: "comenzó a seguirte", time: "Ayer", thumbnail: nil, unread: false)
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(NotificationCategory.allCases, id: \.self) { category in
                                CategoryPill(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { withAnimation { selectedCategory = category } }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    .zIndex(1)
                    
                    // Notifications List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            let filteredItems = items.filter { selectedCategory == .all || $0.category == selectedCategory }
                            
                            if filteredItems.isEmpty {
                                emptyState
                            } else {
                                ForEach(filteredItems) { item in
                                    ModernNotificationRow(item: item)
                                        .transition(.opacity)
                                }
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Actividad")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: markAllAsRead) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("Sin notificaciones")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private func markAllAsRead() {
        withAnimation {
            for i in 0..<items.count {
                items[i].unread = false
            }
        }
    }
}

// MARK: - Components

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color(uiColor: .systemGray6))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ModernNotificationRow: View {
    let item: NotificationsScreen.NotificationItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Avatar + Badge
            ZStack(alignment: .bottomTrailing) {
                if let thumb = item.thumbnail, let url = URL(string: thumb) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        )
                }
                
                // Badge Icon
                Image(systemName: badgeIcon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(badgeColor)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 4) {
                    Text(item.user)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                    
                    if item.kind == .system {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(item.time)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Text(item.message)
                    .font(.system(size: 14))
                    .foregroundColor(item.unread ? .black : .gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if item.kind == .follow {
                    Button(action: {}) {
                        Text("Seguir también")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
            }
            
            // Post Thumbnail (if applicable)
            if item.kind == .like || item.kind == .comment {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Unread Dot
            if item.unread {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(item.unread ? Color.blue.opacity(0.03) : Color.white)
        .contentShape(Rectangle())
    }
    
    private var badgeIcon: String {
        switch item.kind {
        case .like: return "heart.fill"
        case .follow: return "person.fill"
        case .comment: return "bubble.left.fill"
        case .order: return "bag.fill"
        case .promo: return "tag.fill"
        case .system: return "bell.fill"
        }
    }
    
    private var badgeColor: Color {
        switch item.kind {
        case .like: return .red
        case .follow: return .blue
        case .comment: return .green
        case .order: return .orange
        case .promo: return .purple
        case .system: return .black
        }
    }
}
