import Foundation

enum DisplayModeEnum: String, CaseIterable, Identifiable {
    case brand = "Brand"
    case activity = "Activity"
    
    var id: String { rawValue }
}
