struct Brand: Hashable {
    var name: String
    var objectType: String
    var hall: String?
    var category: [String]?
    var activity: String?
}

final class BrandData {
    static var brands: [Brand] = []
}
