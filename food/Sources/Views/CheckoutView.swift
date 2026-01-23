import SwiftUI
import MapKit
import Combine
import SDWebImageSwiftUI

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
    
    // Sheet State
    @State private var sheetHeight: CGFloat = .zero
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @GestureState private var gestureOffset: CGFloat = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showMenu: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // Constants
    private let collapsedHeight: CGFloat = 80 // Visible part when minimized
    private let cornerRadius: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // 1. Map Layer
                WazeLikeMapView(region: $region, tileTemplate: MinimalMapStyle.template)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .overlay(
                        // Back Button
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

                // 2. Bottom Sheet Overlay
                // The sheet content itself
                VStack(spacing: 0) {
                    // Drag Handle
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    
                    // Header Content
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tu pedido va en camino")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("Entrega estimada: 12:15 PM - 12:30 PM")
                                .font(.subheadline)
                                .foregroundColor(.brandGreen)
                        }
                        Spacer()
                        CircularProgressView(progress: Double(elapsed) / 60.0)
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    Divider()
                    
                    // Scrollable Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Status Steps
                            statusStepsView
                            
                            // Driver Info
                            driverInfoView
                            
                            // Address Info
                            addressInfoView
                            
                            // Order Items Preview
                            orderItemsView
                        }
                        .padding(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(CustomCorner(radius: cornerRadius, corners: [.topLeft, .topRight]))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                // Offset Calculation
                .offset(y: getOffset(height: geo.size.height))
                .gesture(
                    DragGesture()
                        .updating($gestureOffset) { value, out, _ in
                            out = value.translation.height
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            let velocity = value.predictedEndTranslation.height
                            let height = geo.size.height
                            
                            // Determine snap points
                            let expanded = 0.0
                            let half = height * 0.4
                            let collapsed = height - collapsedHeight - geo.safeAreaInsets.bottom
                            
                            let currentPos = offset + translation
                            
                            // Snap logic
                            if currentPos < half / 2 || velocity < -500 {
                                offset = expanded
                            } else if currentPos > (collapsed + half) / 2 || velocity > 500 {
                                offset = collapsed
                            } else {
                                offset = half
                            }
                            lastOffset = offset
                        }
                )
                // Initial State
                .onAppear {
                    let height = geo.size.height
                    offset = height * 0.4 // Start at half
                    lastOffset = offset
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: offset)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: gestureOffset)
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
    
    // MARK: - Helper Views
    
    private var statusStepsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Estado del pedido")
                .font(.headline)
            
            HStack(spacing: 0) {
                // Step 1: Cooking
                VStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.brandGreen)
                        .padding(8)
                        .background(Color.brandGreen.opacity(0.1))
                        .clipShape(Circle())
                    Text("Cocinando")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                
                // Connector
                Rectangle()
                    .fill(Color.brandGreen)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                
                // Step 2: Delivery
                VStack {
                    Image(systemName: "bicycle")
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                    Text("Reparto")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private var driverInfoView: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Repartidor")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Juan Pérez")
                    .font(.headline)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.brandGreen)
                    .padding(10)
                    .background(Color.brandGreen.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    private var addressInfoView: some View {
        HStack(spacing: 16) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Dirección de entrega")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Av. Paseo de la Reforma 222")
                    .font(.headline)
            }
            Spacer()
        }
    }
    
    private var orderItemsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tu pedido")
                .font(.headline)
            
            HStack {
                Text("1x Big Mac Combo")
                    .font(.subheadline)
                Spacer()
                Text("$125.00")
                    .font(.subheadline)
                    .bold()
            }
            
            HStack {
                Text("1x McFlurry Oreo")
                    .font(.subheadline)
                Spacer()
                Text("$45.00")
                    .font(.subheadline)
                    .bold()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Logic
    
    func getOffset(height: CGFloat) -> CGFloat {
        let minOffset = 0.0 // Fully expanded (top)
        let maxOffset = height - collapsedHeight - 30 // Collapsed (bottom)
        
        let current = offset + gestureOffset
        return min(max(minOffset, current), maxOffset)
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
