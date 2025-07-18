import Foundation
import Combine
import MapKit

class ContentViewModel: ObservableObject {
    
    // MARK: Published variable
    @Published var searchText: String = ""
    @Published var selectedCategory: String = ""
    @Published var selectedBrand: [String] = []
    @Published var showFilter: Bool = false
    @Published var shouldRecenter: Bool = false
    @Published var searchSuggestions: [String] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var region: MKCoordinateRegion
    
    private var cancelLabels = Set<AnyCancellable>()
    private var pdrManager = PDRManager()
    
    private var selectedBrands: [Brand] = []

    init() {
        let initial = pdrManager.currentLocation
        self.userLocation = initial
        self.region = MKCoordinateRegion(center: initial, span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001))

        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates() // don't search if the text hasn't changed
            .map { text -> [String] in
                guard !text.isEmpty else { return [] }
                return BrandData.brands
                    .filter { $0.name.localizedCaseInsensitiveContains(text) }
                    .map { $0.name } // return only names
            }
            .assign(to: \.searchSuggestions, on: self)
            .store(in: &cancelLabels)
        
        // PDR Building
        pdrManager.$currentLocation
            .receive(on: RunLoop.main)
            .sink { [weak self] coordinate in
                self?.userLocation = coordinate
                if self?.shouldRecenter == true {
                    self?.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001))
                    self?.shouldRecenter = false
                }
            }
            .store(in: &cancelLabels)
    }
    
    func selectSuggestion(_ suggestion: String) {
        self.searchText = suggestion
        self.selectedBrand = [suggestion]
        self.searchSuggestions = []
    }

    func applyCategory(){
        self.selectedBrands = BrandData.brands.filter{ $0.category.contains(selectedCategory) }
        self.selectedBrand = []
        for brand in selectedBrands{
            selectedBrand.append(brand.name)
        }
        self.showFilter = false
    }
}
