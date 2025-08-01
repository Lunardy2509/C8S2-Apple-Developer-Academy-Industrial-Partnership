import Combine
import CoreData
import CoreLocation
import Foundation
import MapKit
import SwiftUICore

class MapMenuViewModel: ObservableObject {
    
    @Environment(\.managedObjectContext) private var context
    
    // MARK: Published variable
    @Published var selectedCategory: String = ""
    @Published var showFilter: Bool = false
    @Published var shouldRecenter: Bool = false
    @Published var searchSuggestions: [SearchResult] = []
    @Published var selectedDisplayMode: DisplayModeEnum = .brand {
        didSet {
            resetState()
        }
    }
    @Published var showSegmentedControl: Bool = true
    @Published var shouldActivateSearchFlow: Bool = false

    @Published var searchText: String = ""
    @Published var selectedBrand: [Entity] = []
    @Published var recentSearchResults: [CachedSearchResult] = []
    
    @Published var popupCoordinate: CLLocationCoordinate2D?
    @Published var popupScreenPosition: CGPoint = .zero
    @Published var mapViewRef: MKMapView?
    @Published var popupData: CustomPopupData?

    // MARK: Private variable
    private var selectedBrands: [Entity] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .map { text -> [SearchResult] in
                guard !text.isEmpty else { return [] }
                return EntityData.entities
                    .filter { $0.properties.name.localizedCaseInsensitiveContains(text) && $0.properties.objectType == "booth"}
                    .map { SearchResult(name: $0.properties.name, hall: $0.properties.hall ?? "") }
            }
            .assign(to: \.searchSuggestions, on: self)
            .store(in: &cancellables)
    }

    func applyCategory(){
        self.selectedBrands = EntityData.entities.filter {
            $0.properties.category?.contains(selectedCategory) == true
        }
        self.selectedBrand = []
        
        for brand in selectedBrands{
            selectedBrand.append(brand)
        }
        self.showFilter = false
    }
    
    func saveSearchResult(brand: Entity, context: NSManagedObjectContext) {
        let entity = CachedSearchResult(context: context)
        entity.name = brand.properties.name
        entity.hall = brand.properties.hall ?? ""
        entity.timestamp = Date()

        do {
            try context.save()
            print("search result saved")
        } catch {
            print("Failed to save search result: \(error)")
        }
    }
    
    func fetchRecentSearchResults(context: NSManagedObjectContext) -> [CachedSearchResult] {
        let request: NSFetchRequest<CachedSearchResult> = CachedSearchResult.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedSearchResult.timestamp, ascending: false)]

        do {
            let allResults = try context.fetch(request)
            
            // Deduplicate by name
            var seenNames = Set<String>()
            var uniqueResults: [CachedSearchResult] = []
            
            for result in allResults {
                if let name = result.name, !seenNames.contains(name) {
                    seenNames.insert(name)
                    uniqueResults.append(result)
                }
                if uniqueResults.count >= 4 { break }
            }
            
            return uniqueResults
        } catch {
            print("Failed to fetch: \(error)")
            return []
        }
    }
    
    func loadRecentSearchResults(context: NSManagedObjectContext) {
        self.recentSearchResults = fetchRecentSearchResults(context: context)
    }
    
    func resetState() {
        withAnimation {
            self.popupData = nil
            self.popupCoordinate = nil
            self.popupScreenPosition = .zero
            self.showSegmentedControl = true
        }
    }
}
