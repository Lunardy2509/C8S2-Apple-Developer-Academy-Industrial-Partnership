import MapKit
import SwiftUI

struct MapMenuView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var locationManager = LocationManager()
    @FocusState private var isFocused: Bool
    @StateObject var viewModel: MapMenuViewModel = MapMenuViewModel()
    
    private func activateSearchFlowIfNeeded() {
        guard !viewModel.shouldActivateSearchFlow else { return }
        viewModel.shouldActivateSearchFlow = true
        
        withAnimation {
            viewModel.selectedDisplayMode = .brand
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                viewModel.showSegmentedControl = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
                viewModel.shouldActivateSearchFlow = false
            }
        }
    }
    
    private func segmentedControlInset() -> some View {
        Group {
            if viewModel.showSegmentedControl {
                SegmentedControlView(displayMode: $viewModel.selectedDisplayMode)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSegmentedControl)
    }
    
    private func dismissKeyboardIfFocused() {
        if isFocused {
            isFocused = false
            withAnimation {
                viewModel.showSegmentedControl = true
            }
        }
    }
    
    private func renderMap() -> some View {
        MapView(userLocation: $locationManager.userLocation, region: $locationManager.region, shouldRecenter: $viewModel.shouldRecenter, selectedBrand: $viewModel.selectedBrand, displayMode: $viewModel.selectedDisplayMode)
            .edgesIgnoringSafeArea(.all)
            .id(viewModel.selectedBrand)
    }
    
    
    private func renderSearchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 15))
            
            TextField("Cari brand Anda", text: $viewModel.searchText)
                .focused($isFocused)
                .onSubmit {
                    if let matchedBrand = BrandData.brands.first(where: { $0.name.lowercased() == viewModel.searchText.lowercased() }) {
                        viewModel.selectedBrand = [matchedBrand]
                        viewModel.saveSearchResult(brand: matchedBrand, context: context)
                    }
                }
                .allowsHitTesting(!viewModel.shouldActivateSearchFlow)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 15)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
        .simultaneousGesture(
            TapGesture().onEnded {
                activateSearchFlowIfNeeded()
            }
        )
    }
    
    private func renderCategoryBtn() -> some View {
        Image(systemName: "line.3.horizontal.decrease")
            .scaledToFit()
            .frame(height: 15)
            .padding(.vertical, 15)
            .padding(.horizontal, 10)
            .foregroundStyle(Color.gray)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
            .onTapGesture {
                viewModel.showFilter = true
            }
    }
    
    private func renderRecenterBtn() -> some View {
        Button(action: {
            viewModel.shouldRecenter = true
        }, label:{
            Image(systemName: "location")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 15)
                .padding(.vertical, 15)
                .padding(.horizontal, 10)
                .font(.system(size: 30))
                .foregroundStyle(Color.gray)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
        })
    }
    
    private func renderCategorySheet() -> some View {
        ScrollView{
            VStack(alignment: .leading) {
                Text("Category")
                    .font(.title)
                    .padding()
                
                ForEach(["Salon", "Hair", "Make Up", "Skin Care", "Body", "Nails", "Fragrance", "Tools", "Beauty Supplement", "Men's Care"], id: \.self) { category in
                    HStack(alignment: .center) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.gray, lineWidth: 1.5)
                                .background(Circle().fill(Color.white))
                                .frame(width: 20, height: 20)
                            
                            if viewModel.selectedCategory == category {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .onTapGesture {
                            if viewModel.selectedCategory == category {
                                viewModel.selectedCategory = ""
                            } else {
                                viewModel.selectedCategory = category
                            }
                        }
                        
                        Text(category)
                            .padding(.leading, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.selectedCategory = ""
                    }) {
                        Text("Reset")
                            .foregroundStyle(Color.black)
                            .frame(width: 120)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(18)
                    }
                    
                    Button(action: {
                        viewModel.applyCategory()
                    }) {
                        Text("Apply")
                            .foregroundStyle(Color.white)
                            .frame(width: 120)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(18)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func renderSearchSuggestions() -> some View {
        List(viewModel.searchSuggestions, id: \.self) { suggestion in
            HStack {
                Text(suggestion.name)
                    .font(.headline)
                
                Text("\(suggestion.hall)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
            .onTapGesture {
                if let matchedBrand = BrandData.brands.first(where: { $0.name.lowercased() == suggestion.name.lowercased() }) {
                    viewModel.selectedBrand = [matchedBrand]
                    viewModel.saveSearchResult(brand: matchedBrand, context: context)
                    viewModel.loadRecentSearchResults(context: context)
                }
                isFocused = false
            }
        }
    }
    
    private func renderRecentSearches() -> some View {
        Group {
            if(viewModel.recentSearchResults.isEmpty) {
                
                Text("No recent searches!")
            } else {
                List(viewModel.recentSearchResults, id: \.self) { result in
                    VStack(alignment: .leading) {
                        Text(result.name ?? "")
                            .font(.headline)
                        Text(result.hall ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(result.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .onTapGesture {
                        if let matchedBrand = BrandData.brands.first(where: { $0.name.lowercased() == result.name?.lowercased() }) {
                            viewModel.selectedBrand = [matchedBrand]
                            viewModel.saveSearchResult(brand: matchedBrand, context: context)
                            isFocused = false
                        }
                    }
                }
                
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            if(isFocused) {
                if viewModel.searchSuggestions.isEmpty {
                    ScrollView(){
                        VStack(alignment: .leading) {
                            Text("Recent Searches")
                                .font(.title3)
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                            renderRecentSearches()
                                .padding(.top, -10)
                        }
                        VStack(alignment: .leading) {
                            Text("All Brands")
                                .font(.title3)
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                            renderRecentSearches()
                                .padding(.top, -10)
                        }
                    }
                    .padding(.top, 80)
                } else {
                    VStack{
                        Text("Search Results")
                        renderSearchSuggestions()
                    }
                    .padding(.top, 80)
                }
            }
            else { renderMap() }
            
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack {
                        renderSearchBar()
                            .onChange(of: viewModel.searchText) {
                                if viewModel.searchText.isEmpty {
                                    viewModel.loadRecentSearchResults(context: context)
                                }
                            }
                        
                        if(!isFocused){ renderCategoryBtn() }
                    }
                    .padding(.horizontal)
                    .onChange(of: isFocused) {
                        if isFocused {
                            viewModel.loadRecentSearchResults(context: context)
                        }
                    }
                    .padding(.top)
                    
                    HStack {
                        Spacer()
                        if(!isFocused) {
                            renderRecenterBtn()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    Spacer()
                }
            }
            .safeAreaInset(edge: .bottom) {
                segmentedControlInset()
                    .padding(.top, 20)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: -2)
                
            }
            .sheet(isPresented: $viewModel.showFilter) {
                renderCategorySheet()
                    .presentationDetents([.fraction(0.65), .fraction(0.99)])
                    .presentationDragIndicator(.visible)
            }
            .onTapGesture {
                dismissKeyboardIfFocused()
            }
        }
    }
}
    
#Preview {
    MapMenuView()
}
