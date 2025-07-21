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
        mapView.isRotateEnabled = true

        let zoomRange = MKMapView.CameraZoomRange(
            maxCenterCoordinateDistance: 200
        )
        mapView.setCameraZoomRange(zoomRange, animated: false)
        
        if let location = userLocation {
            let circle = MKCircle(center: location, radius: 100)
            mapView.addOverlay(circle)
        }
        
        GeoJSONDecoderManager.shared.loadGeoJSON(on: mapView)
        
        mapView.userTrackingMode = .followWithHeading
        mapView.setUserTrackingMode(.followWithHeading, animated: false)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setUserTrackingMode(.followWithHeading, animated: true)

        // Force overlay re-render
        for overlay in uiView.overlays {
            if let polygon = overlay as? MKPolygon {
                uiView.removeOverlay(polygon)
                uiView.addOverlay(polygon)
            } else if let circle = overlay as? MKCircle {
                uiView.removeOverlay(circle)
                uiView.addOverlay(circle)
            }
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(circle: circle)
                circleRenderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
                circleRenderer.strokeColor = UIColor.systemBlue
                circleRenderer.lineWidth = 1
                return circleRenderer
            }
            
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
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            if mapView.userTrackingMode != .followWithHeading {
                mapView.setUserTrackingMode(.followWithHeading, animated: true)
            }
        }

        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            mapView.overlays
                .filter { $0 is MKCircle }
                .forEach { mapView.removeOverlay($0) }

            let circle = MKCircle(center: userLocation.coordinate, radius: 2)
            mapView.addOverlay(circle)

            DispatchQueue.main.async {
                self.parent.userLocation = userLocation.coordinate
            }
        }
    }

}
