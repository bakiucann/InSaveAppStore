// CollectionDetailView.swift

import SwiftUI

struct CollectionDetailView: View {
    @ObservedObject var collection: CollectionModel
    @ObservedObject var viewModel: CollectionsViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var bottomSheetManager: BottomSheetManager // For video actions only
    @State private var showRenameAlert = false
    @State private var newCollectionName: String = ""
    @State private var showDeleteAlert = false
    @State private var selectedVideo: BookmarkedVideo?
    @State private var showOptionsMenu = false
    
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
                // Glassmorphic Animated Background
                animatedBackground
                
                VStack(spacing: 0) {
                    // Custom Navigation Bar
                    glassmorphicNavBar
                    
                    // Content
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
                        
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(videos, id: \.self) { video in
                                    VideoThumbnailView(video: video, itemSize: itemSize) {
                                        selectedVideo = video
                                        showActionSheet(for: video)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                        }
                    } else {
                        EmptyCollectionView()
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .navigationBarHidden(true)
        }
        .onAppear {
            // Initialize rename text with current collection name when showing alert
            newCollectionName = collection.name ?? ""
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
        .overlay(
            // Glassmorphic Rename Alert (without gray overlay)
            GlassmorphicTextInputAlert(
                isPresented: $showRenameAlert,
                inputText: $newCollectionName,
                title: NSLocalizedString("Rename Collection", comment: ""),
                placeholder: NSLocalizedString("New collection name", comment: ""),
                icon: "pencil",
                onSave: renameCollection,
                showOverlay: false // No gray overlay in CollectionDetailView
            )
        )
        .overlay(
            // Glassmorphic Dropdown Menu
            Group {
                if showOptionsMenu {
                    GlassmorphicDropdownMenu(
                        isPresented: $showOptionsMenu,
                        onRename: {
                            showOptionsMenu = false
                            newCollectionName = collection.name ?? ""
                            showRenameAlert = true
                        },
                        onDelete: {
                            showOptionsMenu = false
                            deleteCollection()
                        }
                    )
                }
            }
        )
    }
    
    private func showCollectionOptions() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            showOptionsMenu.toggle()
        }
    }
    
    private func showActionSheet(for video: BookmarkedVideo) {
        // Video actions still use bottom sheet (keep for now)
        // This is separate from collection options menu
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
        
        // Video actions use CustomBottomSheet
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
            viewModel.refreshCollections() // Refresh collections after delete
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func renameCollection() {
        guard !newCollectionName.isEmpty else { return }
        
        // Update the collection name
        collection.name = newCollectionName
        
        // Save to Core Data
        if let context = collection.managedObjectContext {
            do {
                try context.save()
                // The @ObservedObject will automatically update the UI
            } catch {
                print("Error saving collection name: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Glassmorphic Components
    
    private var animatedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color("igPurple").opacity(0.02),
                    Color("igPink").opacity(0.03),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igPurple").opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: 150)
                    .blur(radius: 40)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igOrange").opacity(0.06), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .offset(x: geometry.size.width - 80, y: geometry.size.height - 200)
                    .blur(radius: 50)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igPink").opacity(0.05), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)
                    .offset(x: geometry.size.width / 2, y: 300)
                    .blur(radius: 35)
            }
        }
    }
    
    private var glassmorphicNavBar: some View {
        HStack {
            // Back button
            GlassmorphicBackButton {
                presentationMode.wrappedValue.dismiss()
            }
            
            Spacer()
            
            // Title with gradient
            Text(collection.name ?? "Collection")
                .font(.system(size: 17, weight: .bold))
                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            
            Spacer()
            
            // Menu button with context menu
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    showOptionsMenu.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color("igPurple").opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("igPink"))
                        .rotationEffect(.degrees(90))
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("igPurple").opacity(0.03),
                                Color("igPink").opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color("igPurple").opacity(0.06), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct VideoThumbnailView: View {
    let video: BookmarkedVideo
    let itemSize: CGFloat
    let onTap: () -> Void
    
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
                        // Glassmorphic placeholder
                        ZStack {
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
                            
                            Image("empty.insta")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
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
                
                // Date label with glassmorphic background
                if let date = video.dateAdded {
                    Text(date, style: .date)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .padding(6)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .cornerRadius(12)
        .shadow(color: Color("igPurple").opacity(0.08), radius: 10, x: 0, y: 5)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color("igPurple").opacity(0.15),
                            Color("igPink").opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Glassmorphic Menu Button
struct GlassmorphicMenuButton: View {
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    @State private var splashScale: CGFloat = 0.0
    @State private var splashOpacity: Double = 0.0
    
    var body: some View {
        Button(action: {
            // Trigger liquid splash animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                splashScale = 1.3
                splashOpacity = 0.5
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    splashScale = 0.0
                    splashOpacity = 0.0
                }
                isPressed = false
            }
            
            action()
        }) {
            ZStack {
                // Liquid splash effect
                if isPressed {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("igPink").opacity(0.35),
                                    Color("igPurple").opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 3,
                                endRadius: 20
                            )
                        )
                        .frame(width: 36, height: 36)
                        .scaleEffect(splashScale)
                        .opacity(splashOpacity)
                        .blur(radius: 6)
                }
                
                // Icon with gradient
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("igPink"))
                    .scaleEffect(isPressed ? 1.08 : 1.0)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyCollectionView: View {
    @State private var floatAnimation = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Floating animated icon with glassmorphic design
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
                
                // Glassmorphic circle
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
                
                Image(systemName: "photo.fill")
                    .font(.system(size: 36, weight: .medium))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            }
            .offset(y: floatAnimation ? -8 : 8)
            .animation(
                Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                value: floatAnimation
            )
            .onAppear {
                floatAnimation = true
            }
            
            // Text content with glassmorphic card
            VStack(spacing: 12) {
                Text(NSLocalizedString("No Videos", comment: ""))
                    .font(.system(size: 24, weight: .bold))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                
                Text(NSLocalizedString("This collection has no videos yet", comment: ""))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color("igPurple").opacity(0.08), radius: 15, x: 0, y: 8)
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}
