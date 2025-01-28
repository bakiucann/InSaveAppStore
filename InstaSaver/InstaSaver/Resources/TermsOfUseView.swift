// TermsOfUseView.swift

//
//  TermsOfUseView.swift
//  Tiktak
//
//  Created by Baki Uçan on 15.09.2024.
//

import SwiftUI

struct TermsOfUseView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let accentColor = Color(red: 0.88, green: 0.27, blue: 0.67)  // InstaSaver pembe
    private let secondaryAccent = Color(red: 0.92, green: 0.47, blue: 0.33)  // InstaSaver turuncu
    private let backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.08)  // InstaSaver arka plan
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                // Content Sections
                Group {
                    contentSection(
                        title: "1. Terms Agreement",
                        icon: "checkmark.seal.fill",
                        content: """
                        Upon downloading or utilizing the Application, you automatically agree to these terms. Any unauthorized copying, modification of the Application, or our trademarks is strictly prohibited.
                        
                        You may not:
                        • Extract the source code
                        • Translate the app into other languages
                        • Create derivative versions
                        """
                    )
                    
                    contentSection(
                        title: "2. Application Usage",
                        icon: "iphone.gen3",
                        content: """
                        The Service Provider reserves the right to modify the Application or charge for services at any time. The Application stores and processes personal data to provide the Service.
                        
                        Please ensure your device remains secure and refrain from jailbreaking or rooting your phone as this may result in the Application not functioning correctly.
                        """
                    )
                    
                    contentSection(
                        title: "3. Third-Party Services",
                        icon: "link.circle.fill",
                        content: """
                        The Application utilizes third-party services that have their own Terms and Conditions:
                        
                        • AdMob - Google's mobile advertising platform
                        • RevenueCat - Subscription management service
                        """
                    )
                    
                    contentSection(
                        title: "4. Updates & Changes",
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        content: """
                        The Service Provider may update the Application periodically. It is important to accept updates to continue using the Application.
                        
                        The Service Provider may also terminate the Application's use at any time without prior notice.
                        """
                    )
                    
                    contentSection(
                        title: "5. Contact Us",
                        icon: "envelope.fill",
                        content: """
                        If you have any questions or suggestions about these Terms and Conditions, please contact us at:
                        
                        ucnllc@gmail.com
                        """
                    )
                }
            }
            .padding()
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentColor)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terms of Use")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            Text("Last updated: March 15, 2024")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Please read these terms carefully before using the application.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 4)
        }
        .padding(.bottom, 8)
    }
    
    private func contentSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(5)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }
}

#Preview {
    NavigationView {
        TermsOfUseView()
    }
}

