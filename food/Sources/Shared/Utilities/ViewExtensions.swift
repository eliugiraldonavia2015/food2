import SwiftUI

// MARK: - View Extensions

extension View {
    /// Aplica esquinas redondeadas solo a los bordes especificados
    public func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Rastrea la visualización de una pantalla en Analytics automáticamente al aparecer
    /// - Parameter name: Nombre de la pantalla (snake_case recomendado, ej: "home_feed")
    /// - Parameter properties: Propiedades adicionales opcionales
    public func analyticsScreen(name: String, properties: [String: Any]? = nil) -> some View {
        onAppear {
            var params = properties ?? [:]
            params["screen_name"] = name
            params["screen_class"] = String(describing: type(of: self))
            
            AnalyticsManager.shared.log(event: "screen_view", params: params, priority: .realTime)
        }
    }
}

// MARK: - RoundedCorner Shape

public struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    public init(radius: CGFloat = .infinity, corners: UIRectCorner = .allCorners) {
        self.radius = radius
        self.corners = corners
    }

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
