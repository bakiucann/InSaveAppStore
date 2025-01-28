// VideoCoverImage.swift

import SwiftUI

struct VideoCoverImage: View {
    let urlString: String
    @State private var imageData: Data?
    @State private var isLoading = false
    @State private var loadError: IdentifiableError?
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .background(
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 5, y: 5)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 2)
                    )
            } else if isLoading {
                ProgressView()
            } else {
                Image("empty.insta")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .background(
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 5, y: 5)
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 2)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .alert(item: $loadError) { identifiableError in
            Alert(title: Text("Error"), message: Text("Failed to load image: \(identifiableError.error.localizedDescription)"), dismissButton: .default(Text("OK")))
        }
    }
    
    private func loadImage() {
        guard let url = URL(string: urlString) else {
            self.loadError = IdentifiableError(error: URLError(.badURL))
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    self.loadError = IdentifiableError(error: error)
                    return
                }
                
                if let data = data {
                    self.imageData = data
                } else {
                    self.loadError = IdentifiableError(error: URLError(.cannotLoadFromNetwork))
                }
            }
        }.resume()
    }
}
