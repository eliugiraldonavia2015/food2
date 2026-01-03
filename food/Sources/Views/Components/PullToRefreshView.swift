import SwiftUI

struct PullToRefreshView: View {
    var coordinateSpaceName: String
    var onRefresh: () -> Void
    
    @State private var needRefresh = false
    @State private var spinnerAngle: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: .named(coordinateSpaceName)).midY > 50 {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if geo.frame(in: .named(coordinateSpaceName)).maxY < 10 {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(spinnerAngle))
                }
                .opacity(Double(max(0, min(1, (geo.frame(in: .named(coordinateSpaceName)).midY - 20) / 50))))
                .animation(.linear(duration: 0.5).repeatForever(autoreverses: false), value: spinnerAngle)
                .onAppear {
                    spinnerAngle = 360
                }
                Spacer()
            }
            .offset(y: -30) // Oculto inicialmente
        }
        .padding(.top, -50)
    }
}
