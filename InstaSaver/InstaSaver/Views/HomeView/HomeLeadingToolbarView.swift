//
//  HomeLeadingToolbarView.swift
//  InstaSaver
//
//  Created by Baki Uçan on 6.01.2025.
//

import SwiftUI

struct HomeLeadingToolbarView: View {
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 2) {
            // App Icon
            Image("insaver2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            // App Name with Gradient
            Text("InSave")
                .font(.system(size: 20, weight: .bold))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color("igPurple"),
                            Color("igPink"),
                            Color("igOrange")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        Text("InSave")
                            .font(.system(size: 20, weight: .bold))
                    )
                )
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
//        )
    }
}
