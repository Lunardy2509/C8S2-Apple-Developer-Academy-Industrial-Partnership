//
//  GeoJSONDecoderManager.swift
//  SIG-IPC
//
//  Created by jonathan calvin sutrisna on 16/07/25.
//

import Foundation
import MapKit

final class GeoJSONDecoderManager {
    static let shared = GeoJSONDecoderManager()
    private init() {}
    func loadGeoJSON(on mapView: MKMapView) {
        guard let url = Bundle.main.url(forResource: "footprint", withExtension: "geojson") else {
            print("GeoJSON file not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = MKGeoJSONDecoder()
            let features = try decoder.decode(data)

            var hasZoomed = false 

            for feature in features {
                guard let mkFeature = feature as? MKGeoJSONFeature else { continue }

                for geometry in mkFeature.geometry {
                    if let overlay = geometry as? MKOverlay {
                        mapView.addOverlay(overlay)
                        print("Overlay added: \(overlay)")
                    }

                    if let annotation = geometry as? MKAnnotation {
                        mapView.addAnnotation(annotation)
                    }

                    if let polygon = geometry as? MKPolygon, !hasZoomed {
                        let region = MKCoordinateRegion(polygon.boundingMapRect)
                        mapView.setRegion(region, animated: true)
                        hasZoomed = true
                    }
                }
            }
        } catch {
            print("Failed to load geojson: \(error)")
        }
    }
}
