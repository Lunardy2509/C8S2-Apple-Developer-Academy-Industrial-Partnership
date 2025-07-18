import MapKit
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context

    @StateObject private var locationManager = LocationManager()
    @FocusState private var isFocused: Bool
    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    
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
                .padding(2)
                .focused($isFocused)
                .onSubmit {
                    if let matchedBrand = BrandData.brands.first(where: { $0.name.lowercased() == viewModel.searchText.lowercased() }) {
                        viewModel.selectedBrand = [matchedBrand]
                    }
                }
                .allowsHitTesting(!viewModel.shouldActivateSearchFlow)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .padding(.horizontal)
        .simultaneousGesture(
            TapGesture().onEnded {
                activateSearchFlowIfNeeded()
            }
        )
    }
    private func renderCategoryBtn() -> some View {
        Image(systemName: "line.3.horizontal.decrease")
            .padding()
            .background(Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255))
            .cornerRadius(8)
            .onTapGesture {
                viewModel.showFilter = true
            }
    }
    private func renderRecenterBtn() -> some View {
        Button(action: {
            viewModel.shouldRecenter = true
        }, label:{
            Image(systemName: "location.fill")
                .padding(8)
                .font(.system(size: 30))
                .foregroundStyle(Color.white)
                .background(Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 3)
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
            .onTapGesture {
                print("ROW PRESSED")
                if let matchedBrand = BrandData.brands.first(where: { $0.name.lowercased() == suggestion.name.lowercased() }) {
                    viewModel.selectedBrand = [matchedBrand]
                }
                isFocused = false
            }
        }
        .listStyle(.plain)
        .background(Color.white)
        .cornerRadius(8)
        .frame(maxHeight: 200)
        .padding(.horizontal)
        .shadow(radius: 5)
    }
    
    var body: some View {
            ZStack {
                if(isFocused) {
                    ZStack {
                        Color.gray.opacity(0.3)
                        /// conditionally render suggestions list
                        if !viewModel.searchSuggestions.isEmpty {
                            renderSearchSuggestions()
                        }
                    }
                } else { renderMap() }

                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            renderSearchBar()
                                .onChange(of: viewModel.searchText) { newText in
                                    if newText.isEmpty {
                                        viewModel.loadRecentSearchResults(context: context)
                                    }
                                }

                            renderCategoryBtn()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        renderRecenterBtn()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .safeAreaInset(edge: .bottom) {
                segmentedControlInset()
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

#Preview {
    ContentView()
}
