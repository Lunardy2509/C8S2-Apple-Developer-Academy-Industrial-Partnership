import CoreLocation

struct Brand{
    var name: String
    var hall: String?
    var objectType: String
    var category: [String]?
    var activity: String?
}

final class BrandData {
    static var brands: [Brand] = []
    static var brandFeature: [BrandFeature] = []
}

struct BrandFeature: Decodable {
    let properties: BrandProperties
    let geometry: BrandGeometry
}

struct BrandProperties: Decodable {
    let name: String
    var hall: String?
    var objectType: String
    var category: [String]?
    var activity: String?
}

struct BrandGeometry: Decodable {
    let coordinates: [CLLocationCoordinate2D]
    let type: String

    private enum CodingKeys: String, CodingKey {
        case coordinates
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        let rawCoordinates = try container.decode([[Double]].self, forKey: .coordinates)
        
        coordinates = rawCoordinates.map { pair in
            guard pair.count == 2 else {
                return CLLocationCoordinate2D(latitude: 0, longitude: 0)
            }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
    }
    
    init(coordinates: [CLLocationCoordinate2D], type: String) {
        self.coordinates = coordinates
        self.type = type
    }
}
