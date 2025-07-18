import Foundation
import Combine

class ContentViewModel: ObservableObject {
    
    // MARK: Published variable
    @Published var searchText: String = ""
    @Published var selectedCategory: String = ""
    @Published var selectedBrand: [String] = []
    @Published var showFilter: Bool = false
    @Published var shouldRecenter: Bool = false
    @Published var searchSuggestions: [String] = []
    @Published var selectedDisplayMode: DisplayModeEnum = .brand
    @Published var showSegmentedControl: Bool = true
    @Published var shouldActivateSearchFlow: Bool = false

    // MARK: Private variable
    private var selectedBrands: [Brand] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates() // don't search if the text hasn't changed
            .map { [weak self] text -> [String] in
                guard !text.isEmpty else { return [] }
                return BrandData.brands
                    .filter { $0.name.localizedCaseInsensitiveContains(text) }
                    .map { $0.name } // return only names
            }
            .assign(to: \.searchSuggestions, on: self)
            .store(in: &cancellables)
    }
    
    func selectSuggestion(_ suggestion: String) {
        self.searchText = suggestion
        self.selectedBrand = [suggestion]
        self.searchSuggestions = []
    }

    func applyCategory(){
        self.selectedBrands = BrandData.brands.filter {
            $0.category?.contains(selectedCategory) == true
        }
        self.selectedBrand = []
        for brand in selectedBrands{
            selectedBrand.append(brand.name)
        }
        self.showFilter = false
    }
}
