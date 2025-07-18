import Foundation

enum DisplayModeEnum: String, CaseIterable, Identifiable {
    case brand = "Brand"
    case activity = "Activity"
    case liveCrowd = "Live Crowd"
    
    var id: String { rawValue }
}
