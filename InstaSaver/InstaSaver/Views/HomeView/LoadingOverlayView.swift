//
//  LoadingOverlayView.swift
//  InstaSaver
//
//  Created by Baki Uçan on 6.01.2025.
//

import SwiftUI

struct LoadingOverlayView: View {
    @State private var isAnimating = false
    @State private var currentMessageIndex = 0
    @State private var timer: Timer?
    
    // Bilgilendirici mesajlar - belirli sürelerde değişecek
    private let loadingMessages: [String] = [
        NSLocalizedString("Fetching video info...", comment: ""),
        NSLocalizedString("Processing content...", comment: ""),
        NSLocalizedString("Analyzing quality...", comment: ""),
        NSLocalizedString("Almost there...", comment: ""),
        NSLocalizedString("Preparing download...", comment: "")
    ]
    
    private var currentMessage: String {
        loadingMessages[currentMessageIndex]
    }
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Custom Loading Animation
                ZStack {
                    Circle()
                        .stroke(lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.white.opacity(0.2))
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color("igPurple"),
                                    Color("igOrange")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 1)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                .onAppear {
                    isAnimating = true
                    startMessageRotation()
                }
                .onDisappear {
                    stopMessageRotation()
                }
                
                VStack(spacing: 8) {
                    // Ana mesaj - animasyonlu geçiş
                    Text(currentMessage)
                        .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .id(currentMessageIndex) // ID değiştiğinde animasyon tetiklenir
                
                    // Alt mesaj
                    Text(NSLocalizedString("Please wait", comment: ""))
                        .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                }
                .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color("igPurple").opacity(0.6),
                                        Color("igOrange").opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 25, x: 0, y: 10)
        }
    }
    
    private func startMessageRotation() {
        // İlk mesajı göster, sonra her 3 saniyede bir değiştir
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMessageIndex = (currentMessageIndex + 1) % loadingMessages.count
            }
        }
    }
    
    private func stopMessageRotation() {
        timer?.invalidate()
        timer = nil
    }
}
