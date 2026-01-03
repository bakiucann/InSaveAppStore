// TermsOfUseView.swift

import SwiftUI

struct TermsOfUseView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Animated Background
            GlassmorphicLegalBackground()
            
            VStack(spacing: 0) {
                // Header
                legalHeader(title: NSLocalizedString("Terms of Use", comment: ""))
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Last Updated
                        Text("Last updated: March 15, 2024")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                        
                        Text("Please read these terms carefully before using the application.")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)
                
                // Content Sections
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("1. Terms Agreement", comment: ""),
                        icon: "checkmark.seal.fill",
                        content: """
                        Upon downloading or utilizing the Application, you automatically agree to these terms. Any unauthorized copying, modification of the Application, or our trademarks is strictly prohibited.
                        
                        You may not:
                        • Extract the source code
                        • Translate the app into other languages
                        • Create derivative versions
                        """
                    )
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("2. Application Usage", comment: ""),
                        icon: "iphone.gen3",
                        content: """
                        The Service Provider reserves the right to modify the Application or charge for services at any time. The Application stores and processes personal data to provide the Service.
                        
                        Please ensure your device remains secure and refrain from jailbreaking or rooting your phone as this may result in the Application not functioning correctly.
                        """
                    )
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("3. Third-Party Services", comment: ""),
                        icon: "link.circle.fill",
                        content: """
                        The Application utilizes third-party services that have their own Terms and Conditions:
                        
                        • AdMob - Google's mobile advertising platform
                        • RevenueCat - Subscription management service
                        """
                    )
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("4. Updates & Changes", comment: ""),
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        content: """
                        The Service Provider may update the Application periodically. It is important to accept updates to continue using the Application.
                        
                        The Service Provider may also terminate the Application's use at any time without prior notice.
                        """
                    )
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("5. Contact Us", comment: ""),
                        icon: "envelope.fill",
                        content: """
                        If you have any questions or suggestions about these Terms and Conditions, please contact us at:
                        
                        ucnllc@gmail.com
                        """
                    )
                }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func legalHeader(title: String) -> some View {
        HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            
            Spacer()
            
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(LinearGradient(colors: [Color.white.opacity(0.98), Color.white.opacity(0.9)], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
        TermsOfUseView()
    }
