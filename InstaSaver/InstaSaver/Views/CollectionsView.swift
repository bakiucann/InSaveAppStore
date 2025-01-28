// CollectionsView.swift

import SwiftUI

struct CollectionsView: View {
    @ObservedObject var viewModel: CollectionsViewModel
    @State private var showCustomAlert = false
    @State private var newCollectionName = ""
    @State private var selectedCollection: CollectionModel? = nil
    
    var onCollectionSelected: (CollectionModel) -> Void
    var isPresentedModally: Bool = false
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            mainContent
            if viewModel.collections.isEmpty { EmptyCollectionsView() }
            if showCustomAlert { customAlertOverlay }
        }
        .navigationBarTitle("Collections", displayMode: .inline)
        .navigationBarItems(trailing: addButton)
        .onAppear {
            if viewModel.collections.isEmpty {
                viewModel.fetchCollections()
            }
        }
        .background(navigationLink)
    }
    
    private var mainContent: some View {
        VStack {
            ScrollView {
                if !viewModel.collections.isEmpty {
                    CollectionsListView(collections: viewModel.collections) {
                        handleCollectionSelection($0)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var addButton: some View {
        Button { showCustomAlert.toggle() } label: {
            ZStack {
                Circle()
                    .fill(instagramGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var navigationLink: some View {
        isPresentedModally ? nil : NavigationLink(
            destination: selectedCollection.map {
                CollectionDetailView(collection: $0, viewModel: CollectionsViewModel())
            },
            isActive: Binding(
                get: { selectedCollection != nil },
                set: { if !$0 { selectedCollection = nil } }
            )
        ) {
            EmptyView()
        }
    }
    
    private var customAlertOverlay: some View {
        CustomAlertView(
            isPresented: $showCustomAlert,
            text: $newCollectionName,
            title: NSLocalizedString("Create a Collection", comment: ""),
            message: NSLocalizedString("Enter collection name",comment: "collection name"),
            placeholder: NSLocalizedString("Collection Name", comment: ""),
            onCancel: { print("Creation cancelled") },
            onCreate: { addCollection() }
        )
        .transition(.scale)
        .animation(.easeInOut, value: showCustomAlert)
    }
    
    private func handleCollectionSelection(_ collection: CollectionModel) {
        isPresentedModally ? onCollectionSelected(collection) : (selectedCollection = collection)
    }
    
    private func addCollection() {
        guard !newCollectionName.isEmpty else {
            showAlert(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Collection Name cannot be empty.", comment: ""))
            return
        }
        viewModel.addCollection(name: newCollectionName)
        newCollectionName = ""
        showCustomAlert = false
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: NSLocalizedString("OK", comment: ""), style: .default))
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
}

struct EmptyCollectionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color("igPurple"),
                            Color("igPink")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )
                .shadow(color: Color("igPink").opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("No Collections Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Create your first collection to organize your downloads")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

struct CollectionsListView: View {
    let collections: [CollectionModel]
    let onCollectionSelected: (CollectionModel) -> Void
    
    var body: some View {
        LazyVStack(spacing: 15) {
            ForEach(collections, id: \.id) { collection in
                CollectionRowView(
                    collection: collection,
                    coverImageData: getMostRecentCover(for: collection)
                )
                .onTapGesture { onCollectionSelected(collection) }
            }
        }
        .padding(.vertical)
    }
    
    private func getMostRecentCover(for collection: CollectionModel) -> Data? {
        guard let videos = collection.videos as? Set<BookmarkedVideo>, !videos.isEmpty else { return nil }
        let sorted = videos.sorted { ($0.dateAdded ?? .distantPast) > ($1.dateAdded ?? .distantPast) }
        return sorted.first?.coverImageData
    }
}

struct CollectionRowView: View {
    var collection: CollectionModel
    var coverImageData: Data?
    
    var body: some View {
        HStack(spacing: 15) {
            coverImage
            
            VStack(alignment: .leading, spacing: 6) {
                Text(collection.name ?? "Unknown Collection")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                HStack(spacing: 4) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("igPink"))
                    
                    Text("\(collection.videos?.count ?? 0) \(NSLocalizedString("videos", comment: ""))")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("igPink"))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("igPurple").opacity(0.2),
                            Color("igPink").opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private var coverImage: some View {
        Group {
            if let data = coverImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                Image("empty.insta")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 45)
            }
        }
        .aspectRatio(contentMode: .fill)
        .frame(width: 60, height: 60)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("igPink").opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct CollectionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CollectionsView(
                viewModel: CollectionsViewModel(),
                onCollectionSelected: { _ in },
                isPresentedModally: false
            )
        }
    }
}
