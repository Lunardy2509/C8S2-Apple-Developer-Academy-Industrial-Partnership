import MapKit
import SwiftUI

struct MapMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    
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
                viewModel.popupData = nil
                viewModel.popupCoordinate = nil
                viewModel.popupScreenPosition = .zero
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
        ZStack {
            MapView(
                userLocation: $locationManager.userLocation,
                region: $locationManager.region,
                shouldRecenter: $viewModel.shouldRecenter,
                selectedBrand: $viewModel.selectedBrand,
                displayMode: $viewModel.selectedDisplayMode,
                popupCoordinate: $viewModel.popupCoordinate,
                popupScreenPosition: $viewModel.popupScreenPosition,
                popupData: $viewModel.popupData,
                mapViewRef: $viewModel.mapViewRef
            )
            .edgesIgnoringSafeArea(.all)
            .id(viewModel.selectedBrand)
            
            if let data = viewModel.popupData {
                GeometryReader { geo in
                    let x = viewModel.popupScreenPosition.x
                    let y = viewModel.popupScreenPosition.y
                    VStack {
                        CustomPopupView(data: data)
                            .position(x: x, y: y-125)
                        
                    }
                }
            }
        }
    }
    
    private func renderSearchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.gray)
                .font(.system(size: 15))
            
            TextField("Cari brand Anda", text: $viewModel.searchText)
                .focused($isFocused)
                .onSubmit {
                    if let matchedBrand = EntityData.entities.first(where: { $0.properties.name.lowercased() == viewModel.searchText.lowercased() && $0.properties.objectType == "booth"}) {
                        viewModel.selectedBrand = [matchedBrand]
                        viewModel.saveSearchResult(brand: matchedBrand, context: context)
                    }
                    
                    viewModel.resetState()
                }
                .allowsHitTesting(!viewModel.shouldActivateSearchFlow)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 15)
        .background(colorScheme == .dark ? Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255) : Color.white)
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
            .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255))
            .background(colorScheme == .dark ? Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255) : Color.white)
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
                .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255))
                .background(colorScheme == .dark ? Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255) : Color.white)
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
                                    .fill(Color(red: 219 / 255, green: 40 / 255, blue: 78 / 255))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        
                        Text(category)
                            .padding(.leading, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedCategory = category
                    }
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.selectedCategory = ""
                    }) {
                        Text("Reset")
                            .frame(width: 120)
                            .padding()
                            .foregroundStyle(Color(red: 219 / 255, green: 40 / 255, blue: 78 / 255))
                            .background(Color.white)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(red: 219 / 255, green: 40 / 255, blue: 78 / 255), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        viewModel.applyCategory()
                    }) {
                        Text("Apply")
                            .foregroundStyle(Color.white)
                            .frame(width: 120)
                            .padding()
                            .background(Color(red: 219 / 255, green: 40 / 255, blue: 78 / 255))
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
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.searchSuggestions, id: \.self) { suggestion in
                SearchSuggestionRow(suggestion: suggestion)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func SearchSuggestionRow(suggestion: SearchResult) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(suggestion.name)
                    .font(.headline)
                Text("\(suggestion.hall)")
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.1), radius: 1, x: 0, y: 1)
        .onTapGesture {
            if let matchedBrand = EntityData.entities.first(where: { $0.properties.name.lowercased() == suggestion.name.lowercased() }) {
                viewModel.selectedBrand = [matchedBrand]
                viewModel.saveSearchResult(brand: matchedBrand, context: context)
                viewModel.loadRecentSearchResults(context: context)
            }
            isFocused = false
            
            viewModel.resetState()
        }
    }

    
    private func renderRecentSearches() -> some View {
        Group {
            if(viewModel.recentSearchResults.isEmpty) {
                Text("No recent searches!")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.recentSearchResults, id: \.self) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.name ?? "")
                                .font(.headline)
                                .foregroundStyle(Color.black)
                            
                            Text(result.hall ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            
                            Text(result.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                        .onTapGesture {
                            if let matchedBrand = EntityData.entities.first(where: { $0.properties.name.lowercased() == result.name?.lowercased() }) {
                                viewModel.selectedBrand = [matchedBrand]
                                viewModel.saveSearchResult(brand: matchedBrand, context: context)
                                isFocused = false
                                
                                viewModel.resetState()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func renderAllBrands() -> some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(EntityData.entities, id: \.self) { brand in
                    if brand.properties.objectType == "booth" {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(brand.properties.name)
                                .font(.headline)
                                .foregroundStyle(Color.black)
                            
                            Text(brand.properties.hall ?? "")
                                .font(.subheadline)
                                .foregroundStyle(Color.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                        .onTapGesture {
                            viewModel.selectedBrand = [brand]
                            viewModel.saveSearchResult(brand: brand, context: context)
                            isFocused = false
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
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
                                .padding(.bottom, 5)
                            renderRecentSearches()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        VStack(alignment: .leading) {
                            Text("All Brands")
                                .font(.title3)
                                .padding(.bottom, 5)
                            renderAllBrands()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    .padding(.top, 80)
                } else {
                    ScrollView() {
                        VStack{
                            Text("Search Results")
                            renderSearchSuggestions()
                        }
                        .padding(.top, 80)
                    }
                }
            } else { renderMap() }
            
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Home")
                    }
                    .foregroundStyle(Color.blue)
                }
            }
        }
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
    
struct MapMenuView_Preview: View {
    @StateObject private var viewModel = MapMenuViewModel()

    var body: some View {
        MapMenuView(viewModel: viewModel)
    }
}

#Preview {
    MapMenuView_Preview()
}
