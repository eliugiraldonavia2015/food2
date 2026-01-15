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
    @State private var addressTitle: String = "Mi Casa"
    @State private var addressDetail: String = "Av. Paseo de la Reforma 222, Juárez,\nCuauhtémoc, 06600 Ciudad de México, CDMX"
    @State private var paymentTitle: String = "•••• 4242"
    @State private var paymentSubtitle: String = "VISA DÉBITO"
    @State private var instructions: String = ""
    @State private var tipSelection: TipSelection = .p10
    @State private var customTipText: String = ""
    @State private var placingOrder = false
    @State private var showPlaced = false
    
    private enum TipSelection: Hashable {
        case p10
        case p15
        case p20
        case other
        
        var percentValue: Double? {
            switch self {
            case .p10: return 0.10
            case .p15: return 0.15
            case .p20: return 0.20
            case .other: return nil
            }
        }
    }
    
    private var subtotal: Double { total }
    private var shipping: Double { 0 }
    private var tip: Double {
        if let p = tipSelection.percentValue {
            return subtotal * p
        }
        let sanitized = customTipText.replacingOccurrences(of: ",", with: ".")
        return Double(sanitized) ?? 0
    }
    private var grandTotal: Double { subtotal + shipping + tip }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        addressSection
                        paymentSection
                        instructionsSection
                        tipSection
                        costSummarySection
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 18)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .background(Color.white)
        .preferredColorScheme(.light)
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

            Text("Revisar Pedido")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .bold))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("DIRECCIÓN DE ENTREGA")
            Button(action: {}) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.fuchsia.opacity(0.14))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.fuchsia)
                                .font(.system(size: 14, weight: .bold))
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(addressTitle)
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .bold))
                        Text(addressDetail)
                            .foregroundColor(.gray)
                            .font(.system(size: 11, weight: .semibold))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("MÉTODO DE PAGO")
            Button(action: {}) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 36, height: 28)
                        .overlay(
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 13, weight: .bold))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(paymentTitle)
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .bold))
                        Text(paymentSubtitle)
                            .foregroundColor(.gray)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("INSTRUCCIONES ESPECIALES")
            ZStack(alignment: .topLeading) {
                TextEditor(text: $instructions)
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .semibold))
                    .modifier(HideTextEditorBackground())
                    .frame(height: 90)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                if instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Ej. El timbre no funciona, llamar al llegar...")
                        .foregroundColor(.gray.opacity(0.8))
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("PROPINA PARA EL REPARTIDOR")
                    .foregroundColor(.gray)
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Text("Opcional")
                    .foregroundColor(.gray.opacity(0.8))
                    .font(.system(size: 12, weight: .bold))
            }
            
            HStack(spacing: 10) {
                tipChip("10%", isSelected: tipSelection == .p10) { tipSelection = .p10 }
                tipChip("15%", isSelected: tipSelection == .p15) { tipSelection = .p15 }
                tipChip("20%", isSelected: tipSelection == .p20) { tipSelection = .p20 }
                tipChip("Otro", isSelected: tipSelection == .other) { tipSelection = .other }
                Spacer(minLength: 0)
            }
            
            if tipSelection == .other {
                HStack(spacing: 10) {
                    Text("$")
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .bold))
                    TextField("0.00", text: $customTipText)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            Text("La propina es para tu repartidor.")
                .foregroundColor(.gray.opacity(0.8))
                .font(.system(size: 12, weight: .semibold))
        }
    }
    
    private var costSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESUMEN DE COSTOS")
                .foregroundColor(.gray)
                .font(.system(size: 12, weight: .bold))
            
            VStack(spacing: 10) {
                costRow(title: "Subtotal", value: priceText(subtotal), valueColor: .black)
                costRow(title: "Costo de envío", value: shipping == 0 ? "¡GRATIS!" : priceText(shipping), valueColor: shipping == 0 ? .green : .black)
                costRow(title: "Propina", value: priceText(tip), valueColor: .black)
                Divider().overlay(Color.gray.opacity(0.18))
                costRow(title: "Total", value: priceText(grandTotal), valueColor: .black, isEmphasis: true, totalColor: .green)
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: placeOrder) {
                ZStack {
                    Text(placingOrder ? "Enviando..." : "Realizar Pedido")
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
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 12, weight: .bold))
            Spacer()
            Button(action: {}) {
                Text("Cambiar")
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }
    
    private func tipChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(isSelected ? .white : .black)
                .font(.system(size: 13, weight: .bold))
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(isSelected ? Color.fuchsia : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.gray.opacity(0.18), lineWidth: isSelected ? 0 : 1))
        }
    }
    
    private func costRow(title: String, value: String, valueColor: Color, isEmphasis: Bool = false, totalColor: Color? = nil) -> some View {
        HStack {
            Text(title)
                .foregroundColor(isEmphasis ? .black : .gray)
                .font(.system(size: isEmphasis ? 15 : 13, weight: isEmphasis ? .bold : .semibold))
            Spacer()
            Text(value)
                .foregroundColor(totalColor ?? valueColor)
                .font(.system(size: isEmphasis ? 15 : 13, weight: isEmphasis ? .bold : .bold))
        }
    }
}

private struct HideTextEditorBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

