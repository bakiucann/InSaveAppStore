// HomeView.swift

import SwiftUI

struct HomeView: View {
    @StateObject private var videoViewModel = VideoViewModel()
    @Binding var selectedTab: Tab
    
    // State variables
    @State private var inputText = ""
    @State private var showPasteButton = true
    @State private var isUrlSearch = false
    @State private var isLoading = false
    @State private var showPreview = false
    @State private var showCustomAlert = false
    @State private var showProfileView = false
    @State private var showFeedbackView = false
    @State private var showPaywallView = false
    @State private var showErrorAlert = false
    @State private var errorAlertMessage: String = ""
    
    let interstitial = InterstitialAd()
    
    @Environment(\.screenSize) var screenSize
    
    var body: some View {
        ZStack {
            // Ana içerik: NavigationView
            NavigationView {
                GeometryReader { geometry in
                    ZStack {
                        Color.white
                            .edgesIgnoringSafeArea(.all)
                        
                        ScrollView {
                            VStack(spacing: 15) {
                                SearchSectionView(
                                    inputText: $inputText,
                                    showPasteButton: $showPasteButton,
                                    isUrlSearch: $isUrlSearch,
                                    isLoading: $isLoading,
                                    showPreview: $showPreview,
                                    showCustomAlert: $showCustomAlert,
                                    interstitial: interstitial,
                                    videoViewModel: videoViewModel
                                )
                                
                                Spacer()
                            }
                            .padding()
                            .padding(.top, 80) // Header için üst padding
                            .frame(minHeight: geometry.size.height)
                        }
                        
                        if videoViewModel.isLoading {
                            LoadingOverlayView()
                        }
                        
                        // Ad Loading Overlay - Reklam yüklenirken tüm ekranı kaplar
                        if interstitial.isLoadingAd {
                            AdLoadingOverlayView()
                                .zIndex(999)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                .onAppear {
                    videoViewModel.isLoading = false
                }
                // Native navigation bar'ı tamamen gizle (iOS 14+ uyumlu)
                .navigationBarHidden(true)
                .navigationBarTitleDisplayMode(.inline)
                .fullScreenCover(isPresented: $showPreview) {
                    NavigationView {
                        if let video = videoViewModel.video {
                            PreviewView(video: video)
                        }
                    }
                }
                .fullScreenCover(isPresented: $showPaywallView) {
                    NavigationView {
                        PaywallView()
                    }
                }
                .sheet(isPresented: $showFeedbackView) {
                    FeedbackView()
                }
                .fullScreenCover(isPresented: $showProfileView) {
                    NavigationView {
                        ProfileView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            
            // Glassmorphic Header - NavigationView dışında, üst seviye ZStack'te
            VStack {
                GlassmorphicHeaderView(
                    showProfileView: $showProfileView,
                    showFeedbackView: $showFeedbackView,
                    showPaywallView: $showPaywallView
                )
                
                Spacer()
            }
            .zIndex(100) // Header'ın NavigationView'ın üstünde olması için
            
            // Alert'ler - NavigationView dışında, üst seviye ZStack'te
            let displayedError = errorAlertMessage.components(separatedBy: "#").first ?? errorAlertMessage
            
            // Custom Alert for Input
            if showCustomAlert {
                ModernCustomAlert(
                    title: NSLocalizedString("Input Required", comment: ""),
                    message: NSLocalizedString("Please enter a URL.", comment: ""),
                    buttonTitle: NSLocalizedString("OK", comment: ""),
                    onDismiss: {
                        showCustomAlert = false
                    }
                )
                .zIndex(2)
            }
            
            // Custom Alert for Errors
            if showErrorAlert {
                ModernCustomAlert(
                    title: NSLocalizedString("Error", comment: ""),
                    message: displayedError,
                    buttonTitle: NSLocalizedString("OK", comment: ""),
                    onDismiss: {
                        showErrorAlert = false
                    }
                )
                .zIndex(2)
            }
        }
        .onChange(of: videoViewModel.video) { newValue in
            guard let _ = newValue else { return }
            showPreview = true
            
            // Başarılı arama sonrası reklam göster (POST-action)
            // Video başarıyla yüklendi, 0.8 saniye sonra reklam göster
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    interstitial.showAd(from: rootViewController) {
                        print("✅ Ad shown after successful video search")
                    }
                }
            }
        }
        .onChange(of: videoViewModel.errorMessage) { newValue in
            if let error = newValue {
                errorAlertMessage = error
                showErrorAlert = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            selectedTab: .constant(.home)
        )
        .environmentObject(BottomSheetManager())
        .previewDevice("iPhone 15 Pro")
    }
}
