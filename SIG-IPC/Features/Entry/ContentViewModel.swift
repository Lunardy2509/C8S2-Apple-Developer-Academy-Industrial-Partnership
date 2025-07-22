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

    // MARK: Private variable
    private var selectedBrands: [Entity] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] text -> [String] in
                guard !text.isEmpty else { return [] }
                return EntityData.entities
                    .filter { $0.name.localizedCaseInsensitiveContains(text) }
                    .map { $0.name }
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
        self.selectedBrands = EntityData.entities.filter{ $0.category.contains(selectedCategory) }
        self.selectedBrand = []
        for brand in selectedBrands{
            selectedBrand.append(brand.name)
        }
        self.showFilter = false
    }
}
