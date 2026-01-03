// PrivacyPolicyView.swift

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Animated Background
            GlassmorphicLegalBackground()
            
            VStack(spacing: 0) {
                // Header
                legalHeader(title: NSLocalizedString("Privacy Policy", comment: ""))
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Last Updated
                        Text("Last updated: March 15, 2024")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                        
                        Text("This privacy policy explains how we collect, use, and protect your personal information.")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)
                
                // Content Sections
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("Information Collection", comment: ""),
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
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("Third Party Access", comment: ""),
                        icon: "link.circle.fill",
                        content: """
                            Only aggregated, anonymized data is periodically transmitted to external services to help us improve the Application.
                        
                        The Application uses third-party services that have their own Privacy Policy:
                        
                        • AdMob - Google's advertising platform
                        • RevenueCat - Subscription management service
                        """
                    )
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("Data Protection", comment: ""),
                        icon: "lock.shield.fill",
                        content: """
                        We value your trust in providing us your personal information. We strive to use commercially acceptable means of protecting it.
                        
                        Remember that no method of transmission over the internet or electronic storage is 100% secure and reliable.
                        """
                    )
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("Children's Privacy", comment: ""),
                        icon: "person.2.fill",
                        content: """
                        The Application does not address anyone under the age of 13. We do not knowingly collect personal identifiable information from children under 13.
                        """
                    )
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("Your Rights", comment: ""),
                        icon: "checkmark.shield.fill",
                        content: """
                        You can stop all collection of information by the Application by uninstalling it from your device.
                        
                        You may also request to delete your data by contacting us at:
                        ucnllc@gmail.com
                        """
                    )
                    
                        GlassmorphicLegalSection(
                            title: NSLocalizedString("Changes to Policy", comment: ""),
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        content: """
                        This Privacy Policy may be updated from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.
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

// MARK: - Glassmorphic Legal Background
struct GlassmorphicLegalBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color("igPurple").opacity(0.02), Color("igPink").opacity(0.03), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                Circle()
                    .fill(RadialGradient(colors: [Color("igPurple").opacity(0.08), Color.clear], center: .center, startRadius: 20, endRadius: 120))
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: 150)
                    .blur(radius: 40)
                
                Circle()
                    .fill(RadialGradient(colors: [Color("igOrange").opacity(0.06), Color.clear], center: .center, startRadius: 20, endRadius: 100))
                    .frame(width: 180, height: 180)
                    .offset(x: geometry.size.width - 80, y: geometry.size.height - 200)
                    .blur(radius: 50)
    }
        }
    }
}

// MARK: - Glassmorphic Legal Section
struct GlassmorphicLegalSection: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color("igPink").opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black.opacity(0.85))
            }
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.65))
                .lineSpacing(5)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color("igPurple").opacity(0.02), Color("igPink").opacity(0.01)], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            }
        )
        .shadow(color: Color("igPurple").opacity(0.06), radius: 10, x: 0, y: 5)
    }
}

#Preview {
        PrivacyPolicyView()
}
