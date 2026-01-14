import SwiftUI

struct ReviewOrderView: View {
    enum TipOption: Hashable {
        case percent(Double)
        case other
    }
    
    let subtotal: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var tipOption: TipOption = .percent(0.10)
    @State private var customTipAmountText: String = ""
    @State private var specialInstructions: String = ""
    @State private var showingCustomTipSheet: Bool = false
    @State private var showingOrderAlert: Bool = false
    
    private var shippingCost: Double { 0 }
    
    private var tipAmount: Double {
        switch tipOption {
        case .percent(let rate):
            return max(0, subtotal * rate)
        case .other:
            return max(0, Double(customTipAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        }
    }
    
    private var total: Double { subtotal + shippingCost + tipAmount }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    VStack(spacing: 16) {
                        sectionHeader(title: "DIRECCIÓN DE ENTREGA", trailing: "Cambiar", action: {})
                        addressCard
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(spacing: 16) {
                        sectionHeader(title: "MÉTODO DE PAGO", trailing: "Cambiar", action: {})
                        paymentCard
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("INSTRUCCIONES ESPECIALES")
                        TextField("Ej. El timbre no funciona, llamar al llegar...", text: $specialInstructions, axis: .vertical)
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            sectionTitle("PROPINA PARA EL REPARTIDOR")
                            Spacer()
                            Text("Opcional")
                                .foregroundColor(.gray)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        tipOptionsRow
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(spacing: 10) {
                        sectionTitle("RESUMEN DE COSTOS")
                        costsCard
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 110)
                }
                .padding(.bottom, 10)
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sheet(isPresented: $showingCustomTipSheet) { customTipSheet }
        .alert("Pedido enviado", isPresented: $showingOrderAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Tu pedido fue enviado correctamente.")
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
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.gray)
            .font(.system(size: 12, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func sectionHeader(title: String, trailing: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .firstTextBaseline) {
            sectionTitle(title)
            Spacer()
            Button(action: action) {
                Text(trailing)
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }
    
    private var addressCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.fuchsia.opacity(0.14))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.fuchsia)
                        .font(.system(size: 14, weight: .bold))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mi Casa")
                    .foregroundColor(.black)
                    .font(.system(size: 15, weight: .bold))
                Text("Av. Paseo de la Reforma 222, Juárez,")
                    .foregroundColor(.gray)
                    .font(.system(size: 13, weight: .medium))
                Text("Cuauhtémoc, 06600 Ciudad de México, CDMX")
                    .foregroundColor(.gray)
                    .font(.system(size: 13, weight: .medium))
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var paymentCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gray.opacity(0.08))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.black.opacity(0.65))
                        .font(.system(size: 14, weight: .bold))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("•••• 4242")
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .bold))
                Text("VISA DÉBITO")
                    .foregroundColor(.gray)
                    .font(.system(size: 11, weight: .semibold))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.black.opacity(0.35))
                .font(.system(size: 14, weight: .bold))
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var tipOptionsRow: some View {
        HStack(spacing: 10) {
            tipPill("10%", option: .percent(0.10))
            tipPill("15%", option: .percent(0.15))
            tipPill("20%", option: .percent(0.20))
            tipOtherPill
        }
    }
    
    private func tipPill(_ title: String, option: TipOption) -> some View {
        let isSelected = tipOption == option
        return Button(action: { tipOption = option }) {
            Text(title)
                .foregroundColor(isSelected ? .white : .black.opacity(0.75))
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.fuchsia : Color.gray.opacity(0.10))
                .clipShape(Capsule())
        }
    }
    
    private var tipOtherPill: some View {
        let isSelected: Bool = {
            if case .other = tipOption { return true }
            return false
        }()
        
        return Button(action: {
            tipOption = .other
            showingCustomTipSheet = true
        }) {
            Text("Otro")
                .foregroundColor(isSelected ? .white : .black.opacity(0.75))
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.fuchsia : Color.gray.opacity(0.10))
                .clipShape(Capsule())
        }
    }
    
    private var costsCard: some View {
        VStack(spacing: 8) {
            costsRow(label: "Subtotal", value: priceText(subtotal), valueColor: .black)
            costsRow(label: "Costo de envío", value: shippingCost == 0 ? "¡GRATIS!" : priceText(shippingCost), valueColor: shippingCost == 0 ? .green : .black)
            costsRow(label: "Propina", value: tipAmount == 0 ? "—" : priceText(tipAmount), valueColor: .black)
            Divider().overlay(Color.gray.opacity(0.15))
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func costsRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .font(.system(size: 13, weight: .bold))
        }
    }
    
    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: { showingOrderAlert = true }) {
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
    
    private var customTipSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Ingresa la propina")
                    .foregroundColor(.black)
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("0.00", text: $customTipAmountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                
                Spacer()
            }
            .padding(16)
            .navigationTitle("Propina")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showingCustomTipSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { showingCustomTipSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func priceText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(String(format: "%.2f", value))"
    }
}

