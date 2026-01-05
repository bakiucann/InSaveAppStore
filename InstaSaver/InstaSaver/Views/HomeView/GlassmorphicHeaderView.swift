//
//  GlassmorphicHeaderView.swift
//  InstaSaver
//
//  Liquid Glass Header - Compact Version - iOS 14+ Compatible
//

import SwiftUI

struct GlassmorphicHeaderView: View {
    @Binding var showProfileView: Bool
    @Binding var showFeedbackView: Bool
    @Binding var showPaywallView: Bool
    
    @State private var pressedButton: Int? = nil
    @State private var splashScale: CGFloat = 0.0
    @State private var splashOpacity: Double = 0.0
    @State private var shimmerOffset: CGFloat = -200
    
    // Instagram gradient
    private let appGradient = LinearGradient(
        colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                leadingSection
                Spacer(minLength: 12)
                trailingSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(headerBackground)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            
            Spacer()
        }
    }
    
    // MARK: - Compact Header Background
    private var headerBackground: some View {
                ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.92), Color.white.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                            Color("igPurple").opacity(0.04),
                            Color("igPink").opacity(0.03),
                            Color("igOrange").opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.12), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
                .mask(Capsule())
            
                    Capsule()
                        .stroke(
                            LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.2), Color("igPink").opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                    lineWidth: 1
                        )
                }
        .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 6)
        .shadow(color: Color("igPink").opacity(0.08), radius: 20, x: 0, y: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
    
    // MARK: - Compact Leading Section
    private var leadingSection: some View {
        HStack(spacing: 10) {
            ZStack {
                // Subtle glow behind logo
                Image("insaver26")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .blur(radius: 10)
                    .opacity(0.3)
                
                // Main logo without frame
                Image("insaver26")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
            }
            
            Text("InSave")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
        }
    }
    
    // MARK: - Compact Trailing Section
    private var trailingSection: some View {
        HStack(spacing: 10) {
            compactButton(systemName: "person.crop.circle.fill", index: 0) {
                showProfileView = true
            }
            
            compactButton(systemName: "clock.arrow.circlepath", index: 1) {
                showFeedbackView = true
            }
            
            compactProButton
        }
    }
    
    // MARK: - Compact Icon Button
    private func compactButton(systemName: String, index: Int, action: @escaping () -> Void) -> some View {
        Button(action: {
            triggerRipple(for: index)
            action()
        }) {
            ZStack {
                if pressedButton == index {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color("igPink").opacity(0.4), Color("igPurple").opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(splashScale)
                        .opacity(splashOpacity)
                        .blur(radius: 6)
                }
                
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .medium))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
                    .scaleEffect(pressedButton == index ? 1.12 : 1.0)
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Compact PRO Button
    private var compactProButton: some View {
        Button(action: {
            triggerGemstone()
            showPaywallView = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(appGradient)
                    .frame(width: 64, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.12), Color.clear, Color.black.opacity(0.03)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(NSLocalizedString("PRO", comment: ""))
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .shadow(color: Color("igPurple").opacity(0.35), radius: 8, x: 0, y: 4)
            .shadow(color: Color("igOrange").opacity(0.2), radius: 6, x: 0, y: 3)
            .scaleEffect(splashScale > 0 && pressedButton == 99 ? 1.06 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Animation Helpers
    private func triggerRipple(for index: Int) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            pressedButton = index
            splashScale = 1.6
            splashOpacity = 0.6
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                splashScale = 0.0
                splashOpacity = 0.0
            }
            pressedButton = nil
        }
    }
    
    private func triggerGemstone() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            pressedButton = 99
            splashScale = 1.15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.15)) {
                splashScale = 0.0
            }
            pressedButton = nil
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.white, Color("igPurple").opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
            .ignoresSafeArea()
        
        VStack {
            GlassmorphicHeaderView(
                showProfileView: .constant(false),
                showFeedbackView: .constant(false),
                showPaywallView: .constant(false)
            )
            Spacer()
        }
    }
}
