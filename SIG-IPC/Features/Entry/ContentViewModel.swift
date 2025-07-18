import Foundation
import SwiftUICore
import CoreData
import Combine

class ContentViewModel: ObservableObject {
    
    @Environment(\.managedObjectContext) private var context
    
    // MARK: Published variable
    @Published var selectedCategory: String = ""
    @Published var showFilter: Bool = false
    @Published var shouldRecenter: Bool = false
    @Published var searchSuggestions: [SearchResult] = []
    @Published var selectedDisplayMode: DisplayModeEnum = .brand
    @Published var showSegmentedControl: Bool = true
    @Published var shouldActivateSearchFlow: Bool = false

    @Published var searchText: String = ""
    @Published var selectedBrand: [Brand] = []
    @Published var recentSearchResults: [CachedSearchResult] = []

    // MARK: Private variable
    private var selectedBrands: [Brand] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates() // don't search if the text hasn't changed
            .map { text -> [SearchResult] in
                guard !text.isEmpty else { return [] }
                return BrandData.brands
                    .filter { $0.name.localizedCaseInsensitiveContains(text) }
                    .map { SearchResult(name: $0.name, hall: $0.hall ?? "") }
            }
            .assign(to: \.searchSuggestions, on: self)
            .store(in: &cancellables)
    }

    func applyCategory(){
        self.selectedBrands = BrandData.brands.filter {
            $0.category?.contains(selectedCategory) == true
        }
        self.selectedBrand = []
        for brand in selectedBrands{
            selectedBrand.append(brand)
        }
        self.showFilter = false
    }
    
    func saveSearchResult(name: String, hall: String, context: NSManagedObjectContext) {
        let entity = CachedSearchResult(context: context)
        entity.name = name
        entity.hall = hall
        entity.timestamp = Date()

        do {
            try context.save()
        } catch {
            print("Failed to save search result: \(error)")
        }
    }
    
    func fetchRecentSearchResults(context: NSManagedObjectContext) -> [CachedSearchResult] {
        let request: NSFetchRequest<CachedSearchResult> = CachedSearchResult.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedSearchResult.timestamp, ascending: false)]
        request.fetchLimit = 4

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch: \(error)")
            return []
        }
    }
    
    func loadRecentSearchResults(context: NSManagedObjectContext) {
        self.recentSearchResults = fetchRecentSearchResults(context: context)
    }

}
