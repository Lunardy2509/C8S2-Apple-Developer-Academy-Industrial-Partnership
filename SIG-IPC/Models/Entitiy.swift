struct Entity: Hashable{
    var name: String
    var objectType: String
    var hall: String?
    var category: [String]?
    var activity: String?
}

final class EntityData {
    static var entities: [Entity] = []
}
