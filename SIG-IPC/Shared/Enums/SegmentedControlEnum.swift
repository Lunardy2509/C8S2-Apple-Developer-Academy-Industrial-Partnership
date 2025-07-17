import Foundation

enum SegmentedControlEnum: String, CaseIterable, Identifiable {
    case brand = "Brand"
    case activity = "Activity"
    case heatMap = "Live Crowd"
    var id: String { self.rawValue }
}
