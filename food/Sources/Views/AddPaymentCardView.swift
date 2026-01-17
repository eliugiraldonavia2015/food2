import SwiftUI

struct AddPaymentCardView: View {
    let onSave: (PaymentMethodSelectionView.PaymentItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var holderName: String = ""
    @State private var cardNumber: String = ""
    @State private var expiry: String = ""
    @State private var cvv: String = ""
    @State private var saveForFuture = true

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        cardPreview
                            .padding(.top, 6)

                        sectionHeader("NOMBRE EN LA TARJETA")
                        field(placeholder: "Ej. Juan Pérez", text: $holderName)

                        sectionHeader("NÚMERO DE TARJETA")
                        field(placeholder: "0000 0000 0000 0000", text: $cardNumber, keyboard: .numberPad, trailingIcon: "creditcard.fill")
                            .onChange(of: cardNumber) { _, newValue in
                                cardNumber = formatCardNumber(newValue)
                            }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("FECHA DE EXPIRACIÓN")
                                field(placeholder: "MM/AA", text: $expiry, keyboard: .numberPad)
                                    .onChange(of: expiry) { _, newValue in
                                        expiry = formatExpiry(newValue)
                                    }
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("CVV")
                                field(placeholder: "123", text: $cvv, keyboard: .numberPad, trailingIcon: "info.circle")
                                    .onChange(of: cvv) { _, newValue in
                                        cvv = String(digitsOnly(newValue).prefix(4))
                                    }
                            }
                        }

                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Guardar para futuras compras")
                                    .foregroundColor(.black)
                                    .font(.system(size: 15, weight: .bold))
                                Text("Tus datos se guardan de forma segura")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Spacer()
                            Toggle("", isOn: $saveForFuture)
                                .labelsHidden()
                                .tint(.brandGreen)
                        }
                        .padding(.top, 2)

                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.brandGreen)
                                .font(.system(size: 14, weight: .bold))
                            Text("PAGO ENCRIPTADO SSL DE 256 BITS")
                                .foregroundColor(.gray)
                                .font(.system(size: 12, weight: .bold))
                            Spacer()
                        }
                        .padding(.top, 2)

                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .preferredColorScheme(.light)
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 40, height: 40)
                }
                Spacer()
            }

            Text("Agregar Tarjeta")
                .foregroundColor(.black)
                .font(.system(size: 20, weight: .bold))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var cardPreview: some View {
        let last4 = String(digitsOnly(cardNumber).suffix(4))
        let displayedNumber = last4.isEmpty ? "••••  ••••  ••••  ••••" : "••••  ••••  ••••  \(last4)"
        let displayedName = holderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "NOMBRE DEL TITULAR" : holderName.uppercased()
        let displayedExpiry = expiry.isEmpty ? "MM/AA" : expiry

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.92), Color.black.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 150)
                .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 10)

            HStack {
                Image(systemName: "wave.3.right")
                    .foregroundColor(.white.opacity(0.75))
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("LOGO")
                    .foregroundColor(.white.opacity(0.55))
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule())
            }
            .padding(16)

            VStack(alignment: .leading, spacing: 8) {
                Text(displayedNumber)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .padding(.top, 50)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NOMBRE")
                            .foregroundColor(.white.opacity(0.55))
                            .font(.system(size: 10, weight: .bold))
                        Text(displayedName)
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("VENCE")
                            .foregroundColor(.white.opacity(0.55))
                            .font(.system(size: 10, weight: .bold))
                        Text(displayedExpiry)
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
            }
            .padding(16)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .foregroundColor(.gray)
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func field(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, trailingIcon: String? = nil) -> some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray.opacity(0.7))
                        .font(.system(size: 15, weight: .semibold))
                }
                TextField("", text: text)
                    .foregroundColor(.black)
                    .font(.system(size: 15, weight: .bold))
                    .keyboardType(keyboard)
            }

            if let icon = trailingIcon {
                Image(systemName: icon)
                    .foregroundColor(.gray.opacity(0.55))
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: save) {
                Text("Vincular Tarjeta")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }

    private var canSave: Bool {
        let nameOk = !holderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let digits = digitsOnly(cardNumber)
        let cardOk = digits.count == 16
        let expiryOk = expiry.count == 5
        let cvvDigits = digitsOnly(cvv)
        let cvvOk = cvvDigits.count >= 3
        return nameOk && cardOk && expiryOk && cvvOk
    }

    private func save() {
        let digits = digitsOnly(cardNumber)
        let last4 = String(digits.suffix(4))
        let brand = detectBrand(digits)
        let title = "Tarjeta - \(brand)"
        let subtitle = "•••• \(last4)"

        let item = PaymentMethodSelectionView.PaymentItem(
            id: ULID.new().lowercased(),
            kind: .card,
            title: title,
            subtitle: subtitle,
            systemIcon: "creditcard.fill"
        )
        onSave(item)
        dismiss()
    }

    private func digitsOnly(_ value: String) -> String {
        value.filter { $0.isNumber }
    }

    private func formatCardNumber(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(16))
        var chunks: [String] = []
        var start = digits.startIndex
        while start < digits.endIndex {
            let end = digits.index(start, offsetBy: 4, limitedBy: digits.endIndex) ?? digits.endIndex
            chunks.append(String(digits[start..<end]))
            start = end
        }
        return chunks.joined(separator: " ")
    }

    private func formatExpiry(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(4))
        if digits.count <= 2 { return digits }
        let mm = String(digits.prefix(2))
        let yy = String(digits.dropFirst(2))
        return "\(mm)/\(yy)"
    }

    private func detectBrand(_ digits: String) -> String {
        if digits.hasPrefix("4") { return "Visa" }
        if let firstTwo = Int(digits.prefix(2)), (51...55).contains(firstTwo) { return "Mastercard" }
        if let firstFour = Int(digits.prefix(4)), (2221...2720).contains(firstFour) { return "Mastercard" }
        if digits.hasPrefix("34") || digits.hasPrefix("37") { return "Amex" }
        return "Tarjeta"
    }
}

