import SwiftUI
import SDWebImageSwiftUI

struct NotificationsScreen: View {
    // MARK: - Models
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
    
    // Restaurant Updates (Stories Style)
    struct RestaurantUpdate: Identifiable {
        let id = UUID()
        let name: String
        let logo: String
        let hasUpdate: Bool
    }
    
    let updates: [RestaurantUpdate] = [
        .init(name: "McDonald's", logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/McDonald%27s_Golden_Arches.svg/1200px-McDonald%27s_Golden_Arches.svg.png", hasUpdate: true),
        .init(name: "Starbucks", logo: "https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/1200px-Starbucks_Corporation_Logo_2011.svg.png", hasUpdate: true),
        .init(name: "KFC", logo: "https://upload.wikimedia.org/wikipedia/en/thumb/b/bf/KFC_logo.svg/1200px-KFC_logo.svg.png", hasUpdate: false),
        .init(name: "Domino's", logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Domino%27s_pizza_logo.svg/1200px-Domino%27s_pizza_logo.svg.png", hasUpdate: true)
    ]
    
    @State private var animateList = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. Force Solid Background to cover any parent black background
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            // 2. Main Content
            VStack(spacing: 0) {
                // Custom Navigation Bar for consistency and control
                customNavBar
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Restaurant Updates (Stories)
                        restaurantUpdatesSection
                            .padding(.top, 10)
                            .padding(.bottom, 5)
                        
                        Divider()
                            .padding(.bottom, 5)
                        
                        // Spacer for top padding
                        Spacer().frame(height: 10)
                        
                        // Section: New
                        let unreadItems = items.filter { $0.unread }
                        if !unreadItems.isEmpty {
                            sectionHeader("Nuevas")
                            ForEach(Array(unreadItems.enumerated()), id: \.element.id) { index, item in
                                NotificationRow(item: item)
                                    .opacity(animateList ? 1 : 0)
                                    .offset(y: animateList ? 0 : 20)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateList)
                            }
                        }
                        
                        // Section: Earlier
                        let readItems = items.filter { !$0.unread }
                        if !readItems.isEmpty {
                            sectionHeader("Anteriores")
                                .padding(.top, 10)
                            ForEach(Array(readItems.enumerated()), id: \.element.id) { index, item in
                                NotificationRow(item: item)
                                    .opacity(animateList ? 1 : 0)
                                    .offset(y: animateList ? 0 : 20)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2 + Double(index) * 0.05), value: animateList)
                            }
                        }
                    }
                    .padding(.bottom, 100) // Extra padding for bottom tab bar
                }
            }
        }
        .onAppear {
            animateList = true
        }
    }
    
    private var customNavBar: some View {
        HStack {
            Text("Notificaciones")
                .font(.system(size: 28, weight: .bold)) // Apple style large title
                .foregroundColor(.primary)
            Spacer()
            
            Button(action: markAllAsRead) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 244/255, green: 37/255, blue: 123/255)) // Brand Pink
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10) // Safe area padding adjusted if needed
        .padding(.bottom, 10)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private func markAllAsRead() {
        withAnimation {
            for i in 0..<items.count {
                items[i].unread = false
            }
        }
    }
    
    // MARK: - Components
    
    private var restaurantUpdatesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Add Story Button (Optional)
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .systemGray6))
                            .frame(width: 68, height: 68)
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Text("Mis Favoritos")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.leading, 20)
                
                // Restaurant Circles
                ForEach(updates) { update in
                    VStack(spacing: 6) {
                        ZStack {
                            // Ring
                            if update.hasUpdate {
                                Circle()
                                    .stroke(
                                        AngularGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 244/255, green: 37/255, blue: 123/255), // Brand Pink
                                                Color.orange
                                            ]),
                                            center: .center
                                        ),
                                        lineWidth: 2.5
                                    )
                                    .frame(width: 72, height: 72)
                            } else {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    .frame(width: 72, height: 72)
                            }
                            
                            // Image
                            if let url = URL(string: update.logo) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFit() // Logos usually fit better
                                    .padding(12)   // Padding inside circle for logo
                                    .frame(width: 64, height: 64)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                        
                        Text(update.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .frame(width: 70)
                    }
                }
            }
            .padding(.trailing, 20)
        }
    }
}

// MARK: - Subviews
struct NotificationRow: View {
    let item: NotificationsScreen.NotificationItem
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Action handling would go here
        }) {
            HStack(alignment: .center, spacing: 14) {
                // Icon / Avatar
                ZStack(alignment: .bottomTrailing) {
                    if let thumb = item.thumbnail, let url = URL(string: thumb) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(uiColor: .secondarySystemGroupedBackground), lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .frame(width: 52, height: 52)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
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
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(item.user)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(item.time)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(item.message)
                        .font(.system(size: 14))
                        .foregroundColor(item.unread ? .primary : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Unread Indicator
                if item.unread {
                    Circle()
                        .fill(Color(red: 244/255, green: 37/255, blue: 123/255))
                        .frame(width: 10, height: 10)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

struct NotificationTypeBadge: View {
    let kind: NotificationsScreen.NotificationKind
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .frame(width: 24, height: 24)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
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
        case .like: return Color(red: 255/255, green: 45/255, blue: 85/255) // Pink/Red
        case .follow: return Color(red: 0/255, green: 122/255, blue: 255/255) // Blue
        case .comment: return Color(red: 52/255, green: 199/255, blue: 89/255) // Green
        case .order: return Color(red: 255/255, green: 149/255, blue: 0/255) // Orange
        case .promo: return Color(red: 175/255, green: 82/255, blue: 222/255) // Purple
        case .system: return Color.gray
        }
    }
}

// Helper for button press state
struct ButtonPress: ViewModifier {
    var onPress: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress(true) }
                    .onEnded { _ in onPress(false) }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping (Bool) -> Void) -> some View {
        modifier(ButtonPress(onPress: onPress))
    }
}
