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
            Color.black.opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
            
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
        .ignoresSafeArea(.all)
        .allowsHitTesting(true)
    }
}

#Preview {
        AdLoadingOverlayView()
    }
