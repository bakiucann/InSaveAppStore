//
//  AdLoadingOverlayView.swift
//  InstaSaver
//
//  Simple Ad Loading Overlay
//

import SwiftUI

struct AdLoadingOverlayView: View {
    var body: some View {
        ZStack {
            // Full screen background overlay
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            // Loading indicator
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(NSLocalizedString("Ad Loading...", comment: "Loading ad text"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
        AdLoadingOverlayView()
    }
