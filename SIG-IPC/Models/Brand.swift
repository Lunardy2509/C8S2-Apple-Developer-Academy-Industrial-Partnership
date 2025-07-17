struct Brand{
    var name: String
    var hall: String?
    var objectType: String
    var category: [String]?
    var activity: String?
}

final class BrandData {
    static var brands: [Brand] = []
}
