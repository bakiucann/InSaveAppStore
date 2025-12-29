// ModernCustomAlert.swift

import SwiftUI

struct ModernCustomAlert: View {
    let title: String
    let message: String
    let buttonTitle: String
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arka plan: Hafif koyu overlay - TAM EKRAN (UIScreen boyutları)
                // Status bar hariç tüm ekranı kaplar (kullanıcı zamanı görebilsin)
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                
                Color.black.opacity(0.35)
                    .frame(width: screenWidth, height: screenHeight)
                    .position(x: screenWidth / 2, y: screenHeight / 2)
                    // Status bar'ı açık bırak, sadece alt kısmı kapla
                    .ignoresSafeArea(.container, edges: .bottom)
                    .allowsHitTesting(true)
                    .onTapGesture {
                        onDismiss()
                    }
                
                // Dialog içeriği - merkeze yerleştir
                VStack(spacing: 0) {
                // İkon ve Başlık Bölümü
                VStack(spacing: 12) {
                    // Hata ikonu - küçültüldü
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.4, blue: 0.4),
                                        Color(red: 0.9, green: 0.3, blue: 0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    // Başlık - küçültüldü
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Mesaj Bölümü - kompakt
                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Buton Bölümü - kompakt
                // OK butonu tıklanabilir olmalı (parent'ta allowsHitTesting(false) var, bu yüzden explicit olarak true yapıyoruz)
                Button(action: {
                    onDismiss()
                }) {
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("igPurple"),
                                    Color("igOrange")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: Color("igPurple").opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .frame(maxWidth: 300) // Küçültüldü (340 -> 300)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    // Daha belirgin shadow - arka plandan ayırmak için
                    .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            // Alert card'ın kendisi tıklanabilir değil (sadece OK butonu tıklanabilir)
            // Arka plan overlay'e tıklanınca dismiss olur
            // Boş tap gesture ile alert card'a tıklanınca hiçbir şey olmaz
            .onTapGesture {
                // Alert card'a tıklanınca hiçbir şey yapma (sadece OK butonu çalışır)
            }
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            }
        }
        // Status bar'ı açık bırak, sadece alt kısmı kapla
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

