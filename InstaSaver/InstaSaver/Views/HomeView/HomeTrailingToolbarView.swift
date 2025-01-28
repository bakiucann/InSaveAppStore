//
//  HomeTrailingToolbarView.swift
//  InstaSaver
//
//  Created by Baki Uçan on 6.01.2025.
//

import SwiftUI

struct HomeTrailingToolbarView: View {
    @Binding var showProfileView: Bool
    @Binding var showFeedbackView: Bool
    @Binding var showPaywallView: Bool
    
    @State private var hoveredButton: Int? = nil
    @State private var sparkleRotation: Double = 0.0
    
    private let modernGradient: LinearGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Button
            ToolbarButton(
                systemName: "person.crop.circle.fill",
                gradient: modernGradient,
                isHovered: hoveredButton == 0,
                action: {
                    showProfileView = true
                },
                onHover: { isHovered in
                    withAnimation(.spring()) {
                        hoveredButton = isHovered ? 0 : nil
                    }
                }
            )
            
            // History Button
            ToolbarButton(
                systemName: "clock.arrow.circlepath",
                gradient: modernGradient,
                isHovered: hoveredButton == 1,
                action: {
                    showFeedbackView = true
                },
                onHover: { isHovered in
                    withAnimation(.spring()) {
                        hoveredButton = isHovered ? 1 : nil
                    }
                }
            )
            
            // Premium Button with special effect
            Button(action: { showPaywallView = true }) {
                ZStack {
                    // Premium badge background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("igPurple"),
                                    Color("igPink"),
                                    Color("igOrange")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Content
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(NSLocalizedString("PRO", comment: ""))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(
                    color: Color("igPink").opacity(0.3),
                    radius: hoveredButton == 2 ? 8 : 4,
                    x: 0,
                    y: hoveredButton == 2 ? 4 : 2
                )
                .scaleEffect(hoveredButton == 2 ? 1.05 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovered in
                withAnimation(.spring()) {
                    hoveredButton = isHovered ? 2 : nil
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

struct ToolbarButton: View {
    let systemName: String
    let gradient: LinearGradient
    let isHovered: Bool
    let action: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isHovered ? gradient : LinearGradient(
                        colors: [.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(
                                isHovered ? .white.opacity(0.3) : .gray.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: systemName)
                    .font(.system(size: 18))
                    .foregroundColor(isHovered ? .white : Color("igPink"))
            }
            .shadow(color: Color("igPink").opacity(0.2), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
            .scaleEffect(isHovered ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            onHover(isHovered)
        }
    }
}
