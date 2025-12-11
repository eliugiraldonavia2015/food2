import SwiftUI
import MapKit

struct DemandMapView: UIViewRepresentable {
    enum City: String, CaseIterable { case guayaquil = "Guayaquil", quito = "Quito" }
    let city: City

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolygon, let title = poly.title ?? "" {
                let r = MKPolygonRenderer(polygon: poly)
                r.lineWidth = 0
                r.strokeColor = .clear
                r.fillColor = DemandMapView.colorFor(title)
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    static func colorFor(_ title: String) -> UIColor {
        switch title {
        case "high": return UIColor.systemGreen.withAlphaComponent(0.30)
        case "medium": return UIColor.systemOrange.withAlphaComponent(0.30)
        default: return UIColor.systemRed.withAlphaComponent(0.30)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.isRotateEnabled = false
        map.showsCompass = false
        map.showsScale = false
        map.pointOfInterestFilter = .includingAll
        configureMap(map)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        configureMap(uiView)
    }

    private func configureMap(_ map: MKMapView) {
        let (center, span, overlays) = data(for: city)
        map.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
        overlays.forEach { map.addOverlay($0) }
    }

    private func data(for city: City) -> (CLLocationCoordinate2D, MKCoordinateSpan, [MKOverlay]) {
        switch city {
        case .guayaquil:
            let center = CLLocationCoordinate2D(latitude: -2.170997, longitude: -79.922359)
            let span = MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            let high = polygon(title: "high", coords: [
                (-2.1700, -79.9300), (-2.1650, -79.9150), (-2.1800, -79.9050), (-2.1850, -79.9200)
            ])
            let medium = polygon(title: "medium", coords: [
                (-2.1550, -79.9400), (-2.1500, -79.9250), (-2.1600, -79.9150), (-2.1650, -79.9300)
            ])
            let low = polygon(title: "low", coords: [
                (-2.1900, -79.9400), (-2.1850, -79.9250), (-2.1950, -79.9150), (-2.2000, -79.9300)
            ])
            return (center, span, [high, medium, low])
        case .quito:
            let center = CLLocationCoordinate2D(latitude: -0.180653, longitude: -78.467834)
            let span = MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            let high = polygon(title: "high", coords: [
                (-0.1750, -78.4800), (-0.1700, -78.4650), (-0.1850, -78.4550), (-0.1900, -78.4700)
            ])
            let medium = polygon(title: "medium", coords: [
                (-0.1650, -78.4900), (-0.1600, -78.4750), (-0.1700, -78.4650), (-0.1750, -78.4800)
            ])
            let low = polygon(title: "low", coords: [
                (-0.1950, -78.4900), (-0.1900, -78.4750), (-0.2000, -78.4650), (-0.2050, -78.4800)
            ])
            return (center, span, [high, medium, low])
        }
    }

    private func polygon(title: String, coords: [(Double, Double)]) -> MKPolygon {
        let points = coords.map { CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1) }
        let poly = MKPolygon(coordinates: points, count: points.count)
        poly.title = title
        return poly
    }
}

