// BrutalismCustomAlert.swift

import SwiftUI

struct ModernCustomAlert: View {
    let title: String
    let message: String
    let buttonTitle: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Arka plan: yarı saydam siyah maske
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 24) {
                
                // Başlık (Daha büyük, koyu renk)
                Text(title)
                    .font(.system(size: 20, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                
                // Mesaj (orta boy, gri ton, ortalı)
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                // Buton
                Button(action: {
                    onDismiss()
                }) {
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                    // BURADA projenin stiline göre:
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.4, green: 0.2, blue: 0.9),
                                    Color(red: 0.6, green: 0.3, blue: 0.95)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.top, 8)
                
            }
            .padding(24)
            .frame(maxWidth: 320)
            // Arka plan
            .background(Color.white)
            .cornerRadius(20)
            // İnce çerçeve veya gradient çerçeve eklemek isterseniz:
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            // Hafif gölge
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 4)
        }
    }
}
