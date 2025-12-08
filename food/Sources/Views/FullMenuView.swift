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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    infoRow
                    branchDistance
                    categoryTabs
                    sectionTitle("Popular")
                    menuRow
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
            }
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
    }

    private var infoRow: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.06))
            .frame(height: 90)
            .overlay(
                HStack(spacing: 22) {
                    infoItem(title: "Tiempo", value: "25-35 min", system: "clock", tint: .green)
                    infoItem(title: "Envío", value: "$2.99", system: "dollarsign.circle", tint: .green)
                    infoItem(title: "Rating", value: "4.8", system: "star.fill", tint: Color.orange)
                    Spacer()
                }
                .padding(.horizontal, 16)
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
        .frame(width: 110, alignment: .leading)
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

    private var menuRow: some View {
        HStack(spacing: 12) {
            menuCard(title: "Pizza", url: "https://images.unsplash.com/photo-1601924638867-3ec3b1f7c2d7")
            menuCard(title: "Burger", url: "https://images.unsplash.com/photo-1550547660-d9450f859349")
            menuCard(title: "Pasta", url: "https://images.unsplash.com/photo-1525755662778-989d0524087e")
        }
        .frame(height: 170)
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
                        .offset(x: 10, y: -10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            Spacer()
        }
    }
}

