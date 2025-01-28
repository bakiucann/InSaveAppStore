// CustomAlertView.swift

import SwiftUI

struct CustomAlertView: View {
    @Binding var isPresented: Bool
    @Binding var text: String
    
    var title: String
    var message: String
    var placeholder: String
    var onCancel: () -> Void
    var onCreate: () -> Void
    
    // Gradient tanımı
    private let modernGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Group {
            if isPresented {
                ZStack {
                    // Backdrop
                    Color.black.opacity(0.1)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                onCancel()
                                isPresented = false
                            }
                        }
                    
                    // Alert Content
                    VStack(spacing: 20) {
                        // Title
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black.opacity(0.9))
                        
                        // Message
                        if !message.isEmpty {
                            Text(message)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        
                        // TextField
                        TextField(placeholder, text: $text)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        modernGradient,
                                        lineWidth: 1
                                    )
                            )
                            .padding(.horizontal)
                        
                        // Buttons
                        HStack(spacing: 12) {
                            // Cancel Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    onCancel()
                                    isPresented = false
                                }
                            }) {
                                Text(NSLocalizedString("Cancel", comment: ""))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            
                            // Create Button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    onCreate()
                                    isPresented = false
                                }
                            }) {
                                Text(NSLocalizedString("Create", comment: ""))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(modernGradient)
                                    .cornerRadius(12)
                                    .shadow(
                                        color: Color("igPink").opacity(0.3),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .transition(.scale.combined(with: .opacity))
                }
                .zIndex(1) // Performans için zIndex eklendi
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}
