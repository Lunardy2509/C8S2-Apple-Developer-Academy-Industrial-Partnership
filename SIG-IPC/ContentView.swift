import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State var shouldRecenter: Bool = false
    @FocusState private var isFocused: Bool
    @State private var searchText: String = ""
    @State var selectedBrand: String = ""

    var body: some View {
        ZStack{
            MapView(userLocation: $locationManager.userLocation, region: $locationManager.region, shouldRecenter: $shouldRecenter, selectedBrand: $selectedBrand)
                .edgesIgnoringSafeArea(.all)
                .id(selectedBrand)

            VStack{
                TextField("Cari brand booth", text: $searchText)
                    .padding()
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .cornerRadius(8)
                    .focused($isFocused)
                    .padding(.horizontal)
                    .onSubmit {
                        selectedBrand = searchText
                    }
                
                HStack{
                    Spacer()
                    Button(action: {
                        shouldRecenter = true
                    }, label:{
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    })
                }
                .padding()
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
