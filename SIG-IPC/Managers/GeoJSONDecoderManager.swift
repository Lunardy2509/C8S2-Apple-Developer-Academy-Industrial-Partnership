import Foundation
import MapKit

final class GeoJSONDecoderManager {
    static let shared = GeoJSONDecoderManager()
    private var hasSeededData = false
    
    private init() {}
    
    func loadGeoJSON(on mapView: MKMapView) {
        loadFile(named: "hall", on: mapView)
        loadFile(named: "placeofinterest", on: mapView)
        self.hasSeededData = true
    }
    
    private func loadFile(named name: String, on mapView: MKMapView) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "geojson") else {
            print("GeoJSON file '\(name)' not found")
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
                    
                    if let polygon = geometry as? MKPolygon {
                        let (title, category) = extractFeatureID(from: mkFeature)
                        polygon.title = title
                        mapView.addOverlay(polygon)
                        
                        if !hasZoomed {
                            let region = MKCoordinateRegion(polygon.boundingMapRect)
                            mapView.setRegion(region, animated: true)
                            hasZoomed = true
                        }
                        
                        if ["booth", "stage"].contains(category){
                            mapView.addAnnotation(geometry)
                        }
                    }
                }
            }
            print("\(name) GeoJSON loaded and rendered successfully.")
            
        } catch {
            print("Failed to load geojson '\(name)': \(error)")
        }
    }
    
    private func extractFeatureID(from feature: MKGeoJSONFeature) -> (String?, String) {
        guard let propertiesData = feature.properties else { return (nil, "") }
        do {
            var objectType: String = ""
            if let json = try JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] {
                if let name = json["name"] as? String {
                    objectType = json["object_type"] as? String ?? ""
                    if self.hasSeededData {
                        return (name, objectType)
                    }
                }
                
                if let geometry = feature.geometry.first as? MKPolygon {
                    let points = geometry.points()
                    var coords: [CLLocationCoordinate2D] = []
                    for i in 0..<geometry.pointCount {
                        coords.append(points[i].coordinate)
                    }
                    
                    let wrappedCoords = coords.map { CoordinateWrapper($0) }
                    
                    if objectType == "hall" {
                        let hall = Hall(
                            name: json["name"] as? String ?? "",
                            geometry: HallGeometry(coordinates: wrappedCoords)
                        )
                        HallData.halls.append(hall)
                        print("🏛️ Parsed \(hall.name)")
                        return (hall.name, "hall")
                    } else {
                        let entityProperties = EntityProperties(
                            name: json["name"] as? String ?? "",
                            hall: json["hall"] as? String,
                            objectType: objectType,
                            category: json["category"] as? [String],
                            activity: json["activity"] as? String,
                            isFocused: (json["isFocused"] as? String) == "yes"
                        )
                        
                        let entityGeometry = EntityGeometry(
                            coordinates: wrappedCoords,
                            type: "Polygon"
                        )
                        
                        let entity = Entity(
                            properties: entityProperties,
                            geometry: entityGeometry
                        )
                        
                        EntityData.entities.append(entity)
                        print("✅ Parsed Entity \(entity.properties.name)")

                        return (entity.properties.name, entity.properties.objectType)
                    }
                }
            }
        } catch {
            print("Error decoding properties: \(error)")
        }
        
        return (nil, "")
    }
}
