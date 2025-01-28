// CustomBottomSheet.swift

import SwiftUI

struct CustomBottomSheet: View {
    @Binding var isShowing: Bool
    var actions: [BottomSheetAction] // Dinamik aksiyonlar için
    var onCancel: () -> Void // Cancel işlemi için
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isShowing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onCancel()
                    }
                
                VStack(spacing: 36) {
                    // Aksiyonlar için butonları dinamik olarak oluştur
                    ForEach(actions) { action in
                        ButtonLarge(label: action.label, background: action.background, textColor: action.textColor) {
                            action.action()
                            isShowing.toggle() // Alt sayfayı kapat
                        }
                        .frame(height: 30)
                    }
                    
                    // Cancel butonu
                    ButtonLarge( label: NSLocalizedString("Cancel", comment: ""), background: .gray, textColor: .white) {
                        onCancel() // Cancel işlemi
                    }
                    .frame(height: 30)
                }
                .padding(.horizontal, 42)
                .padding(.bottom, 42)
                .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.easeInOut, value: isShowing)
    }
}

struct BottomSheetAction: Identifiable {
    var id = UUID()
    var label: String
    var background: Color
    var textColor: Color
    var action: () -> Void
}

struct ButtonLarge: View {
    
    var label: String
    var background: Color = .blue     // Örnek varsayılan renk
    var textColor: Color = .white     // Varsayılan yazı rengi
    var action: () -> Void
    
    let cornerRadius: CGFloat = 10
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(label)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(textColor)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
            // Arka plan
                .background(background)
            // Köşe yuvarlama
                .cornerRadius(cornerRadius)
            // Hafif gölge (modern tasarım)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}

