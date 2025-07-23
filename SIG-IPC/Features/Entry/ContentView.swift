import MapKit
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool

    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    
    private func renderMapCarousel() -> some View {
        VStack(alignment: .leading, spacing: 20){
            Text("My Event")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 10) {
                Image("Banner_JxB")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .cornerRadius(16)
                    .padding(.horizontal, 15)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Jakarta x Beauty 2025")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text("4-7 Juli 2025")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
        
                Button(action: {
                    print("Venue map tapped")
                    viewModel.displayMap.toggle()
                }) {
                    Text("View Venue Map")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 210/255, green: 49/255, blue: 68/255))
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
    }
    
    var body: some View {
        ZStack{
            Color.white
            VStack{
                Image("PlaceholderMainMenu")
                renderMapCarousel()
            }
            .fullScreenCover(isPresented: $viewModel.displayMap){
                NavigationStack {
                    MapMenuView()
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Venue Map")
                                    .font(.headline)
                                    .foregroundStyle(Color.black)
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    viewModel.displayMap.toggle()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(Color.white, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
            }
        }
    }
}

#Preview {
    ContentView(viewModel: ContentViewModel())
}