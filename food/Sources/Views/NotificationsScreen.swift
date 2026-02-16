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
        .init(kind: .order, user: "Food2 Delivery", message: "Tu pedido de Sushi Master ha sido entregado.", time: "Ahora", thumbnail: nil, unread: true),
        .init(kind: .like, user: "camila_eats", message: "le gustó tu reseña.", time: "5 min", thumbnail: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80", unread: true),
        .init(kind: .follow, user: "chef_diego", message: "comenzó a seguirte.", time: "20 min", thumbnail: "https://images.unsplash.com/photo-1583394838336-acd977736f90", unread: true),
        .init(kind: .comment, user: "pizzalover99", message: "comentó: '¿Dónde es esto? 😍'", time: "1h", thumbnail: "https://images.unsplash.com/photo-1599566150163-29194dcaad36", unread: false),
        .init(kind: .promo, user: "Burger King", message: "¡2x1 en Whoppers hoy! 🍔", time: "3h", thumbnail: "https://images.unsplash.com/photo-1571091718767-18b5b1457add", unread: false),
        .init(kind: .system, user: "Soporte", message: "Bienvenido a Food2.", time: "Ayer", thumbnail: nil, unread: false),
        .init(kind: .like, user: "andrea_f", message: "le gustó tu foto.", time: "Ayer", thumbnail: "https://images.unsplash.com/photo-1494790108377-be9c29b29330", unread: false),
        .init(kind: .follow, user: "carlos_g", message: "comenzó a seguirte.", time: "Ayer", thumbnail: nil, unread: false)
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        MinimalNotificationRow(item: item)
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
        HStack(alignment: .center, spacing: 14) {
            // Avatar
            ZStack {
                if let thumb = item.thumbnail, let url = URL(string: thumb) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        )
                }
                
                // Blue Dot for unread (Instagram style: small dot on avatar right side)
                if item.unread {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 14, y: -14)
                }
            }
            
            // Text Content
            HStack(spacing: 4) {
                Text(item.user)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                +
                Text(" \(item.message)")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                +
                Text(" \(item.time)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            
            Spacer()
            
            // Trailing Action/Thumbnail
            if item.kind == .follow {
                Button(action: {}) {
                    Text("Seguir")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            } else if item.kind == .like || item.kind == .comment {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8) // Reduced vertical padding for compact look
        .background(Color.white)
    }
}
