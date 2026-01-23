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
    
    private var costSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESUMEN DE COSTOS")
                .foregroundColor(.gray)
                .font(.system(size: 13, weight: .bold))
            
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
    private let restaurantCoord = CLLocationCoordinate2D(latitude: 19.420, longitude: -99.175)
    private let destinationCoord = CLLocationCoordinate2D(latitude: 19.426, longitude: -99.170)
    @State private var courierCoord = CLLocationCoordinate2D(latitude: 19.420, longitude: -99.175)
    @State private var elapsed: Int = 0
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 19.423, longitude: -99.1725), span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
    @State private var sheetY: CGFloat = 0
    @State private var sheetState: SheetState = .half
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showMenu: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var sheetOffset: CGFloat = 0
    @State private var sheetStartOffset: CGFloat = 0
    @State private var isDraggingSheet: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    headerBar
                        .padding(.horizontal, 12)
                    WazeLikeMapView(region: $region, tileTemplate: MinimalMapStyle.template)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Color.white
                    .frame(height: geo.size.height * 0.40 + geo.safeAreaInsets.bottom)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .offset(y: sheetOffset)
                    .allowsHitTesting(false)

                bottomSheet(height: geo.size.height)
                    .frame(height: geo.size.height * 0.40)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    
                    .ignoresSafeArea(.container, edges: .bottom)
                    .offset(y: sheetOffset)
                    
            }
            .onAppear {
                sheetOffset = 0
            }
        }
        .preferredColorScheme(.light)
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

struct WazeLikeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let tileTemplate: String?
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        if #available(iOS 13.0, *) {
            let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
            config.showsTraffic = false
            map.preferredConfiguration = config
        } else {
            map.mapType = .standard
        }
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        map.showsScale = false
        map.showsBuildings = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.setRegion(region, animated: false)
        if let template = tileTemplate, let overlay = tileOverlay(from: template) {
            overlay.canReplaceMapContent = true
            map.addOverlay(overlay, level: .aboveLabels)
        }
        map.delegate = context.coordinator
        return map
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.region.center.latitude != region.center.latitude || uiView.region.center.longitude != region.center.longitude {
            uiView.setRegion(region, animated: false)
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject, MKMapViewDelegate {}
    private func tileOverlay(from template: String) -> MKTileOverlay? {
        let overlay = MKTileOverlay(urlTemplate: template)
        overlay.minimumZ = 0
        overlay.maximumZ = 19
        return overlay
    }
}

    private var headerBar: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Button(action: { showMenu = true }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .font(.system(size: 18, weight: .bold))
                    .imageScale(.medium)
            }
            Text("Tu pedido va en camino")
                .foregroundColor(.black)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .layoutPriority(1)
            Spacer()
        }
        .frame(height: 28)
    }

    

    private var progressStages: some View {
        VStack(spacing: 8) {
            HStack(spacing: 18) {
                stageIcon(system: "checkmark", index: 0)
                connector(index: 1)
                stageIcon(system: "bag.fill", index: 2)
                connector(index: 3)
                stageIcon(system: "bicycle", index: 4)
                connector(index: 5)
                stageIcon(system: "house.fill", index: 6)
            }
            ProgressView(value: Double(elapsed) / 60.0)
                .tint(.brandGreen)
        }
    }

    private var deliveryEta: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.brandGreen)
                .frame(width: 10, height: 10)
            Text("Entrega estimada")
                .foregroundColor(.black)
                .font(.system(size: 14, weight: .bold))
            Spacer()
            Text(timeString(remaining: max(0, 60 - elapsed)))
                .foregroundColor(.brandGreen)
                .font(.system(size: 14, weight: .bold))
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func bottomSheet(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .center) {
                HStack {
                    Text("Detalles del pedido")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Text("Agregar productos")
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 6)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let peek: CGFloat = 28
                        let maxOffset = height * 0.40 - peek
                        if !isDraggingSheet { sheetStartOffset = sheetOffset; isDraggingSheet = true }
                        sheetOffset = min(max(0, sheetStartOffset + value.translation.height), maxOffset)
                    }
                    .onEnded { _ in
                        let peek: CGFloat = 28
                        let maxOffset = height * 0.40 - peek
                        isDraggingSheet = false
                        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.85, blendDuration: 0.0)) {
                            sheetOffset = sheetOffset > maxOffset / 2 ? maxOffset : 0
                        }
                    }
            )
            .onTapGesture {
                let peek: CGFloat = 28
                let maxOffset = height * 0.40 - peek
                withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.85, blendDuration: 0.0)) {
                    sheetOffset = sheetOffset >= maxOffset ? 0 : sheetOffset
                }
            }
            Divider().overlay(Color.gray.opacity(0.18))
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Circle().fill(Color.fuchsia.opacity(0.14)).frame(width: 36, height: 36).overlay(Image(systemName: "person.fill").foregroundColor(.fuchsia))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Repartidor")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .bold))
                        Text("Maria • 5.0")
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Spacer()
                    Image(systemName: "phone.fill").foregroundColor(.brandGreen)
                }
                HStack(spacing: 10) {
                    Circle().fill(Color.brandGreen.opacity(0.14)).frame(width: 36, height: 36).overlay(Image(systemName: "mappin.and.ellipse").foregroundColor(.brandGreen))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dirección de entrega")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .bold))
                        Text("Av. Paseo de la Reforma 1870")
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    Circle().fill(Color.orange.opacity(0.14)).frame(width: 36, height: 36).overlay(Image(systemName: "fork.knife").foregroundColor(.orange))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Restaurante")
                            .foregroundColor(.black)
                            .font(.system(size: 14, weight: .bold))
                        Text("McDonald's • 3 productos")
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func stageIcon(system: String, index: Int) -> some View {
        let active = stage >= index
        return ZStack {
            Circle()
                .fill(active ? Color.brandGreen : Color.gray.opacity(0.2))
                .frame(width: 34, height: 34)
            Image(systemName: system)
                .foregroundColor(active ? .white : .gray)
                .font(.system(size: 16, weight: .bold))
        }
        .animation(.easeInOut(duration: 0.3), value: stage)
    }

    private func connector(index: Int) -> some View {
        Rectangle()
            .fill(stage >= index ? Color.brandGreen : Color.gray.opacity(0.2))
            .frame(height: 3)
            .frame(maxWidth: .infinity)
            .cornerRadius(2)
            .animation(.easeInOut(duration: 0.3), value: stage)
    }

    private var stage: Int { min(6, elapsed / 10) }

    private func timeString(remaining: Int) -> String {
        let m = remaining / 60
        let s = remaining % 60
        let ms = String(format: "%02d:%02d", m, s)
        return ms
    }

    private func interpolate(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, t: Double) -> CLLocationCoordinate2D {
        let lat = from.latitude + (to.latitude - from.latitude) * t
        let lon = from.longitude + (to.longitude - from.longitude) * t
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func iconCircle(system: String, color: Color) -> some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 38, height: 38)
            Circle().stroke(color, lineWidth: 2).frame(width: 38, height: 38)
            Image(systemName: system)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .bold))
        }
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
    }

    private enum SheetState { case half, low }

    private func targetY(for state: SheetState, height: CGFloat) -> CGFloat {
        switch state {
        case .half: return height * 0.45
        case .low: return height * 0.91
        }
    }

    private struct Pin: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let system: String
        let color: Color
    }

    private var pins: [Pin] {
        [
            .init(id: "restaurant", coordinate: restaurantCoord, system: "fork.knife", color: .brandGreen),
            .init(id: "destination", coordinate: destinationCoord, system: "house.fill", color: .black),
            .init(id: "courier", coordinate: courierCoord, system: "bicycle", color: .fuchsia)
        ]
    }
}
