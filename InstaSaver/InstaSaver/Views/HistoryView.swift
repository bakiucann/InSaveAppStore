// HistoryView.swift

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @StateObject private var videoViewModel = VideoViewModel()
    @State private var selectedStories: [InstagramStoryModel] = []
    @State private var showStoryView = false
    @State private var isLoadingStory = false
    @State private var showClearAlert = false
    
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
            // MARK: - Animated Background
            animatedBackground
            
            VStack(spacing: 0) {
                // MARK: - Glassmorphic Header
                glassmorphicHeader
                
                if viewModel.history.isEmpty {
                    GlassmorphicEmptyHistoryView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.history, id: \.id) { historyItem in
                                GlassmorphicHistoryItemRow(
                                    historyItem: historyItem,
                                    videoViewModel: videoViewModel,
                                    onDelete: {
                                        viewModel.deleteHistoryItem(historyItem)
                                    },
                                    onPlay: {
                                        if historyItem.type == "story" {
                                            // Story için StoryView'ı aç
                                            isLoadingStory = true
                                            selectedStories = [
                                                InstagramStoryModel(
                                                    type: "video",
                                                    url: historyItem.originalUrl ?? "",
                                                    thumbnailUrl: historyItem.originCover ?? "",
                                                    takenAt: Int(historyItem.date.timeIntervalSince1970)
                                                )
                                            ]
                                            
                                            // Thumbnail'i önceden yükle
                                            if let thumbnailUrl = URL(string: historyItem.originCover ?? "") {
                                                URLSession.shared.dataTask(with: thumbnailUrl) { _, _, _ in
                                                    DispatchQueue.main.async {
                                                        isLoadingStory = false
                                                        showStoryView = true
                                                    }
                                                }.resume()
                                            } else {
                                                isLoadingStory = false
                                                showStoryView = true
                                            }
                                        } else {
                                            // Normal video için PreviewView'ı aç
                                            let video = InstagramVideoModel(
                                                id: historyItem.id,
                                                allVideoVersions: [
                                                    VideoVersion(
                                                        type: 101,
                                                        width: 1080,
                                                        height: 1920,
                                                        id: historyItem.id + "_hd",
                                                        url: historyItem.originalUrl ?? ""
                                                    ),
                                                    VideoVersion(
                                                        type: 103,
                                                        width: 720,
                                                        height: 1280,
                                                        id: historyItem.id + "_sd",
                                                        url: historyItem.originalUrl ?? ""
                                                    )
                                                ],
                                                downloadLink: historyItem.originalUrl ?? "",
                                                thumbnailUrl: historyItem.originCover ?? "",
                                                videoTitle: historyItem.title,
                                                videoQuality: VideoQuality.default,
                                                isPhoto: historyItem.type == "photo",
                                                isCarousel: false
                                            )
                                            videoViewModel.setVideo(video)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // Loading Overlay
            if videoViewModel.isLoading || isLoadingStory {
                GlassmorphicHistoryLoadingView()
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showClearAlert) {
            Alert(
                title: Text("Clear History"),
                message: Text("Are you sure you want to clear all history items?"),
                primaryButton: .destructive(Text("Clear")) {
                    viewModel.clearAllHistory()
                },
                secondaryButton: .cancel()
            )
        }
        .fullScreenCover(isPresented: $showStoryView) {
            NavigationView {
                StoryView(stories: selectedStories, isFromHistory: true)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { videoViewModel.video != nil && !videoViewModel.isLoading },
            set: { showPreview in
                if !showPreview {
                    videoViewModel.clearVideoData()
                }
            }
        )) {
            if let video = videoViewModel.video {
                NavigationView {
                    PreviewView(video: video)
                }
            }
        }
    }
    
    // MARK: - Animated Background
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
            
            // Subtle orbs
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
                    .offset(x: -50, y: 80)
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
                    .offset(x: geometry.size.width - 80, y: geometry.size.height - 250)
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

    // MARK: - Glassmorphic Header
    private var glassmorphicHeader: some View {
        HStack {
            // Title with gradient
            Text(NSLocalizedString("History", comment: ""))
                .font(.system(size: 28, weight: .bold))
                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            
            Spacer()
            
            // Clear All Button
            if !viewModel.history.isEmpty {
                Button(action: { showClearAlert = true }) {
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.red.opacity(0.25), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        // Main circle with red tint
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.95),
                                        Color(red: 1.0, green: 0.92, blue: 0.92)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        // Red overlay tint
                        Circle()
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        // Border
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.8), Color.red.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 44, height: 44)
                        
                        // Stacked layers icon with X badge
                        ZStack {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                            
                            // X badge
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.9, green: 0.2, blue: 0.2))
                                        .frame(width: 13, height: 13)
                                )
                                .offset(x: 9, y: -9)
                        }
                    }
                    .shadow(color: Color.red.opacity(0.2), radius: 12, x: 0, y: 4)
                }
                .accessibilityLabel(NSLocalizedString("Clear All", comment: ""))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
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
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Glassmorphic Empty History View
struct GlassmorphicEmptyHistoryView: View {
    @State private var floatAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Floating icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igPink").opacity(0.3), Color.clear],
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
                                    colors: [Color.white.opacity(0.8), Color("igPink").opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color("igPurple").opacity(0.2), radius: 15, x: 0, y: 8)
                
                Image(systemName: "clock.fill")
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
                Text(NSLocalizedString("No History Available", comment: ""))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                
                Text(NSLocalizedString("Your downloaded videos will appear here", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Glassmorphic History Item Row
struct GlassmorphicHistoryItemRow: View {
    let historyItem: HistoryItem
    @ObservedObject var videoViewModel: VideoViewModel
    var onDelete: () -> Void
    var onPlay: () -> Void
    
    @State private var isPressed = false
    
    private var displayTitle: String {
        let trimmed = historyItem.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            switch historyItem.type {
            case "story":
                return NSLocalizedString("Instagram Story", comment: "")
            case "photo":
                return NSLocalizedString("Instagram Photo", comment: "")
            default:
                return NSLocalizedString("Instagram Video", comment: "")
            }
        }
        return trimmed
    }
    
    private var contentTypeInfo: (icon: String, label: String, color: Color) {
        switch historyItem.type {
        case "story":
            return ("clock.arrow.circlepath", "Story", Color("igOrange"))
        case "photo":
            return ("photo.fill", "Photo", Color("igPink"))
        default:
            return ("play.rectangle.fill", "Video", Color("igPurple"))
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            GlassmorphicThumbnailImage(imageData: historyItem.coverImageData, contentType: historyItem.type)
            
            // Content - Same structure for all types
            VStack(alignment: .leading, spacing: 6) {
                Text(displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.85))
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                HStack(spacing: 6) {
                    // Type badge
                    typeBadge
                    
                    // Date
                    Text(historyItem.date, style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                // Delete Button
                Button(action: onDelete) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color("igPink").opacity(0.2), lineWidth: 1)
                            )
                        
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .gradientForeground(colors: [Color("igPink"), Color("igOrange")])
                    }
                }
                
                // Play Button - Glassmorphic style
                Button(action: onPlay) {
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color("igPink").opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        // Glass circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.95), Color.white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.8), Color("igPink").opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: Color("igPurple").opacity(0.15), radius: 8, x: 0, y: 4)
                        
                        // Play icon with gradient
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                            .offset(x: 1)
                    }
                }
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("igPurple").opacity(0.02),
                                Color("igPink").opacity(0.01)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 18)
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
        .shadow(color: Color("igPurple").opacity(0.08), radius: 12, x: 0, y: 6)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
    
    private var typeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: contentTypeInfo.icon)
                .font(.system(size: 10))
            
            Text(contentTypeInfo.label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(contentTypeInfo.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(contentTypeInfo.color.opacity(0.1))
        )
    }
}

// MARK: - Glassmorphic Thumbnail Image
struct GlassmorphicThumbnailImage: View {
    let imageData: Data?
    var contentType: String = "video"
    
    private var placeholderIcon: String {
        switch contentType {
        case "story":
            return "clock.arrow.circlepath"
        case "photo":
            return "photo.fill"
        default:
            return "play.rectangle.fill"
        }
    }
    
    private var placeholderColors: [Color] {
        switch contentType {
        case "story":
            return [Color("igOrange").opacity(0.15), Color("igPink").opacity(0.1)]
        case "photo":
            return [Color("igPink").opacity(0.15), Color("igPurple").opacity(0.1)]
        default:
            return [Color("igPurple").opacity(0.15), Color("igPink").opacity(0.1)]
        }
    }
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: placeholderColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: placeholderIcon)
                        .font(.system(size: 22, weight: .medium))
                        .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color("igPink").opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color("igPurple").opacity(0.12), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Glassmorphic History Loading View
struct GlassmorphicHistoryLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 1).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                VStack(spacing: 6) {
                    Text(NSLocalizedString("Loading...", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Text(NSLocalizedString("Please wait", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            .padding(32)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                    
                    RoundedRectangle(cornerRadius: 24)
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
                    
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color("igPink").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color("igPurple").opacity(0.15), radius: 20, x: 0, y: 10)
            .onAppear {
                isAnimating = true
            }
        }
    }
}

// MARK: - Legacy Components (kept for compatibility)

struct EmptyHistoryView: View {
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
                    Image(systemName: "clock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )
                .shadow(color: Color("igPink").opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("No History Available", comment: ""))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                
                Text(NSLocalizedString("Your downloaded videos will appear here", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

struct HistoryItemRow: View {
    let historyItem: HistoryItem
    @ObservedObject var videoViewModel: VideoViewModel
    var onDelete: () -> Void
    var onPlay: () -> Void
    
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
        HStack(spacing: 15) {
            ThumbnailImage(imageData: historyItem.coverImageData)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(historyItem.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                HStack(spacing: 6) {
                    Image(systemName: historyItem.type == "story" ? "clock.arrow.circlepath" : "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(Color("igPink"))
                    
                    Text(historyItem.date, style: .date)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("igPink"))
                        .frame(width: 36, height: 36)
                        .background(Color("igPink").opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: onPlay) {
                    ZStack {
                        Circle()
                            .fill(instagramGradient)
                            .frame(width: 35, height: 35)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
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
}

struct ThumbnailImage: View {
    let imageData: Data?
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image("empty.insta")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 45)
            }
        }
        .frame(width: 60, height: 60)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("igPink").opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct HistoryLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 4)
                        .frame(width: 50, height: 50)
                        .foregroundColor(Color.white.opacity(0.2))
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 1)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                .onAppear {
                    isAnimating = true
                }
                
                Text("Loading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Please wait")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 20)
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryView(viewModel: HistoryViewModel())
        }
    }
}
