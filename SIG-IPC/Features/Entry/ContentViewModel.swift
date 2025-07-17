import Foundation

class ContentViewModel: ObservableObject {
    
    // MARK: Published variable
    @Published var searchText: String = ""
    @Published var selectedCategory: String = ""
    @Published var selectedBrand: [String] = []
    @Published var showFilter: Bool = false
    @Published var shouldRecenter: Bool = false
    @Published var selectedDisplayMode: DisplayModeEnum = .brand

    // MARK: Private variable
    private var selectedBrands: [Brand] = []

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
