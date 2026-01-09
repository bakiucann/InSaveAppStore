//
//  GlassmorphicDropdownMenu.swift
//  InstaSaver
//
//  High-performance glassmorphic dropdown menu component
//  Reusable across different views for consistent UI
//

import SwiftUI

// MARK: - Glassmorphic Dropdown Menu
struct GlassmorphicDropdownMenu: View {
    @Binding var isPresented: Bool
    var onRename: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparent backdrop for tap to dismiss
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                
                // Dropdown menu positioned at top-right
                VStack(alignment: .trailing, spacing: 0) {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 0) {
                            // Rename option
                            DropdownMenuItem(
                                icon: "pencil",
                                title: NSLocalizedString("Rename", comment: ""),
                                color: Color("igPink"),
                                action: onRename
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.15))
                                .padding(.horizontal, 12)
                            
                            // Delete option
                            DropdownMenuItem(
                                icon: "trash.fill",
                                title: NSLocalizedString("Delete Collection", comment: ""),
                                color: .red,
                                action: onDelete
                            )
                        }
                        .frame(width: 200)
                        .background(glassmorphicBackground)
                        .shadow(color: Color("igPurple").opacity(0.15), radius: 20, x: 0, y: 10)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 60) // Position below navbar
                    
                    Spacer()
                }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .zIndex(998) // Below alert (999) but above content
    }
    
    // MARK: - Glassmorphic Background
    private var glassmorphicBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.98), Color.white.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("igPurple").opacity(0.03),
                            Color("igPink").opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Dropdown Menu Item
struct DropdownMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(color == .red ? .red : .black.opacity(0.85))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isPressed ? Color.gray.opacity(0.05) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#if DEBUG
struct GlassmorphicDropdownMenu_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            GlassmorphicDropdownMenu(
                isPresented: .constant(true),
                onRename: { print("Rename tapped") },
                onDelete: { print("Delete tapped") }
            )
        }
    }
}
#endif
