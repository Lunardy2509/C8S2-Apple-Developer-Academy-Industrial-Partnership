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
                    }

                    if let annotation = geometry as? MKAnnotation {
                        mapView.addAnnotation(annotation)
                    }

                    if let polygon = geometry as? MKPolygon {
                        polygon.title = extractFeatureID(from: mkFeature)
                        mapView.addOverlay(polygon)

                        if !hasZoomed {
                           let region = MKCoordinateRegion(polygon.boundingMapRect)
                           mapView.setRegion(region, animated: true)
                           hasZoomed = true
                       }
                    }
                }
            }
        } catch {
            print("Failed to load geojson: \(error)")
        }
    }
    
    private func extractFeatureID(from feature: MKGeoJSONFeature) -> String? {
        guard let propertiesData = feature.properties else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {
                if let id = json["id"] as? String {
                    return id
                }
            }
        } catch {
            print("Error decoding properties: \(error)")
        }
        
        return nil
    }

}
