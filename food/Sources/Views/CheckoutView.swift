import SwiftUI
import MapKit
import Combine
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
    @State private var showOrderTracking = false
    @State private var showAddressSelection = false
    @State private var showPaymentSelection = false
    
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
        .fullScreenCover(isPresented: $showAddressSelection) {
            DeliveryAddressSelectionView(
                addresses: [
                    .init(
                        id: "home",
                        title: "Casa",
                        detail: "Av. Paseo de la Reforma 222,\nJuárez, Cuauhtémoc, 06600\nCiudad de México, CDMX",
                        systemIcon: "house.fill"
                    ),
                    .init(
                        id: "office",
                        title: "Oficina",
                        detail: "Torre Virreyes, Pedregal 24, Molino\ndel Rey, 11040 Ciudad de México,\nCDMX",
                        systemIcon: "briefcase.fill"
                    ),
                    .init(
                        id: "partner",
                        title: "Novia",
                        detail: "Calle Colima 123, Roma Norte,\nCuauhtémoc, 06700 Ciudad de\nMéxico, CDMX",
                        systemIcon: "heart.fill"
                    )
                ],
                initialSelectedId: addressTitle.lowercased().contains("casa") ? "home" : nil
            ) { selected in
                addressTitle = selected.title
                addressDetail = selected.detail
            }
        }
        .fullScreenCover(isPresented: $showPaymentSelection) {
            PaymentMethodSelectionView(
                cards: [
                    .init(id: "card_main", kind: .card, title: "Principal - Visa", subtitle: "•••• 4242", systemIcon: "creditcard.fill"),
                    .init(id: "card_secondary", kind: .card, title: "Nómina - Mastercard", subtitle: "•••• 8899", systemIcon: "creditcard.fill")
                ],
                otherMethods: [
                    .init(id: "applepay", kind: .applePay, title: "Apple Pay", subtitle: "", systemIcon: "apple.logo"),
                    .init(id: "cash", kind: .cash, title: "Efectivo", subtitle: "Paga al recibir el pedido", systemIcon: "banknote.fill")
                ],
                initialSelectedId: paymentTitle.contains("4242") ? "card_main" : nil
            ) { selected in
                switch selected.kind {
                case .card:
                    paymentTitle = selected.subtitle.isEmpty ? "Tarjeta" : selected.subtitle
                    paymentSubtitle = selected.title.uppercased()
                case .applePay:
                    paymentTitle = "Apple Pay"
                    paymentSubtitle = ""
                case .cash:
                    paymentTitle = "Efectivo"
                    paymentSubtitle = "Paga al recibir el pedido"
                }
            }
        }
        .fullScreenCover(isPresented: $showPlaced) {
            OrderPlacedOverlayView {
                showPlaced = false
                showOrderTracking = true
            }
        }
        .fullScreenCover(isPresented: $showOrderTracking) {
            OrderTrackingView(
                restaurantId: restaurantName.lowercased().replacingOccurrences(of: " ", with: "_"),
                restaurantName: restaurantName,
                coverUrl: "",
                avatarUrl: "",
                location: addressTitle,
                branchName: nil,
                distanceKm: nil
            )
        }
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

            Text("Revisar Pedido")
                .foregroundColor(.black)
                .font(.system(size: 20, weight: .bold))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("DIRECCIÓN DE ENTREGA") { showAddressSelection = true }
            Button(action: {}) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.fuchsia.opacity(0.14))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.fuchsia)
                                .font(.system(size: 15, weight: .bold))
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(addressTitle)
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                        Text(addressDetail)
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .semibold))
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
            sectionHeader("MÉTODO DE PAGO") { showPaymentSelection = true }
            Button(action: {}) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 36, height: 28)
                        .overlay(
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14, weight: .bold))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(paymentTitle)
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                        Text(paymentSubtitle)
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 15, weight: .bold))
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INSTRUCCIONES ESPECIALES")
                .foregroundColor(.gray)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $instructions)
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .semibold))
                    .modifier(HideTextEditorBackground())
                    .frame(height: 90)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                if instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Ej. El timbre no funciona, llamar al llegar...")
                        .foregroundColor(.gray.opacity(0.8))
                        .font(.system(size: 16, weight: .semibold))
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
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("Opcional")
                    .foregroundColor(.gray.opacity(0.8))
                    .font(.system(size: 13, weight: .bold))
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
                    .font(.system(size: 16, weight: .bold))
                    TextField("0.00", text: $customTipText)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            Text("La propina es para tu repartidor.")
                .foregroundColor(.gray.opacity(0.8))
                .font(.system(size: 13, weight: .semibold))
        }
    }
    
    private var bottomBar: some View {
        VStack(spacing: 8) {
            totalsPanel
            Button(action: placeOrder) {
                ZStack {
                    Text(placingOrder ? "Enviando..." : "Realizar Pedido")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brandGreen)
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
    
    private var totalsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RESUMEN DE COSTOS")
                .foregroundColor(.gray)
                .font(.system(size: 13, weight: .bold))
            
            VStack(spacing: 10) {
                costRow(title: "Subtotal", value: priceText(subtotal), valueColor: .black)
                costRow(title: "Costo de envío", value: shipping == 0 ? "¡GRATIS!" : priceText(shipping), valueColor: shipping == 0 ? .brandGreen : .black)
                costRow(title: "Propina", value: priceText(tip), valueColor: .black)
                Divider().overlay(Color.gray.opacity(0.18))
                costRow(title: "Total", value: priceText(grandTotal), valueColor: .black, isEmphasis: true, totalColor: .brandGreen)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
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
    
    private func sectionHeader(_ title: String, onChange: @escaping () -> Void = {}) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 13, weight: .bold))
            Spacer()
            Button(action: onChange) {
                Text("Cambiar")
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 13, weight: .bold))
            }
        }
    }
    
    private func tipChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(isSelected ? .white : .black)
                .font(.system(size: 14, weight: .bold))
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
                .font(.system(size: isEmphasis ? 16 : 14, weight: isEmphasis ? .bold : .semibold))
            Spacer()
            Text(value)
                .foregroundColor(totalColor ?? valueColor)
                .font(.system(size: isEmphasis ? 16 : 14, weight: isEmphasis ? .bold : .bold))
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

struct OrderPlacedOverlayView: View {
    let onDone: () -> Void
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.brandGreen)
                    .font(.system(size: 60, weight: .bold))
                Text("Pedido enviado")
                    .foregroundColor(.black)
                    .font(.system(size: 22, weight: .bold))
                Text("Tu pedido ya fue enviado")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(24)
            .background(Color.white)
        }
        .preferredColorScheme(.light)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onDone()
            }
        }
    }
}

struct OrderTrackingView: View {
    let restaurantId: String
    let restaurantName: String
    let coverUrl: String
    let avatarUrl: String
    let location: String
    let branchName: String?
    let distanceKm: Double?
    private let destinationCoord = CLLocationCoordinate2D(latitude: 19.426, longitude: -99.170)
    
    // MARK: - Simulation State
    enum OrderStatus: CaseIterable {
        case sent
        case confirmed
        case preparing
        case courierToRestaurant
        case pickup
        case courierToCustomer
        case arrived
        case completed
        
        var title: String {
            switch self {
            case .sent: return "Enviando pedido..."
            case .confirmed: return "¡Pedido confirmado!"
            case .preparing: return "Preparando tus alimentos"
            case .courierToRestaurant: return "Repartidor en camino al restaurante"
            case .pickup: return "Repartidor recogiendo tu pedido"
            case .courierToCustomer: return "¡Tu pedido va en camino!"
            case .arrived: return "¡El repartidor llegó!"
            case .completed: return "Entregado"
            }
        }
        
        var progress: Double {
            switch self {
            case .sent: return 0.05
            case .confirmed: return 0.15
            case .preparing: return 0.35
            case .courierToRestaurant: return 0.50
            case .pickup: return 0.65
            case .courierToCustomer: return 0.80
            case .arrived: return 0.95
            case .completed: return 1.0
            }
        }
        
        var systemIcon: String {
            switch self {
            case .sent: return "paperplane.fill"
            case .confirmed: return "checkmark.circle.fill"
            case .preparing: return "flame.fill"
            case .courierToRestaurant: return "bicycle"
            case .pickup: return "bag.fill"
            case .courierToCustomer: return "figure.wave"
            case .arrived: return "house.fill"
            case .completed: return "star.fill"
            }
        }
    }
    
    @State private var status: OrderStatus = .sent
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 19.423, longitude: -99.1725), span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
    @State private var deliveryCode: String = String(Int.random(in: 1000...9999))
    
    // Sheet State
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @GestureState private var gestureOffset: CGFloat = 0
    @State private var showChat = false
    @State private var showMenu = false
    @Environment(\.dismiss) private var dismiss
    
    // Simulation Timer
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    // Constants
    private let collapsedHeight: CGFloat = 100
    private let cornerRadius: CGFloat = 20
    @State private var hasInitializedPosition = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // ... (Map Layer code remains same) ...
                // 1. Map Layer
                WazeLikeMapView(region: $region, tileTemplate: MinimalMapStyle.template)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .overlay(
                        Button(action: { showMenu = true }) {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, geo.safeAreaInsets.top + 10)
                        .padding(.leading, 16)
                        , alignment: .topLeading
                    )
                    .onAppear {
                        if !hasInitializedPosition {
                            let height = geo.size.height
                            let halfOffset = height * 0.4
                            offset = halfOffset
                            lastOffset = halfOffset
                            hasInitializedPosition = true
                        }
                    }

                // 2. Bottom Sheet
                VStack(spacing: 0) {
                    // Drag Handle
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    // Header (Always Visible)
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(status.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .animation(.none, value: status)
                                
                                if status != .completed {
                                    Text("Entrega estimada: 12:30 PM")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            // Status Icon
                            ZStack {
                                Circle()
                                    .fill(Color.brandGreen.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: status.systemIcon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.brandGreen)
                            }
                        }
                        
                        // Linear Progress Bar
                        if status != .completed {
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(Color.brandGreen)
                                    .frame(width: geo.size.width * 0.85 * status.progress, height: 6)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: status)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .background(Color.white) // Ensure hit target
                    .gesture(
                        DragGesture()
                            .updating($gestureOffset) { value, out, _ in
                                let height = geo.size.height
                                let maxOffset = height - collapsedHeight - geo.safeAreaInsets.bottom
                                let currentOffset = offset + value.translation.height
                                
                                // Rubber banding logic during drag
                                if currentOffset < 0 {
                                    out = value.translation.height / 3.0
                                } else if currentOffset > maxOffset {
                                    let excess = currentOffset - maxOffset
                                    out = value.translation.height - (excess / 1.5) // Simplified dampening
                                } else {
                                    out = value.translation.height
                                }
                            }
                            .onEnded { value in
                                let height = geo.size.height
                                let maxOffset = height - collapsedHeight - geo.safeAreaInsets.bottom
                                let halfOffset = height * 0.4
                                let velocity = value.predictedEndTranslation.height
                                
                                let currentPos = offset + value.translation.height
                                let targetOffset: CGFloat
                                
                                // Snap logic based on velocity and position
                                if velocity < -400 {
                                    // Swipe Up
                                    if currentPos < halfOffset {
                                        targetOffset = 0 // Go to Top
                                    } else {
                                        targetOffset = halfOffset // Go to Middle
                                    }
                                } else if velocity > 400 {
                                    // Swipe Down
                                    if currentPos < halfOffset {
                                        targetOffset = halfOffset // Go to Middle
                                    } else {
                                        targetOffset = maxOffset // Go to Bottom
                                    }
                                } else {
                                    // Nearest snap point
                                    let distToTop = abs(currentPos - 0)
                                    let distToMid = abs(currentPos - halfOffset)
                                    let distToBot = abs(currentPos - maxOffset)
                                    
                                    if distToTop < distToMid && distToTop < distToBot {
                                        targetOffset = 0
                                    } else if distToMid < distToTop && distToMid < distToBot {
                                        targetOffset = halfOffset
                                    } else {
                                        targetOffset = maxOffset
                                    }
                                }
                                
                                offset = targetOffset
                                lastOffset = targetOffset
                            }
                    )
                    
                    Divider()
                    
                    // Scrollable Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            if status == .arrived {
                                verificationCodeView
                            }
                            
                            driverCardView
                            
                            if status == .preparing || status == .confirmed {
                                preparingAnimationView
                            }
                            
                            addressCardView
                            orderSummaryView
                        }
                        .padding(24)
                        .padding(.bottom, geo.safeAreaInsets.bottom + (geo.size.height * 0.6)) // Ensure content can be scrolled into view even when sheet is offset
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: geo.size.height)
                .background(Color.white)
                .clipShape(CustomCorner(radius: cornerRadius, corners: [.topLeft, .topRight]))
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: -5)
                .offset(y: offset + gestureOffset)
                .animation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0), value: offset)
                .animation(.interactiveSpring(), value: gestureOffset)
                // We move the drag gesture from here (whole sheet) to just the header/background if we want scroll to work freely.
                // BUT user wants to drag the sheet up/down.
                // If we remove it from here, user can only drag by header.
                // If we keep it, scroll might be blocked.
                // Let's try putting it on the background but let ScrollView be on top?
                // Actually, the issue "can't scroll at half position" is likely because the sheet height is huge and offset pushes it down,
                // but the touch area is still valid. The DragGesture on the parent is consuming the touches.
                // Correct approach: Apply DragGesture to the whole view but use simultaneousGesture or restricted hit testing?
                // Better approach: Only allow dragging the sheet via the header area.
                // Let's move the gesture modifier to the Header VStack.

                
                // 3. Completion Overlay
                if status == .completed {
                    completionOverlay
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            // Initial position logic handled via geometry reader if needed, 
            // but here we set a flag or let the first geometry update set it.
            // We'll set it to a value that triggers the .onChange of geometry or just rely on state.
            // Since we need geometry to know what "half" is, we can't set exact pixels here easily 
            // without hardcoding or waiting for layout.
            // A common trick is to use a high value and let the clamping logic fix it, 
            // or initialize it when we have size.
        }
        .onReceive(timer) { _ in
            advanceSimulation()
        }
        .sheet(isPresented: $showChat) {
            DeliveryChatView()
        }
        .fullScreenCover(isPresented: $showMenu) {
            FullMenuView(
                restaurantId: restaurantId,
                restaurantName: restaurantName,
                coverUrl: coverUrl,
                avatarUrl: avatarUrl,
                location: location,
                branchName: branchName,
                distanceKm: distanceKm,
                isEditing: false
            )
        }
    }
    
    // MARK: - Simulation Logic
    func advanceSimulation() {
        guard status != .completed else { return }
        
        let allCases = OrderStatus.allCases
        if let currentIndex = allCases.firstIndex(of: status), currentIndex < allCases.count - 1 {
            // Stop auto-advance at 'arrived' to let user verify code
            if status == .arrived { return }
            
            withAnimation(.spring()) {
                status = allCases[currentIndex + 1]
            }
        }
    }
    
    func verifyDelivery() {
        withAnimation(.spring()) {
            status = .completed
            // Confetti or haptic could go here
        }
    }
    
    // MARK: - Logic
    
    // Removed complex getOffset logic in favor of direct state manipulation
    
    // MARK: - Components
    
    var verificationCodeView: some View {
        VStack(spacing: 16) {
            Text("Entrégale este código al repartidor")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(deliveryCode)
                .font(.system(size: 48, weight: .heavy, design: .monospaced))
                .foregroundColor(.black)
                .padding(.vertical, 10)
                .padding(.horizontal, 30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            
            Button(action: verifyDelivery) {
                Text("Simular Entrega Exitosa")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandGreen)
                    .cornerRadius(14)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    var driverCardView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.gray.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Juan Pérez")
                    .font(.headline)
                    .foregroundColor(.black)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("4.9")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("• Toyota Prius")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: { showChat = true }) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.brandGreen)
                    .clipShape(Circle())
                    .shadow(color: .brandGreen.opacity(0.4), radius: 5, x: 0, y: 3)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    var preparingAnimationView: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
                .padding()
            VStack(alignment: .leading) {
                Text("El restaurante está preparando tu pedido")
                    .font(.subheadline)
                    .bold()
                Text("Cuidando cada detalle...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    var addressCardView: some View {
        HStack(spacing: 16) {
            Image(systemName: "mappin.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Dirección de entrega")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                Text(location)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
            }
            Spacer()
            
            // Mini Map Preview
            Map(coordinateRegion: .constant(MKCoordinateRegion(center: destinationCoord, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))), interactionModes: [])
                .frame(width: 60, height: 60)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                        .font(.caption)
                )
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    var orderSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resumen")
                .font(.headline)
            
            HStack {
                Text("1x Big Mac Combo")
                Spacer()
                Text("$125.00").bold()
            }
            .font(.subheadline)
            
            Divider()
            
            HStack {
                Text("Total")
                    .bold()
                Spacer()
                Text("$125.00")
                    .bold()
                    .foregroundColor(.brandGreen)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
    
    var completionOverlay: some View {
        ZStack {
            Color.brandGreen.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(1.2)
                    .padding(.bottom, 20)
                
                Text("¡Disfruta tu pedido!")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Gracias por confiar en nosotros")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                Button(action: { dismiss() }) {
                    Text("Volver al Inicio")
                        .font(.headline)
                        .foregroundColor(.brandGreen)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(30)
                        .shadow(radius: 10)
                }
                .padding(.top, 40)
            }
            .padding()
        }
    }
}

// MARK: - Chat View
struct DeliveryChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var message = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "¡Hola! Ya recogí tu pedido, llego en 10 min.", isUser: false)
    ]
    
    struct ChatMessage: Identifiable, Hashable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isUser { Spacer() }
                                Text(msg.text)
                                    .padding(12)
                                    .background(msg.isUser ? Color.brandGreen : Color.gray.opacity(0.2))
                                    .foregroundColor(msg.isUser ? .white : .black)
                                    .cornerRadius(16)
                                    .frame(maxWidth: 250, alignment: msg.isUser ? .trailing : .leading)
                                if !msg.isUser { Spacer() }
                            }
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Escribe un mensaje...", text: $message)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(.brandGreen)
                    }
                    .disabled(message.isEmpty)
                }
                .padding()
                .background(Color.white)
                .shadow(radius: 2)
            }
            .navigationTitle("Chat con Juan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cerrar") { dismiss() })
        }
    }
    
    func sendMessage() {
        guard !message.isEmpty else { return }
        messages.append(ChatMessage(text: message, isUser: true))
        message = ""
    }
}

// MARK: - Components

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(Color.brandGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progress)
        }
    }
}

struct CustomCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct WazeLikeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let tileTemplate: String?
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsUserLocation = true
        map.delegate = context.coordinator
        return map
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: WazeLikeMapView
        
        init(_ parent: WazeLikeMapView) {
            self.parent = parent
        }
    }
}
