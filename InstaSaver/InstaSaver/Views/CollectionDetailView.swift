// CollectionDetailView.swift

import SwiftUI

struct CollectionDetailView: View {
    var collection: CollectionModel
    @ObservedObject var viewModel: CollectionsViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var bottomSheetManager: BottomSheetManager
    @State private var showRenameAlert = false
    @State private var newCollectionName: String = ""
    @State private var showDeleteAlert = false
    @State private var selectedVideo: BookmarkedVideo?
    
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
        GeometryReader { geometry in
            let itemSize = (geometry.size.width / 3) - 16 // 3 sütun için thumbnail boyutu
            
            ZStack {
                Color(.white)
                    .ignoresSafeArea()
                
                VStack {
                    if let videosSet = collection.videos as? Set<BookmarkedVideo>, !videosSet.isEmpty {
                        let videos = Array(videosSet).sorted {
                            (video1: BookmarkedVideo, video2: BookmarkedVideo) -> Bool in
                            (video1.dateAdded ?? Date()) > (video2.dateAdded ?? Date())
                        }
                        
                        let columns = [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ]
                        
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(videos, id: \.self) { video in
                                    VideoThumbnailView(video: video, itemSize: itemSize) {
                                        selectedVideo = video
                                        showActionSheet(for: video)
                                    }
                                }
                            }
                            .padding()
                        }
                    } else {
                        EmptyCollectionView()
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .navigationTitle(collection.name ?? "Collection")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        GlassmorphicBackButton {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    MenuButton {
                        showCollectionOptions()
                    }
                }
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Video"),
                message: Text("Do you want to delete this video from the collection?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let video = selectedVideo {
                        deleteVideoFromCollection(video: video)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .customAlert(
            isPresented: $showRenameAlert,
            title: NSLocalizedString("Rename Collection", comment: "Alert title for renaming a collection"),
            text: $newCollectionName,
            placeholder: NSLocalizedString("New collection name", comment: "Placeholder text for new collection name input"),
            onSave: renameCollection
        )
    }
    
    private func showCollectionOptions() {
        let renameAction = BottomSheetAction(
            label: NSLocalizedString("Rename", comment: ""),
            background: Color("igPink"),
            textColor: .white,
            action: { showRenameAlert = true }
        )
        
        let deleteCollectionAction = BottomSheetAction(
            label: NSLocalizedString("Delete Collection", comment: ""),
            background: .red,
            textColor: .white,
            action: { deleteCollection() }
        )
        
        bottomSheetManager.actions = [renameAction, deleteCollectionAction]
        bottomSheetManager.showBottomSheet = true
    }
    
    private func showActionSheet(for video: BookmarkedVideo) {
        let openInstagramAction = BottomSheetAction(
            label: NSLocalizedString("Open on Instagram", comment: "Button to open video on Instagram"),
            background: Color("igPink"),
            textColor: .white,
            action: {
                if let videoID = video.id {
                    let cleanID = videoID.components(separatedBy: "?").first ?? videoID
                    let cleanerID = cleanID.components(separatedBy: "/").last ?? cleanID
                    
                    // Check if the original URL contains "reel" or "reels" to determine the type
                    let urlString = (videoID.contains("reel") || videoID.contains("reels")) ? 
                        "https://www.instagram.com/reel/\(cleanerID)/" :
                        "https://www.instagram.com/p/\(cleanerID)/"
                        
                    if let videoUrl = URL(string: urlString) {
                        UIApplication.shared.open(videoUrl)
                    }
                }
            }
        )
        
        
        let deleteVideoAction = BottomSheetAction(
            label: NSLocalizedString("Delete", comment: ""),
            background: .red,
            textColor: .white,
            action: {
                showDeleteAlert = true
            }
        )
        
        bottomSheetManager.actions = [openInstagramAction, deleteVideoAction]
        bottomSheetManager.showBottomSheet = true
    }
    
    private func deleteVideoFromCollection(video: BookmarkedVideo) {
        viewModel.deleteVideoFromCollection(collection: collection, video: video)
        viewModel.updateCollectionAfterVideoDeletion(collection)
    }
    
    private func deleteCollection() {
        if let context = collection.managedObjectContext {
            context.delete(collection)
            try? context.save()
            viewModel.fetchCollections() // Refresh collections after rename
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: collection.managedObjectContext)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func renameCollection() {
        guard !newCollectionName.isEmpty else { return }
        collection.name = newCollectionName
        try? collection.managedObjectContext?.save()
        viewModel.fetchCollections() // Refresh collections after rename
        NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: collection.managedObjectContext)
    }
}

struct VideoThumbnailView: View {
    let video: BookmarkedVideo
    let itemSize: CGFloat
    let onTap: () -> Void
    
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
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Thumbnail Image
                Group {
                    if let imageData = video.coverImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image("empty.insta")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                }
                .frame(width: itemSize, height: itemSize * 1.5)
                .clipped()
                
                // Gradient overlay at bottom
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.5), .clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                .frame(height: itemSize * 0.5)
                
                // Date label
                if let date = video.dateAdded {
                    Text(date, style: .date)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                        .padding(6)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
}

// BackButtons is now replaced by GlassmorphicBackButton in Utilities/GlassmorphicBackButton.swift

struct MenuButton: View {
    let action: () -> Void
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(instagramGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct EmptyCollectionView: View {
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
        VStack(spacing: 24) {
            Circle()
                .fill(instagramGradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "photo.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )
                .shadow(color: Color("igPink").opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("No Videos", comment: ""))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                
                Text(NSLocalizedString("This collection has no videos yet", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        title: String,
        text: Binding<String>,
        placeholder: String,
        onSave: @escaping () -> Void
    ) -> some View {
        ZStack {
            self.blur(radius: isPresented.wrappedValue ? 2 : 0)
                .animation(.easeInOut, value: isPresented.wrappedValue)
            
            if isPresented.wrappedValue {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented.wrappedValue = false
                    }
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    TextField(placeholder, text: text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            isPresented.wrappedValue = false
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gray)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            onSave()
                            isPresented.wrappedValue = false
                        }) {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color("igPink"))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 40)
            }
        }
    }
}
