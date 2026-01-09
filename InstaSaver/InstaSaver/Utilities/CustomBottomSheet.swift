// CustomBottomSheet.swift
// High-Performance Glassmorphic Action Menu

import SwiftUI

struct CustomBottomSheet: View {
    @Binding var isShowing: Bool
    var actions: [BottomSheetAction]
    var onCancel: () -> Void
    
    var body: some View {
        ZStack {
            if isShowing {
                // Backdrop with tap to dismiss
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            onCancel()
                        }
                    }
                
                // Centered glassmorphic menu
                VStack(spacing: 0) {
                    ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                        GlassmorphicMenuActionButton(
                            label: action.label,
                            background: action.background,
                            textColor: action.textColor,
                            isFirst: index == 0,
                            isLast: index == actions.count - 1
                        ) {
                            action.action()
                            withAnimation(.easeOut(duration: 0.2)) {
                                isShowing = false
                            }
                        }
                        
                        if index < actions.count - 1 {
                            Divider()
                                .background(Color.gray.opacity(0.15))
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.98), Color.white.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.8), Color("igPink").opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: Color("igPurple").opacity(0.15), radius: 25, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 40)
                .scaleEffect(isShowing ? 1 : 0.9)
                .opacity(isShowing ? 1 : 0)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isShowing)
    }
}

struct BottomSheetAction: Identifiable {
    var id = UUID()
    var label: String
    var background: Color
    var textColor: Color
    var action: () -> Void
}

// MARK: - Glassmorphic Menu Action Button (Optimized)
struct GlassmorphicMenuActionButton: View {
    var label: String
    var background: Color
    var textColor: Color
    var isFirst: Bool
    var isLast: Bool
    var action: () -> Void
    
    @State private var isPressed = false
    
    private var buttonColor: Color {
        if background == .red {
            return .red
        } else if background == Color("igPink") {
            return Color("igPink")
        }
        return .black
    }
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                // Icon based on action type
                Image(systemName: iconForAction())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(buttonColor)
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(buttonColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isPressed ? Color.gray.opacity(0.05) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForAction() -> String {
        let lowercaseLabel = label.lowercased()
        
        if lowercaseLabel.contains("delete") || lowercaseLabel.contains("sil") {
            return "trash.fill"
        } else if lowercaseLabel.contains("rename") || lowercaseLabel.contains("yeniden adlandır") {
            return "pencil"
        } else if lowercaseLabel.contains("instagram") {
            return "arrow.up.forward.app.fill"
        } else if lowercaseLabel.contains("share") || lowercaseLabel.contains("paylaş") {
            return "square.and.arrow.up"
        }
        return "circle.fill"
    }
}

// MARK: - Legacy Components (Backwards Compatibility)
struct ButtonLarge: View {
    var label: String
    var background: Color = .blue
    var textColor: Color = .white
    var action: () -> Void
    
    var body: some View {
        GlassmorphicMenuActionButton(
            label: label,
            background: background,
            textColor: textColor,
            isFirst: false,
            isLast: false,
            action: action
        )
    }
}

struct GlassmorphicBottomSheetButton: View {
    var label: String
    var background: Color
    var textColor: Color
    var action: () -> Void
    
    var body: some View {
        GlassmorphicMenuActionButton(
            label: label,
            background: background,
            textColor: textColor,
            isFirst: false,
            isLast: false,
            action: action
        )
    }
}

struct GlassmorphicCancelButton: View {
    var action: () -> Void
    
    var body: some View {
        GlassmorphicMenuActionButton(
            label: NSLocalizedString("Cancel", comment: ""),
            background: .gray,
            textColor: .gray,
            isFirst: false,
            isLast: true,
            action: action
        )
    }
}

