//
//  GlassmorphicHeaderView.swift
//  InstaSaver
//
//  Modern "Liquid Glass / iOS 18 Style" header with glassmorphic design
//

import SwiftUI

struct GlassmorphicHeaderView: View {
    @Binding var showProfileView: Bool
    @Binding var showFeedbackView: Bool
    @Binding var showPaywallView: Bool
    
    @State private var pressedButton: Int? = nil
    @State private var splashScale: CGFloat = 0.0
    @State private var splashOpacity: Double = 0.0
    
    // iOS 14+ compatible glass material background
    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 15.0, *) {
            Capsule()
                .fill(.ultraThinMaterial)
        } else {
            // iOS 14 fallback: white with gradient overlay for glass effect
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color.white.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private let appGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let textGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Main header container
            HStack(spacing: 0) {
                // Leading Section (Logo + Text)
                leadingSection
                
                // Flexible spacer with minimum width to ensure proper separation
                Spacer(minLength: 16)
                
                // Trailing Section (Buttons)
                trailingSection
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Glass material background (iOS 14+ compatible)
                    glassBackground
                    
                    // Tinted gradient overlay (5-10% opacity)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("igPurple").opacity(0.08),
                                    Color("igPink").opacity(0.06),
                                    Color("igOrange").opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Subtle border
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
            .shadow(color: Color("igPink").opacity(0.15), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Leading Section
    private var leadingSection: some View {
        HStack(spacing: 10) {
            // App Logo with Glow Effect
            ZStack {
                // Glow effect behind logo
                Image("insaver2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .blur(radius: 20)
                    .opacity(0.3)
                    .offset(x: 0, y: 0)
                
                // Actual logo
                Image("insaver2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .shadow(color: Color("igPink").opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            // App Name with Gradient
            Text("InSave")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.clear)
                .overlay(
                    textGradient
                        .mask(
                            Text("InSave")
                                .font(.system(size: 20, weight: .bold))
                        )
                )
        }
    }
    
    // MARK: - Trailing Section
    private var trailingSection: some View {
        HStack(spacing: 12) {
            // Profile Button
            glassIconButton(
                systemName: "person.crop.circle.fill",
                index: 0,
                action: { showProfileView = true }
            )
            
            // History Button
            glassIconButton(
                systemName: "clock.arrow.circlepath",
                index: 1,
                action: { showFeedbackView = true }
            )
            
            // Premium Gemstone Button
            gemstoneButton
        }
    }
    
    // MARK: - Glass Icon Button with Liquid Splash Effect
    private func glassIconButton(systemName: String, index: Int, action: @escaping () -> Void) -> some View {
        Button(action: {
            // Trigger liquid splash animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                pressedButton = index
                splashScale = 1.5
                splashOpacity = 0.6
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    splashScale = 0.0
                    splashOpacity = 0.0
                }
                pressedButton = nil
            }
            
            action()
        }) {
            ZStack {
                // Liquid splash effect (amorphous shape)
                if pressedButton == index {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("igPink").opacity(0.4),
                                    Color("igPurple").opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(splashScale)
                        .opacity(splashOpacity)
                        .blur(radius: 8)
                }
                
                // Icon
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color("igPink"))
                    .scaleEffect(pressedButton == index ? 1.1 : 1.0)
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Gemstone PRO Button
    private var gemstoneButton: some View {
        Button(action: {
            // Gemstone press animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                splashScale = 1.3
                splashOpacity = 0.5
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    splashScale = 0.0
                    splashOpacity = 0.0
                }
            }
            
            showPaywallView = true
        }) {
            ZStack {
                // Gemstone background with gradient
                RoundedRectangle(cornerRadius: 14)
                    .fill(appGradient)
                    .frame(width: 72, height: 32)
                    .overlay(
                        // 3D glass gloss reflection
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        // Subtle border
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Content
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(NSLocalizedString("PRO", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .shadow(color: Color("igPurple").opacity(0.4), radius: 12, x: 0, y: 6)
            .shadow(color: Color("igOrange").opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(splashScale > 0 ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
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

