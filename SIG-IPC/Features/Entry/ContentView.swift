import MapKit
import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func renderMap() -> some View {
        MapView(userLocation: $locationManager.userLocation, region: $locationManager.region, shouldRecenter: $viewModel.shouldRecenter, selectedBrand: $viewModel.selectedBrand)
            .edgesIgnoringSafeArea(.all)
            .id(viewModel.selectedBrand)
    }
    
    func renderSearchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
            
            TextField("Cari brand Anda", text: $viewModel.searchText)
                .padding(2)
                .focused($isFocused)
                .onSubmit {
                    viewModel.selectedBrand = [viewModel.searchText]
                }
        }
        .padding(8)
        .background(colorScheme == .dark ? Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255) : Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .onTapGesture {
            isFocused = true
        }
    }
    
    func renderCategoryBtn() -> some View {
        Image(systemName: "line.3.horizontal.decrease")
            .padding()
            .background(colorScheme == .dark ? Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255) : Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .onTapGesture {
                viewModel.showFilter = true
            }
    }
    
    func renderRecenterBtn() -> some View {
        Button(action: {
            viewModel.shouldRecenter = true
        }, label:{
            Image(systemName: "location")
                .padding(8)
                .font(.system(size: 30))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255))
                .background(colorScheme == .dark ? Color(red: 95 / 255, green: 95 / 255, blue: 95 / 255) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 3)
        })
    }
    
    func renderCategorySheet() -> some View {
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
                            .foregroundStyle(Color.white)
                            .frame(width: 120)
                            .padding()
                            .background(Color(red: 219 / 255, green: 40 / 255, blue: 78 / 255))
                            .cornerRadius(18)
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
        
    
    var body: some View {
        ZStack {
            renderMap()

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        renderSearchBar()
                        renderCategoryBtn()
                    }
                    .padding(.horizontal)

                    /// conditionally render suggestions list
                    if isFocused && !viewModel.searchSuggestions.isEmpty {
                        List(viewModel.searchSuggestions, id: \.self) { suggestion in
                            Text(suggestion)
                                .onTapGesture {
                                    viewModel.selectSuggestion(suggestion)
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
                }
                .padding(.top)
                
                HStack {
                    Spacer()
                    renderRecenterBtn()
                }
                .padding(.top)
                .padding(.horizontal)
                
                Spacer()

            }
        }
        .sheet(isPresented: $viewModel.showFilter) {
            renderCategorySheet()
                .presentationDetents([.fraction(0.65), .fraction(0.99)])
                .presentationDragIndicator(.visible)
        }
        .onTapGesture {
            isFocused = false
        }
    }
}

#Preview {
    ContentView()
}
    
