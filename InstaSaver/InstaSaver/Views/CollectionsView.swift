// CollectionsView.swift

import SwiftUI

struct CollectionsView: View {
    @ObservedObject var viewModel: CollectionsViewModel
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
            Color.white
                .ignoresSafeArea()
            
            mainContent
            if viewModel.collections.isEmpty { EmptyCollectionsView() }
        }
        .navigationBarTitle("Collections", displayMode: .inline)
        .navigationBarItems(trailing: glassmorphicAddButton)
        .onAppear {
            if viewModel.collections.isEmpty {
                viewModel.fetchCollections()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            // Refresh collections when any Core Data change occurs
            viewModel.refreshCollections()
        }
        .background(navigationLink)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                if !viewModel.collections.isEmpty {
                    CollectionsListView(collections: viewModel.collections) {
                        handleCollectionSelection($0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }
    
    private var glassmorphicAddButton: some View {
        Button(action: { viewModel.showCreateCollectionAlert = true }) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.clear)
                .overlay(
                    instagramGradient
                        .mask(
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var navigationLink: some View {
        isPresentedModally ? nil : NavigationLink(
            destination: selectedCollection.map {
                CollectionDetailView(collection: $0, viewModel: viewModel)
            },
            isActive: Binding(
                get: { selectedCollection != nil },
                set: { if !$0 { selectedCollection = nil } }
            )
        ) {
            EmptyView()
        }
    }
    
    private func handleCollectionSelection(_ collection: CollectionModel) {
        isPresentedModally ? onCollectionSelected(collection) : (selectedCollection = collection)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: NSLocalizedString("OK", comment: ""), style: .default))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

struct EmptyCollectionsView: View {
    @State private var floatAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Floating animated icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igPurple").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                // Glass circle
                        Circle()
                            .fill(
                                LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    .frame(width: 90, height: 90)
                    .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                    colors: [Color.white.opacity(0.8), Color("igPurple").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                    )
                    .shadow(color: Color("igPurple").opacity(0.2), radius: 15, x: 0, y: 8)
                
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 36, weight: .medium))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            }
            .offset(y: floatAnimation ? -8 : 8)
            .animation(
                Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                value: floatAnimation
            )
            .onAppear { floatAnimation = true }
            
            // Text content
            VStack(spacing: 10) {
                Text(NSLocalizedString("No Collections Yet", comment: ""))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                
                Text(NSLocalizedString("Create your first collection to organize your downloads", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

struct CollectionsListView: View {
    let collections: [CollectionModel]
    let onCollectionSelected: (CollectionModel) -> Void
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(collections, id: \.id) { collection in
                CollectionRowView(
                    collection: collection,
                    coverImageData: getMostRecentCover(for: collection)
                )
                .onTapGesture { onCollectionSelected(collection) }
            }
        }
    }
    
    private func getMostRecentCover(for collection: CollectionModel) -> Data? {
        guard let videos = collection.videos as? Set<BookmarkedVideo>, !videos.isEmpty else { return nil }
        let sorted = videos.sorted { ($0.dateAdded ?? .distantPast) > ($1.dateAdded ?? .distantPast) }
        return sorted.first?.coverImageData
    }
}

struct CollectionRowView: View {
    @ObservedObject var collection: CollectionModel
    var coverImageData: Data?
    
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
        HStack(spacing: 12) {
            // Cover Image with Glassmorphic Border
            coverImage
            
            // Collection Info
            VStack(alignment: .leading, spacing: 5) {
                Text(collection.name ?? NSLocalizedString("Unknown Collection", comment: ""))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black.opacity(0.9))
                
                HStack(spacing: 5) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.clear)
                        .overlay(
                            instagramGradient
                                .mask(
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 12))
                                )
                        )
                    
                    Text("\(collection.videos?.count ?? 0) \(NSLocalizedString("videos", comment: ""))")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Chevron Icon with Gradient
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.clear)
                .overlay(
                    instagramGradient
                        .mask(
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                        )
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Glassmorphic Background
                if #available(iOS 15.0, *) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Tinted Gradient Overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("igPurple").opacity(0.06),
                                Color("igPink").opacity(0.04),
                                Color("igOrange").opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 6)
        .shadow(color: Color("igPink").opacity(0.08), radius: 20, x: 0, y: 8)
    }
    
    private var coverImage: some View {
        Group {
            if let data = coverImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                ZStack {
                    // Glassmorphic placeholder background
                    if #available(iOS 15.0, *) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("igPurple").opacity(0.08),
                                    Color("igPink").opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image("empty.insta")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .opacity(0.5)
                }
            }
        }
        .aspectRatio(contentMode: .fill)
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("igPurple").opacity(0.3),
                            Color("igPink").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        .shadow(color: Color("igPink").opacity(0.12), radius: 10, x: 0, y: 4)
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
