//
//  MapView.swift
//  SIG-IPC
//
//  Created by jonathan calvin sutrisna on 16/07/25.
//
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Load and render GeoJSON
        GeoJSONDecoderManager.shared.loadGeoJSON(on: mapView)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 2.0
                return renderer
            }

            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.red.withAlphaComponent(0.3)
                renderer.strokeColor = .red
                renderer.lineWidth = 1.5
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
