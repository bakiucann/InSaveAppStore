// CollectionsAlertOverlay.swift

import SwiftUI

struct CollectionsAlertOverlay: View {
    @ObservedObject var viewModel: CollectionsViewModel
    
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
        if viewModel.showCreateCollectionAlert {
            GeometryReader { geometry in
                ZStack {
                    // Background Overlay - Tam ekran (UIScreen boyutları)
                    let screenWidth = UIScreen.main.bounds.width
                    let screenHeight = UIScreen.main.bounds.height
                    
                    Color.black.opacity(0.35)
                        .frame(width: screenWidth, height: screenHeight)
                        .position(x: screenWidth / 2, y: screenHeight / 2)
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.showCreateCollectionAlert = false
                                viewModel.newCollectionName = ""
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
                                
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            // Title
                            Text(NSLocalizedString("Create a Collection", comment: ""))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black.opacity(0.9))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                        
                        // TextField Section - Compact
                        TextField(NSLocalizedString("Collection Name", comment: ""), text: $viewModel.newCollectionName)
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
                        
                        // Buttons Section - Compact
                        HStack(spacing: 10) {
                            // Cancel Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.showCreateCollectionAlert = false
                                    viewModel.newCollectionName = ""
                                }
                            }) {
                                Text(NSLocalizedString("Cancel", comment: ""))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                            }
                            
                            // Create Button
                            Button(action: {
                                guard !viewModel.newCollectionName.isEmpty else { return }
                                viewModel.addCollection(name: viewModel.newCollectionName)
                                viewModel.newCollectionName = ""
                                viewModel.showCreateCollectionAlert = false
                            }) {
                                Text(NSLocalizedString("Create", comment: ""))
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
                            .disabled(viewModel.newCollectionName.isEmpty)
                            .opacity(viewModel.newCollectionName.isEmpty ? 0.5 : 1.0)
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
                    .onTapGesture {}
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                }
            }
            .ignoresSafeArea(.all)
            .allowsHitTesting(true)
            .zIndex(999)
        }
    }
}

