import Foundation

class ContentViewModel: ObservableObject {
    @Published var displayMap: Bool = false
    
    func toggleMap() {
        self.displayMap = !self.displayMap
    }
}
