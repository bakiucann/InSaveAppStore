//
//  AdLoadingOverlayView.swift
//  InstaSaver
//
//  Created on 2025-01-27.
//  Critical view to prevent accidental clicks while ad is loading
//

import SwiftUI

struct AdLoadingOverlayView: View {
    var body: some View {
        ZStack {
            // Semi-transparent black background covering entire screen
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            // Content centered on screen
            VStack(spacing: 20) {
                // Circular ProgressView with white tint and scale effect
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                // Loading text below spinner
                Text(NSLocalizedString("Ad Loading...", comment: "Loading ad text"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        // Ensure it blocks all touch interactions
        .allowsHitTesting(true)
    }
}

// MARK: - Preview
struct AdLoadingOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        AdLoadingOverlayView()
    }
}

