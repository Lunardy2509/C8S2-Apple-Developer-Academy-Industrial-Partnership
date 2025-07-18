import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var region: MKCoordinateRegion
    @Binding var shouldRecenter: Bool
    @Binding var selectedBrand: [String]

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
            DispatchQueue.main.async {
                self.region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
                )
            }
            
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

                let title = polygon.title?.lowercased() ?? ""
                let selectedBrands = parent.selectedBrand.map {
                    $0.lowercased()
                }
                
                if selectedBrands.contains(title) {
                    renderer.fillColor = UIColor.green.withAlphaComponent(0.4)
                    renderer.strokeColor = UIColor.green
                } else {
                    if ["hall a", "hall b", "hall cendrawasih"].contains(title) {
                        renderer.fillColor = UIColor.white
                        renderer.strokeColor = UIColor(Color(red: 221 / 255, green: 170 / 255, blue: 167 / 255))
                        renderer.lineWidth = 1.5
                        return renderer
                    }
                    
                    if EntityData.entities.contains(where: { $0.name.lowercased() == title && $0.objectType == "wall" }) {
                        renderer.fillColor = UIColor.black.withAlphaComponent(0.6)
                    } else if EntityData.entities.contains(where: { $0.name.lowercased() == title && $0.objectType == "tunnel" }) {
                        renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                    } else if EntityData.entities.contains(where: { $0.name.lowercased() == title && $0.objectType == "stage" }) {
                        renderer.fillColor = UIColor.red.withAlphaComponent(0.8)
                    } else {
                        // Booth
                        if selectedBrands.isEmpty {
                            renderer.fillColor = UIColor.red.withAlphaComponent(0.4)
                        } else{
                            renderer.fillColor = UIColor.red.withAlphaComponent(0.2)
                        }
                    }
                    renderer.strokeColor = UIColor.clear
                }

                renderer.lineWidth = 1
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
