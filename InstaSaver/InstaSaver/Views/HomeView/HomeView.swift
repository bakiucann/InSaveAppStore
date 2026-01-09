// HomeView.swift
// Glassmorphic UI Design - Compact Version

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
    @State private var animateBackground = false
    
    @EnvironmentObject var interstitial: InterstitialAd
    
    @Environment(\.screenSize) var screenSize
    
    var body: some View {
        ZStack {
            // MARK: - Animated Gradient Background
            animatedBackground
            
            // MARK: - Main Content
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                        // Content
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Compact spacer for header
                                Color.clear.frame(height: 70)
                                
                                // Main Search Card
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
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                
                                Spacer(minLength: 80)
                            }
                        .frame(minHeight: geometry.size.height)
                    }
                    
                        // Loading Overlay
                        if videoViewModel.isLoading {
                            LoadingOverlayView()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .onAppear {
                videoViewModel.isLoading = false
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateBackground = true
                    }
            }
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
                .fullScreenCover(isPresented: $showFeedbackView) {
                    NavigationView {
                FeedbackView()
            }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
                .fullScreenCover(isPresented: $showProfileView) {
                    NavigationView {
                        ProfileView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            
            // MARK: - Compact Glassmorphic Header Overlay
            VStack {
                GlassmorphicHeaderView(
                    showProfileView: $showProfileView,
                    showFeedbackView: $showFeedbackView,
                    showPaywallView: $showPaywallView
                )
                Spacer()
        }
            .zIndex(100)
            
            // MARK: - Alerts
            if showCustomAlert {
                ModernCustomAlert(
                    title: NSLocalizedString("Input Required", comment: ""),
                    message: NSLocalizedString("Please enter a URL.", comment: ""),
                    buttonTitle: NSLocalizedString("OK", comment: ""),
                    onDismiss: { showCustomAlert = false }
                )
                .zIndex(200)
            }
            
            if showErrorAlert {
                let displayedError = errorAlertMessage.components(separatedBy: "#").first ?? errorAlertMessage
                ModernCustomAlert(
                    title: NSLocalizedString("Error", comment: ""),
                    message: displayedError,
                    buttonTitle: NSLocalizedString("OK", comment: ""),
                    onDismiss: { showErrorAlert = false }
                )
                .zIndex(200)
            }
        }
        .onChange(of: videoViewModel.video) { newValue in
            guard let _ = newValue else { return }
            
                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                interstitial.showAd(from: rootViewController, completion: {
                    print("✅ Ad shown after successful video search, now opening PreviewView")
                    DispatchQueue.main.async {
                        showPreview = true
                    }
                }, skipCooldown: true)
            } else {
                showPreview = true
            }
        }
        .onChange(of: videoViewModel.errorMessage) { newValue in
            if let error = newValue {
                errorAlertMessage = error
                showErrorAlert = true
            }
        }
    }
    
    // MARK: - Animated Background (Subtle)
    private var animatedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.white,
                    Color("igPurple").opacity(0.02),
                    Color("igPink").opacity(0.03),
                    Color.white
                ],
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            
            // Subtle floating orbs
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("igPurple").opacity(0.1),
                                Color("igPurple").opacity(0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(
                        x: animateBackground ? -40 : -80,
                        y: animateBackground ? 40 : 80
                    )
                    .blur(radius: 50)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("igOrange").opacity(0.08),
                                Color("igPink").opacity(0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .offset(
                        x: geometry.size.width - (animateBackground ? 80 : 120),
                        y: geometry.size.height - (animateBackground ? 160 : 200)
                    )
                    .blur(radius: 60)
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
        HomeView(selectedTab: .constant(.home))
        .environmentObject(BottomSheetManager())
        .previewDevice("iPhone 15 Pro")
    }
}
