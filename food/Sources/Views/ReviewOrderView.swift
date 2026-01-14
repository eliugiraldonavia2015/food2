import SwiftUI

struct ReviewOrderView: View {
    let subtotal: Double
    let onClose: () -> Void
    let onPlaceOrder: () -> Void

    @State private var instructions: String = ""
    @State private var selectedTipPercent: Int? = 10

    private let deliveryCost: Double = 0

    private var tipAmount: Double {
        guard let pct = selectedTipPercent else { return 0 }
        return subtotal * (Double(pct) / 100.0)
    }

    private var total: Double { subtotal + deliveryCost + tipAmount }

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
                        costsSection
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomButtonBar }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: onClose) {
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
        VStack(spacing: 10) {
            sectionHeader(title: "DIRECCIÓN DE ENTREGA", trailing: "Cambiar", trailingAction: {})
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.green)
                            .font(.system(size: 16, weight: .bold))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Mi Casa")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                    Text("Av. Paseo de la Reforma 222, Juárez,\nCuauhtémoc, 06600 Ciudad de México, CDMX")
                        .foregroundColor(.gray)
                        .font(.system(size: 12, weight: .regular))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var paymentSection: some View {
        VStack(spacing: 10) {
            sectionHeader(title: "MÉTODO DE PAGO", trailing: "Cambiar", trailingAction: {})
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.10))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.black.opacity(0.8))
                            .font(.system(size: 16, weight: .bold))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Visa •••• 4242")
                        .foregroundColor(.black)
                        .font(.system(size: 14, weight: .bold))
                    Text("VISA DÉBITO")
                        .foregroundColor(.gray)
                        .font(.system(size: 12, weight: .semibold))
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(14)
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var instructionsSection: some View {
        VStack(spacing: 10) {
            sectionHeader(title: "INSTRUCCIONES ESPECIALES")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.gray.opacity(0.06))
                    .frame(height: 110)

                if instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Ej. El timbre no funciona, llamar al llegar...")
                        .foregroundColor(.gray.opacity(0.8))
                        .font(.system(size: 13, weight: .regular))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }

                TextEditor(text: $instructions)
                    .foregroundColor(.black)
                    .font(.system(size: 13, weight: .regular))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .scrollContentBackground(.hidden)
            }
        }
    }

    private var tipSection: some View {
        VStack(spacing: 10) {
            sectionHeader(title: "PROPINA PARA EL REPARTIDOR", trailing: "Opcional", trailingColor: .gray.opacity(0.8))
            HStack(spacing: 10) {
                tipChip(title: "10%", percent: 10)
                tipChip(title: "15%", percent: 15)
                tipChip(title: "20%", percent: 20)
                tipChip(title: "Otro", percent: nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func tipChip(title: String, percent: Int?) -> some View {
        let isSelected = selectedTipPercent == percent
        return Button(action: { selectedTipPercent = percent }) {
            Text(title)
                .foregroundColor(isSelected ? .white : .black)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Color.fuchsia : Color.gray.opacity(0.10))
                .clipShape(Capsule())
        }
    }

    private var costsSection: some View {
        VStack(spacing: 10) {
            sectionHeader(title: "RESUMEN DE COSTOS")
            VStack(spacing: 8) {
                costsRow(title: "Subtotal", value: priceText(subtotal), valueColor: .black)
                costsRow(title: "Costo de envío", value: deliveryCost <= 0 ? "¡GRATIS!" : priceText(deliveryCost), valueColor: deliveryCost <= 0 ? .green : .black)
                costsRow(title: "Propina", value: tipAmount <= 0 ? "—" : priceText(tipAmount), valueColor: .black)

                Divider()
                    .overlay(Color.gray.opacity(0.15))
                    .padding(.vertical, 2)

                HStack(alignment: .firstTextBaseline) {
                    Text("Total")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Text(priceText(total))
                        .foregroundColor(.fuchsia)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .padding(14)
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func costsRow(title: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .font(.system(size: 13, weight: .bold))
        }
    }

    private func sectionHeader(title: String, trailing: String? = nil, trailingColor: Color = .fuchsia, trailingAction: (() -> Void)? = nil) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.6)
            Spacer()
            if let trailing {
                Button(action: { trailingAction?() }) {
                    Text(trailing)
                        .foregroundColor(trailingColor)
                        .font(.system(size: 12, weight: .bold))
                }
            }
        }
    }

    private var bottomButtonBar: some View {
        VStack(spacing: 10) {
            Button(action: onPlaceOrder) {
                Text("Pedir")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }

    private func priceText(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

