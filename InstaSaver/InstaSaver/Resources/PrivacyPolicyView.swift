// PrivacyPolicyView.swift
import SwiftUI

struct PrivacyPolicyView: View {
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
                        title: "Information Collection",
                        icon: "doc.text.fill",
                        content: """
                        The Application collects information when you download and use it. This information may include:
                        
                        • Your device's Internet Protocol address (IP address)
                        • The pages of the Application that you visit
                        • The time and date of your visit
                        • The time spent on the Application
                        • The operating system you use
                        
                        The Application does not gather precise information about your location.
                        """
                    )
                    
                    contentSection(
                        title: "Third Party Access",
                        icon: "link.circle.fill",
                        content: """
                        Only aggregated, anonymized data is periodically transmitted to external services to help us improve the Application. We may share your information with third parties in the ways described in this privacy statement.
                        
                        The Application uses third-party services that have their own Privacy Policy:
                        
                        • AdMob - Google's advertising platform
                        • RevenueCat - Subscription management service
                        """
                    )
                    
                    contentSection(
                        title: "Data Protection",
                        icon: "lock.shield.fill",
                        content: """
                        We value your trust in providing us your personal information. We strive to use commercially acceptable means of protecting it.
                        
                        Remember that no method of transmission over the internet or electronic storage is 100% secure and reliable.
                        """
                    )
                    
                    contentSection(
                        title: "Children's Privacy",
                        icon: "person.2.fill",
                        content: """
                        The Application does not address anyone under the age of 13. We do not knowingly collect personal identifiable information from children under 13.
                        """
                    )
                    
                    contentSection(
                        title: "Your Rights",
                        icon: "checkmark.shield.fill",
                        content: """
                        You can stop all collection of information by the Application by uninstalling it from your device.
                        
                        You may also request to delete your data by contacting us at:
                        ucnllc@gmail.com
                        """
                    )
                    
                    contentSection(
                        title: "Changes to Policy",
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        content: """
                        This Privacy Policy may be updated from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.
                        
                        It is advised to review this Privacy Policy periodically for any changes.
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
            Text("Privacy Policy")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            Text("Last updated: March 15, 2024")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            
            Text("This privacy policy explains how we collect, use, and protect your personal information.")
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
        PrivacyPolicyView()
    }
}
