// HistoryView.swift

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @StateObject private var videoViewModel = VideoViewModel()
    @State private var selectedStories: [InstagramStoryModel] = []
    @State private var showStoryView = false
    @State private var isLoadingStory = false
    
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
            Color(.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if viewModel.history.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.history, id: \.id) { historyItem in
                                HistoryItemRow(
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
                                                videoQuality: VideoQuality.default
                                            )
                                            videoViewModel.setVideo(video)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                }
            }
            
            if videoViewModel.isLoading || isLoadingStory {
                HistoryLoadingView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("History")
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
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
}

// MARK: - Supporting Views
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
            
            HStack(spacing: 12) {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("igPink"))
                        .frame(width: 36, height: 36)
                        .background(Color("igPink").opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: onPlay) {
                    ZStack {
                        Circle()
                            .fill(instagramGradient)
                            .frame(width: 36, height: 36)
                        
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
                // Custom Loading Animation
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
