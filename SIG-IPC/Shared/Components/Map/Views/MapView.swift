import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var region: MKCoordinateRegion
    @Binding var shouldRecenter: Bool
    @Binding var selectedBrand: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsScale = false

        GeoJSONDecoderManager.shared.loadGeoJSON(on: mapView)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if shouldRecenter, let userLocation = self.userLocation {
            self.region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                self.shouldRecenter = false
            }
        }

        // Force overlay re-render
        for overlay in uiView.overlays {
            if let polygon = overlay as? MKPolygon {
                uiView.removeOverlay(polygon)
                uiView.addOverlay(polygon)
            }
        }

        print("🔁 MapView updated - selectedBrand: \(selectedBrand)")
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)

                let title = polygon.title?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let selected = parent.selectedBrand.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if title == selected {
                    renderer.fillColor = UIColor.green.withAlphaComponent(0.4)
                    renderer.strokeColor = UIColor.green
                } else {
                    renderer.fillColor = UIColor.red.withAlphaComponent(0.3)
                    renderer.strokeColor = UIColor.red
                }

                renderer.lineWidth = 1.5
                print("🎯 Polygon '\(polygon.title ?? "N/A")' vs selected '\(parent.selectedBrand)'")
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
