// SplashView.swift
// Glassmorphic Premium Splash Screen

import SwiftUI

struct SplashView: View {
    @Binding var isAppReady: Bool // Controls the transition to ContentView
    @State private var size: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    @State private var animateBackground = false
    @State private var startTime: Date?
    
    // Optimal splash duration: 1.5 seconds (smooth but not intrusive)
    private let minimumDuration: TimeInterval = 1.5
    
    var body: some View {
        ZStack {
            // MARK: - 1. Animated Glassmorphic Background
            animatedBackground
            
            // MARK: - 2. Glassmorphic Logo Card
            VStack(spacing: 20) {
                ZStack {
                    // Glass Background with enhanced styling
                    RoundedRectangle(cornerRadius: 35)
                        .fill(Color.white.opacity(0.25))
                        .background(
                            RoundedRectangle(cornerRadius: 35)
                                .fill(Color.white.opacity(0.1))
                                .blur(radius: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color("igPurple").opacity(0.15), radius: 20, x: 0, y: 10)
                        .shadow(color: Color("igPink").opacity(0.1), radius: 30, x: 0, y: 15)
                    
                    // Logo & Text Content
                    VStack(spacing: 15) {
                        Image("insaver2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                        
                        Text("InSave")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color("igPurple"),
                                        Color("igPink"),
                                        Color("igOrange")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .mask(
                                    Text("InSave")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                )
                            )
                    }
                    .padding(40)
                }
                .fixedSize()
            }
            .scaleEffect(size)
            .opacity(opacity)
        }
        .onAppear {
            self.startTime = Date()
            
            // MARK: - Premium Scale & Opacity Animation
            withAnimation(.easeOut(duration: 1.0)) {
                self.size = 1.0
                self.opacity = 1.0
            }
            
            // Animated background loop
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
            
            // Transition to main app after minimum duration
            transitionToMainApp()
        }
        .preferredColorScheme(.light) // Force light mode - app has no theme selection
    }
    
    // MARK: - Animated Background (matching HomeView.swift)
    private var animatedBackground: some View {
        ZStack {
            // Base gradient with Instagram colors
            LinearGradient(
                colors: [
                    Color.white,
                    Color("igPurple").opacity(0.15),
                    Color("igPink").opacity(0.15),
                    Color.white
                ],
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            
            // Floating Orbs for depth
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("igPurple").opacity(0.2),
                                Color("igPurple").opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(
                        x: animateBackground ? -50 : -100,
                        y: animateBackground ? -50 : -100
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("igOrange").opacity(0.2),
                                Color("igPink").opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(
                        x: geometry.size.width - (animateBackground ? 150 : 250),
                        y: geometry.size.height - (animateBackground ? 150 : 250)
                    )
            }
        }
    }
    
    // MARK: - Transition Logic (1.5 seconds optimal duration)
    private func transitionToMainApp() {
        guard let startTime = startTime else { return }
        
        // Calculate remaining time to satisfy minimum duration
        let elapsed = Date().timeIntervalSince(startTime)
        let delay = max(0, minimumDuration - elapsed)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation {
                self.isAppReady = true
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview - App Ready State
            SplashView(isAppReady: .constant(false))
                .previewDisplayName("Splash Screen")
            
            // Preview - Already Ready (should transition)
            SplashView(isAppReady: .constant(true))
                .previewDisplayName("Ready to Transition")
        }
    }
}
