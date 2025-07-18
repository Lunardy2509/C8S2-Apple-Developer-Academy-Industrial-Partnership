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
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsScale = false
        
        GeoJSONDecoderManager.shared.loadGeoJSON(on: mapView)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if shouldRecenter, let coordinate = userLocation {
            let newRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
            )
            uiView.setRegion(newRegion, animated: true)
            
            DispatchQueue.main.async {
                shouldRecenter = false
            }
        }
        
        // Only remove the previous "You" annotation
        if let userAnnotation = uiView.annotations.first(where: { $0.title == "You" }) {
            uiView.removeAnnotation(userAnnotation)
        }
        
        if let coordinate = userLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "You"
            uiView.addAnnotation(annotation)
        }
        
        for overlay in uiView.overlays {
            if let polygon = overlay as? MKPolygon {
                uiView.removeOverlay(polygon)
                uiView.addOverlay(polygon)
            }
        }
        
        print("🗺️ MapView updated — selectedBrand: \(selectedBrand)")
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polygon = overlay as? MKPolygon,
                  let rawTitle = polygon.title,
                  !rawTitle.isEmpty else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolygonRenderer(polygon: polygon)
            let title = rawTitle.lowercased()
            let selectedBrands = parent.selectedBrand.map { $0.lowercased() }

            if selectedBrands.contains(title) {
                renderer.fillColor = UIColor.green.withAlphaComponent(0.4)
                renderer.strokeColor = UIColor.green
            } else if ["hall a", "hall b", "hall cendrawasih"].contains(title) {
                renderer.fillColor = UIColor.white
                renderer.strokeColor = UIColor(red: 221 / 255, green: 170 / 255, blue: 167 / 255, alpha: 1.0)
                renderer.lineWidth = 1.5
                return renderer
            } else if BrandData.brands.contains(where: { $0.name.lowercased() == title && $0.objectType == "wall" }) {
                renderer.fillColor = UIColor.black.withAlphaComponent(0.6)
            } else if BrandData.brands.contains(where: { $0.name.lowercased() == title && $0.objectType == "tunnel" }) {
                renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
            } else if BrandData.brands.contains(where: { $0.name.lowercased() == title && $0.objectType == "stage" }) {
                renderer.fillColor = UIColor.red.withAlphaComponent(0.8)
            } else {
                renderer.fillColor = selectedBrands.isEmpty
                    ? UIColor.red.withAlphaComponent(0.4)
                    : UIColor.red.withAlphaComponent(0.2)
            }

            renderer.strokeColor = UIColor.clear
            renderer.lineWidth = 1
            return renderer
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // Use Apple’s default GPS-based blue dot (if used)
            }

            // Custom blue dot for "You" annotation
            if annotation.title == "You" {
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "You")
                view.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
                view.layer.cornerRadius = 8
                view.backgroundColor = UIColor.systemBlue
                view.layer.borderColor = UIColor.white.cgColor
                view.layer.borderWidth = 3
                view.layer.masksToBounds = true
                return view
            }

            return nil // Default pin for other annotations if needed
        }
    }
}
