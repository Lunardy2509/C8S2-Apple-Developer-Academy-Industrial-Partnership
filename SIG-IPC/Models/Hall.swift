//
//  Hall.swift
//  SIG-IPC
//
//  Created by Adeline Charlotte Augustinne on 24/07/25.
//

import CoreLocation

final class HallData {
    static var halls: [Hall] = []
}

struct Hall: Decodable, Hashable {
    let name: String
    let geometry: HallGeometry
}

struct HallGeometry: Decodable, Hashable {
    let coordinates: [CoordinateWrapper]
    
    private enum CodingKeys: String, CodingKey {
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rawCoordinates = try container.decode([[Double]].self, forKey: .coordinates)
        coordinates = rawCoordinates.map { pair in
            guard pair.count == 2 else {
                return CoordinateWrapper(CLLocationCoordinate2D(latitude: 0, longitude: 0))
            }
            return CoordinateWrapper(CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
        }
    }

    init(coordinates: [CoordinateWrapper]) {
        self.coordinates = coordinates
    }
}

