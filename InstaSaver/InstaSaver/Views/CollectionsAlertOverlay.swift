// CollectionsAlertOverlay.swift
// Reusable Glassmorphic Alert Component

import SwiftUI

// MARK: - Generic Glassmorphic Alert
struct GlassmorphicTextInputAlert: View {
    @Binding var isPresented: Bool
    @Binding var inputText: String
    var title: String
    var placeholder: String
    var icon: String
    var onSave: () -> Void
    var showOverlay: Bool = true // Default: show gray overlay
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        if isPresented {
            ZStack {
                // Background Overlay (optional)
                if showOverlay {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPresented = false
                                inputText = ""
                            }
                        }
                } else {
                    // Transparent backdrop for tap to dismiss (no gray overlay)
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPresented = false
                                inputText = ""
                            }
                        }
                }
                
                // Compact Glassmorphic Alert Content
                VStack(spacing: 0) {
                    // Icon & Title Section
                    VStack(spacing: 10) {
                        // Gradient Icon Circle
                        ZStack {
                            Circle()
                                .fill(instagramGradient)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        // Title
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black.opacity(0.9))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // TextField Section
                    TextField(placeholder, text: $inputText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if #available(iOS 15.0, *) {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                } else {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.95),
                                                    Color.white.opacity(0.9)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color("igPurple").opacity(0.3),
                                                Color("igPink").opacity(0.3)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            }
                        )
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                    
                    // Buttons Section
                    HStack(spacing: 10) {
                        // Cancel Button
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPresented = false
                                inputText = ""
                            }
                        }) {
                            Text(NSLocalizedString("Cancel", comment: ""))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                        }
                        
                        // Save Button
                        Button(action: {
                            guard !inputText.isEmpty else { return }
                            onSave()
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }) {
                            Text(NSLocalizedString("Save", comment: ""))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    Capsule()
                                        .fill(instagramGradient)
                                )
                                .shadow(color: Color("igPink").opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .disabled(inputText.isEmpty)
                        .opacity(inputText.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: 280)
                .background(
                    ZStack {
                        if #available(iOS 15.0, *) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                        }
                        
                        RoundedRectangle(cornerRadius: 20)
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
                        
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
                .shadow(color: Color.black.opacity(0.25), radius: 25, x: 0, y: 12)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .transition(.scale.combined(with: .opacity))
                .scaleEffect(isPresented ? 1 : 0.9)
                .opacity(isPresented ? 1 : 0)
            }
            .ignoresSafeArea()
            .zIndex(999)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isPresented)
        }
    }
}

// MARK: - Collections Alert Overlay (Wrapper)
struct CollectionsAlertOverlay: View {
    @ObservedObject var viewModel: CollectionsViewModel
    
    var body: some View {
        GlassmorphicTextInputAlert(
            isPresented: $viewModel.showCreateCollectionAlert,
            inputText: $viewModel.newCollectionName,
            title: NSLocalizedString("Create a Collection", comment: ""),
            placeholder: NSLocalizedString("Collection Name", comment: ""),
            icon: "square.grid.2x2.fill"
        ) {
            viewModel.addCollection(name: viewModel.newCollectionName)
            viewModel.newCollectionName = ""
        }
    }
}

