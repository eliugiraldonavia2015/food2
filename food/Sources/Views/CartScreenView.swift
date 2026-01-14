import SwiftUI
import SDWebImageSwiftUI

struct CartScreenView: View {
    struct CartItem: Identifiable, Hashable {
        let id: String
        let title: String
        let subtitle: String
        let price: Double
        let imageUrl: String
    }

    let restaurantName: String
    let items: [CartItem]
    @Binding var quantities: [String: Int]
        
    private let summaryFixedHeight: CGFloat = 74

    @Environment(\.dismiss) private var dismiss
    @State private var showReviewOrder: Bool = false

    private var cartItems: [CartItem] {
        items.filter { (quantities[$0.id] ?? 0) > 0 }
    }

    private var suggestedItems: [CartItem] {
        let inCartIds = Set(cartItems.map(\.id))
        return items.filter { !inCartIds.contains($0.id) }.prefix(8).map { $0 }
    }

    private var subtotal: Double {
        var total: Double = 0
        for item in items {
            let qty = quantities[item.id] ?? 0
            if qty > 0 {
                total += Double(qty) * item.price
            }
        }
        return total
    }

    private var total: Double { subtotal }
    
    private var summaryMaxHeight: CGFloat {
        UIScreen.main.bounds.height * 0.4
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .background(Color.white)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        restaurantHeader
                        cartList
                        suggestedSection
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomSummaryArea }
        .fullScreenCover(isPresented: $showReviewOrder) {
            ReviewOrderView(subtotal: total)
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 40, height: 40)
                }
                Spacer()
            }

            Text("Mi Carrito")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .bold))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var restaurantHeader: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.green.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "storefront.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .bold))
                )

            Text(restaurantName)
                .foregroundColor(.black)
                .font(.system(size: 16, weight: .bold))

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var cartList: some View {
        VStack(spacing: 12) {
            ForEach(cartItems) { item in
                cartRow(item)
            }
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func cartRow(_ item: CartItem) -> some View {
        let qty = quantities[item.id] ?? 0
        let lineTotal = Double(qty) * item.price

        return HStack(spacing: 12) {
            itemImage(item.imageUrl)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)

                Text(item.subtitle.isEmpty ? " " : item.subtitle)
                    .foregroundColor(.gray)
                    .font(.system(size: 11))
                    .lineLimit(1)

                HStack(spacing: 10) {
                    stepperControl(itemId: item.id)
                    Text(priceText(lineTotal))
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                }
                .padding(.top, 4)
            }

            Button(action: { quantities[item.id] = 0 }) {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .bold))
                    )
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 10)
    }

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Se te antoja algo más?")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestedItems) { item in
                        suggestedCard(item)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.top, 4)
    }

    private func suggestedCard(_ item: CartItem) -> some View {
        let qty = quantities[item.id] ?? 0

        return VStack(alignment: .leading, spacing: 8) {
            itemImage(item.imageUrl)
                .frame(width: 150, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(item.title)
                .foregroundColor(.black)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)

            HStack {
                Text(priceText(item.price))
                    .foregroundColor(.black)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }
        }
        .padding(10)
        .frame(width: 170, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        .overlay(alignment: .bottomTrailing) {
            suggestedQuantityControl(itemId: item.id, quantity: qty)
                .padding(10)
        }
    }

    private var bottomSummaryArea: some View {
        VStack(spacing: 10) {
            totalsPanel
            checkoutButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private var totalsPanel: some View {
        totalsFooter
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(height: summaryFixedHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }
    
    private var totalsFooter: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Subtotal")
                    .foregroundColor(.gray)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(priceText(subtotal))
                    .foregroundColor(.black)
                    .font(.system(size: 13, weight: .bold))
            }
            HStack {
                Text("Costo de envío")
                    .foregroundColor(.gray)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("¡GRATIS!")
                    .foregroundColor(.green)
                    .font(.system(size: 13, weight: .bold))
            }
            Divider()
                .overlay(Color.gray.opacity(0.15))
            HStack(alignment: .firstTextBaseline) {
                Text("Total")
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text(priceText(total))
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
    
    private var checkoutButton: some View {
        Button(action: { showReviewOrder = true }) {
            Text("Ir a checkout • \(priceText(total))")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func stepperControl(itemId: String) -> some View {
        let qty = quantities[itemId] ?? 0
        return HStack(spacing: 12) {
            Button(action: {
                let updated = max(0, qty - 1)
                quantities[itemId] = updated == 0 ? nil : updated
            }) {
                Text("−")
                    .foregroundColor(.green)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 34, height: 34)
            }

            Text("\(qty)")
                .foregroundColor(.black)
                .font(.system(size: 14, weight: .bold))
                .frame(minWidth: 14)

            Button(action: {
                quantities[itemId] = min(99, qty + 1)
            }) {
                Text("+")
                    .foregroundColor(.green)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 34, height: 34)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .background(Color.gray.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func suggestedQuantityControl(itemId: String, quantity: Int) -> some View {
        Group {
            if quantity <= 0 {
                Button(action: { quantities[itemId] = 1 }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        )
                }
            } else {
                HStack(spacing: 10) {
                    Button(action: {
                        let updated = max(0, quantity - 1)
                        quantities[itemId] = updated == 0 ? nil : updated
                    }) {
                        Image(systemName: "minus")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(Circle())
                    }

                    Text("\(quantity)")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                        .frame(minWidth: 14)

                    Button(action: { quantities[itemId] = min(99, quantity + 1) }) {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Color.gray.opacity(0.10))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
        }
    }

    private func priceText(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func itemImage(_ urlString: String) -> some View {
        Group {
            if let url = URL(string: urlString), !urlString.isEmpty {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

