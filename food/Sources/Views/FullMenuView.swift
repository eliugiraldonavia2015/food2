import SwiftUI
import SDWebImageSwiftUI

struct FullMenuView: View {
    let restaurantName: String
    let coverUrl: String
    let avatarUrl: String
    let location: String
    let branchName: String?
    let distanceKm: Double?
    @Environment(\.dismiss) private var dismiss
    @State private var activeTab: String = "Todo"
    private let tabs = ["Todo","Popular","Combos","Entradas","Especiales","Sopas"]
    private struct MenuItem: Identifiable { let id = UUID(); let title: String; let url: String }
    private let menuData: [String: [MenuItem]] = [
        "Popular": [
            .init(title: "Pizza", url: "https://images.unsplash.com/photo-1601924638867-3ec3b1f7c2d7"),
            .init(title: "Burger", url: "https://images.unsplash.com/photo-1550547660-d9450f859349"),
            .init(title: "Pasta", url: "https://images.unsplash.com/photo-1525755662778-989d0524087e")
        ],
        "Combos": [
            .init(title: "Combo Taco", url: "https://images.unsplash.com/photo-1612872086026-3b72c8585f63"),
            .init(title: "Combo Sushi", url: "https://images.unsplash.com/photo-1553621042-f6e147245754"),
            .init(title: "Combo Burger", url: "https://images.unsplash.com/photo-1550547660-d9450f859349")
        ],
        "Entradas": [
            .init(title: "Nachos", url: "https://images.unsplash.com/photo-1586190848861-99aa4a171e90"),
            .init(title: "Edamame", url: "https://images.unsplash.com/photo-1551218808-94e220e084d2"),
            .init(title: "Aros", url: "https://images.unsplash.com/photo-1554118811-1e0d58224f24")
        ],
        "Especiales": [
            .init(title: "Chef Roll", url: "https://images.unsplash.com/photo-1546069901-5ec6a79120b0"),
            .init(title: "Trufa Pasta", url: "https://images.unsplash.com/photo-1525755662778-989d0524087e"),
            .init(title: "BBQ", url: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd")
        ],
        "Sopas": [
            .init(title: "Ramen", url: "https://images.unsplash.com/photo-1543353071-873f17a7a5c0"),
            .init(title: "Miso", url: "https://images.unsplash.com/photo-1525755662778-989d0524087e"),
            .init(title: "Caldo", url: "https://images.unsplash.com/photo-1504754524776-8f4f37710ca2")
        ]
    ]
    private var allItems: [MenuItem] { Array(menuData.values.joined()) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    infoRow
                    branchDistance
                    categoryTabs
                    sectionsStack
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                
            }
            .ignoresSafeArea(edges: .top)
            checkoutBar
            topBar
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            WebImage(url: URL(string: coverUrl))
                .resizable()
                .indicator(.activity)
                .aspectRatio(contentMode: .fill)
                .frame(height: 240)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.black.opacity(0.0), location: 0.0),
                            .init(color: Color.black.opacity(0.0), location: 0.55),
                            .init(color: Color.black.opacity(0.30), location: 0.65),
                            .init(color: Color.black.opacity(0.75), location: 0.75),
                            .init(color: Color.black.opacity(1.0), location: 0.85),
                            .init(color: Color.black.opacity(1.0), location: 0.92),
                            .init(color: Color.black.opacity(1.0), location: 0.97),
                            .init(color: Color.black.opacity(1.0), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            HStack(alignment: .center, spacing: 12) {
                WebImage(url: URL(string: avatarUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.green, lineWidth: 2))
                VStack(alignment: .leading, spacing: 6) {
                    Text(restaurantName)
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                    Text(location)
                        .foregroundColor(.white.opacity(0.9))
                        .font(.subheadline)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, -16)
        .ignoresSafeArea(edges: .top)
    }

    private var infoRow: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.06))
            .frame(height: 90)
            .overlay(
                HStack(spacing: 0) {
                    infoItem(title: "Tiempo", value: "25-35 min", system: "clock", tint: .green)
                        .frame(maxWidth: .infinity)
                    infoItem(title: "Envío", value: "$2.99", system: "dollarsign.circle", tint: .green)
                        .frame(maxWidth: .infinity)
                    infoItem(title: "Rating", value: "4.8", system: "star.fill", tint: Color.orange)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            )
    }

    private func infoItem(title: String, value: String, system: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: system)
                    .foregroundColor(tint)
                Text(title)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
            }
            Text(value)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }

    private var branchDistance: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.06))
            .frame(height: 84)
            .overlay(
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sucursal seleccionada")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                        Text(branchName ?? location)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Distancia")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                        Text(String(format: "%.1f km", distanceKm ?? 2.3))
                            .foregroundColor(.green)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .padding(.horizontal, 16)
            )
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tabs, id: \.self) { t in
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { activeTab = t } }) {
                        Text(t)
                            .foregroundColor(activeTab == t ? .black : .white)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(activeTab == t ? Color.green : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        HStack { Text(t).foregroundColor(.white).font(.headline); Spacer() }
    }

    private var sectionsStack: some View {
        VStack(spacing: 20) {
            section("Todo", items: allItems)
            section("Popular", items: menuData["Popular"] ?? [])
            section("Combos", items: menuData["Combos"] ?? [])
            section("Entradas", items: menuData["Entradas"] ?? [])
            section("Especiales", items: menuData["Especiales"] ?? [])
            section("Sopas", items: menuData["Sopas"] ?? [])
        }
    }

    private func section(_ title: String, items: [MenuItem]) -> some View {
        VStack(spacing: 12) {
            sectionTitle(title)
            HStack(spacing: 12) {
                ForEach(items.prefix(3)) { it in
                    menuCard(title: it.title, url: it.url)
                }
            }
            .frame(height: 170)
        }
    }

    private func menuCard(title: String, url: String) -> some View {
        VStack(spacing: 6) {
            WebImage(url: URL(string: url))
                .resizable()
                .indicator(.activity)
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.4), lineWidth: title == "Pizza" ? 2 : 0))
            Text(title)
                .foregroundColor(.white)
                .font(.footnote)
        }
    }

    private var checkoutBar: some View {
        VStack {
            Spacer()
            Button(action: {}) {
                Text("Ir al Checkout • $15.99")
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
                }
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "cart").foregroundColor(.white))
                    Circle()
                        .fill(Color.green)
                        .frame(width: 18, height: 18)
                        .overlay(Text("1").foregroundColor(.white).font(.caption2.bold()))
                        .offset(x: 8, y: -8)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 26)
            .padding(.top, 8)
            Spacer()
        }
    }
}

