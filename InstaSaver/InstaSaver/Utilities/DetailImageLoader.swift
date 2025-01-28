// DetailImageLoader.swift

import SwiftUI
import Combine

class DetailImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    
    func loadImage(from url: URL) {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.image = image
            }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

struct CustomDetailAsyncImage: View {
    @StateObject private var loader = DetailImageLoader()
    let url: URL?
    let placeholder: Image
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        if let url = url {
            ZStack {
                if let image = loader.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height) // Dinamik boyut
                        .clipped()
                } else {
                    placeholder
                        .resizable()
                        .scaledToFit()
                        .frame(width: width, height: height) // Dinamik boyut
                        .onAppear {
                            loader.loadImage(from: url)
                        }
                }
            }
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
        } else {
            placeholder
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height) // Dinamik boyut
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
    }
}
