//
//  GlassmorphicBackButton.swift
//  InstaSaver
//
//  Glassmorphic back button component matching toolbar design language
//

import SwiftUI

struct GlassmorphicBackButton: View {
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
                // Liquid splash effect (smaller, more subtle)
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
                
                // Icon - Glassmorphic style (no background, direct icon)
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color("igPink"))
                    .scaleEffect(isPressed ? 1.08 : 1.0)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        VStack {
            GlassmorphicBackButton {
                print("Back button tapped")
            }
            
            Spacer()
        }
        .padding()
    }
}

