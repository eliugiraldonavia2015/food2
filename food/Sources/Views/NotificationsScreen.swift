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
    
    struct NotificationSection: Identifiable {
        let id = UUID()
        let title: String
        let items: [NotificationItem]
    }

    // MARK: - State
    // Simulating grouped data
    @State private var sections: [NotificationSection] = [
        .init(title: "Nuevo", items: [
            .init(kind: .order, user: "Food2 Delivery", message: "Tu pedido de Sushi Master ha sido entregado.", time: "Ahora", thumbnail: nil, unread: true),
            .init(kind: .like, user: "camila_eats", message: "le gustó tu reseña.", time: "5 min", thumbnail: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80", unread: true),
            .init(kind: .follow, user: "chef_diego", message: "comenzó a seguirte.", time: "20 min", thumbnail: "https://images.unsplash.com/photo-1583394838336-acd977736f90", unread: true)
        ]),
        .init(title: "Hoy", items: [
            .init(kind: .comment, user: "pizzalover99", message: "comentó: '¿Dónde es esto? 😍'", time: "1h", thumbnail: "https://images.unsplash.com/photo-1599566150163-29194dcaad36", unread: false),
            .init(kind: .promo, user: "Burger King", message: "¡2x1 en Whoppers hoy! 🍔", time: "3h", thumbnail: "https://images.unsplash.com/photo-1571091718767-18b5b1457add", unread: false)
        ]),
        .init(title: "Esta semana", items: [
            .init(kind: .system, user: "Soporte", message: "Bienvenido a Food2.", time: "Ayer", thumbnail: nil, unread: false),
            .init(kind: .like, user: "andrea_f", message: "le gustó tu foto.", time: "Ayer", thumbnail: "https://images.unsplash.com/photo-1494790108377-be9c29b29330", unread: false),
            .init(kind: .follow, user: "carlos_g", message: "comenzó a seguirte.", time: "Ayer", thumbnail: nil, unread: false)
        ])
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(section.title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                .padding(.bottom, 8)
                            
                            ForEach(section.items) { item in
                                MinimalNotificationRow(item: item)
                            }
                        }
                    }
                }
                .padding(.bottom, 80)
            }
            .navigationTitle("Actividad")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.white.ignoresSafeArea())
        }
    }
}

// MARK: - Components

struct MinimalNotificationRow: View {
    let item: NotificationsScreen.NotificationItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let thumb = item.thumbnail, let url = URL(string: thumb) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.gray)
                        )
                }
                
                // Blue Dot for unread
                if item.unread {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }
            
            // Text Content
            HStack(spacing: 4) {
                Text(item.user)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                +
                Text(" \(item.message)")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .fontWeight(.regular)
                +
                Text(" \(item.time)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure it takes available space
            
            // Trailing Action/Thumbnail
            if item.kind == .follow {
                Button(action: {}) {
                    Text("Seguir")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            } else if item.kind == .like || item.kind == .comment {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.white)
    }
}
