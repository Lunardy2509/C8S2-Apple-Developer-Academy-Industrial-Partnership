struct Entity{
    var name: String
    var hall: String
    var objectType: String
    var category: [String]
    var activity: [String]
}

final class EntityData {
    static var entities: [Entity] = []
}
