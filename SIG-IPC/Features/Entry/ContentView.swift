import MapKit
import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @FocusState private var isFocused: Bool
    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    
    func renderMap() -> some View {
        MapView(userLocation: $locationManager.userLocation, region: $locationManager.region, shouldRecenter: $viewModel.shouldRecenter, selectedBrand: $viewModel.selectedBrand)
            .edgesIgnoringSafeArea(.all)
            .id(viewModel.selectedBrand)
    }
    
    func renderSearchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 15))
            
            TextField("Cari brand Anda", text: $viewModel.searchText)
                .padding(2)
                .focused($isFocused)
                .onSubmit {
                    viewModel.selectedBrand = [viewModel.searchText]
                }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(8)
        .padding(.horizontal)
        .onTapGesture {
            isFocused = true
        }
    }
    
    func renderCategoryBtn() -> some View {
        Image(systemName: "line.3.horizontal.decrease")
            .padding(10)
            .background(Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255))
            .cornerRadius(6)
            .onTapGesture {
                viewModel.showFilter = true
            }
    }
    
    func renderRecenterBtn() -> some View {
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
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        renderRecenterBtn()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
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
