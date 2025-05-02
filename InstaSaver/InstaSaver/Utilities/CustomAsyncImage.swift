// CustomAsyncImage.swift

import SwiftUI
import Combine

class ImageLoader: ObservableObject {
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

import SwiftUI

struct CustomAsyncImage: View {
    @StateObject private var loader = ImageLoader()
    let url: URL?
    let placeholder: Image
    
    var body: some View {
        if let url = url {
            ZStack {
                if let image = loader.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .onAppear {
                            loader.loadImage(from: url)
                        }
                }
            }
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
        } else {
            placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
    }
}
