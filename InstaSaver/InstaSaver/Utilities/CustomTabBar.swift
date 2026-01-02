// CustomTabBar.swift
// Glassmorphic Tab Bar - HomeView uyumlu tasarım

import SwiftUI

struct CustomTabBar: View {
    @Binding var currentTab: Tab
    
    private let instagramGradient = LinearGradient(
        colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                GlassTabButton(
                    tab: tab,
                    isSelected: currentTab == tab,
                    gradient: instagramGradient,
                    onTap: {
                        currentTab = tab
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(glassmorphicBackground)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
    
    // MARK: - Glassmorphic Background
    private var glassmorphicBackground: some View {
        ZStack {
            // Frosted glass base
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.92), Color.white.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle gradient tint
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
            
            // Border
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.2), Color("igPink").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: -4)
        .shadow(color: Color("igPink").opacity(0.08), radius: 20, x: 0, y: -6)
    }
}

// MARK: - Glass Tab Button
struct GlassTabButton: View {
    let tab: Tab
    let isSelected: Bool
    let gradient: LinearGradient
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Icon container
                    if isSelected {
                        // Selected state - gradient circle
                        Circle()
                            .fill(gradient)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1), Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        // Unselected state - subtle glass
                        Circle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                    }
                    
                    // Icon
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : Color.gray.opacity(0.7))
                }
                
                // Label
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Color("igPink") : Color.gray.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(currentTab: .constant(.home))
    }
    .background(Color.gray.opacity(0.1))
}
