import SwiftUI
import SDWebImageSwiftUI

struct CheckoutView: View {
    struct LineItem: Identifiable, Hashable {
        let id: String
        let title: String
        let subtitle: String
        let imageUrl: String
        let unitPrice: Double
        let quantity: Int
    }

    let restaurantName: String
    let items: [LineItem]
    let total: Double

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPaymentMethod: PaymentMethod = .card
    @State private var address: String = "Av. Reforma 123, CDMX"
    @State private var placingOrder = false
    @State private var showPlaced = false

    enum PaymentMethod: String, CaseIterable, Identifiable {
        case card = "Tarjeta"
        case cash = "Efectivo"
        case applePay = "Apple Pay"

        var id: String { rawValue }
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
                        header
                        itemsPanel
                        addressPanel
                        paymentPanel
                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .alert("Pedido enviado", isPresented: $showPlaced) {
            Button("OK") { dismiss() }
        } message: {
            Text("Tu pedido fue enviado al restaurante.")
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

            Text("Checkout")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .bold))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.green.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "storefront.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .bold))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Pedido a")
                    .foregroundColor(.gray)
                    .font(.system(size: 12, weight: .semibold))
                Text(restaurantName)
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var itemsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tu orden")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                ForEach(items) { item in
                    itemRow(item)
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func itemRow(_ item: LineItem) -> some View {
        let lineTotal = Double(item.quantity) * item.unitPrice

        return HStack(spacing: 12) {
            WebImage(url: URL(string: item.imageUrl))
                .resizable()
                .indicator(.activity)
                .aspectRatio(contentMode: .fill)
                .frame(width: 54, height: 54)
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
                HStack(spacing: 8) {
                    Text("x\(item.quantity)")
                        .foregroundColor(.gray)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text(priceText(lineTotal))
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var addressPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dirección")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .bold))

            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 14, weight: .bold))
                TextField("Dirección de entrega", text: $address)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
            }
            .padding(14)
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var paymentPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pago")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .bold))

            VStack(spacing: 10) {
                ForEach(PaymentMethod.allCases) { method in
                    Button(action: { selectedPaymentMethod = method }) {
                        HStack {
                            Text(method.rawValue)
                                .foregroundColor(.black)
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            if selectedPaymentMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18, weight: .bold))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.35))
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Total")
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text(priceText(total))
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)

            Button(action: placeOrder) {
                ZStack {
                    Text(placingOrder ? "Enviando..." : "Confirmar pedido")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .opacity(placingOrder ? 0.7 : 1)
                }
            }
            .disabled(placingOrder || items.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }

    private func placeOrder() {
        guard !placingOrder else { return }
        placingOrder = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            placingOrder = false
            showPlaced = true
        }
    }

    private func priceText(_ value: Double) -> String {
        let formatted = String(format: "%.2f", value)
        return "$\(formatted)"
    }
}

