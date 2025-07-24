import CoreLocation

final class EntityData {
    static var entities: [Entity] = []
}

struct Entity: Decodable, Hashable {
    let properties: EntityProperties
    let geometry: EntityGeometry
}

struct EntityProperties: Decodable, Hashable {
    let name: String
    var hall: String?
    var objectType: String
    var category: [String]?
    var activity: String?
    var isFocused: Bool?
}

struct EntityGeometry: Decodable, Hashable {
    let coordinates: [CoordinateWrapper]
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
                return CoordinateWrapper(CLLocationCoordinate2D(latitude: 0, longitude: 0))
            }
            return CoordinateWrapper(CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
        }
    }

    init(coordinates: [CoordinateWrapper], type: String) {
        self.coordinates = coordinates
        self.type = type
    }
}

struct CoordinateWrapper: Hashable {
    let coordinate: CLLocationCoordinate2D

    init(_ coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }

    static func == (lhs: CoordinateWrapper, rhs: CoordinateWrapper) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}
