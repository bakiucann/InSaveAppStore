// ShareView.swift
// Professional share view for InSave app

import SwiftUI

struct ShareView: View {
    @Binding var isPresented: Bool
    @State private var showNativeShare = false
    @State private var copiedToClipboard = false
    
    private let appLink = "https://apps.apple.com/us/app/insave/id6740251620"
    private let shareMessage = NSLocalizedString("Hey! Check out InSave - The best Instagram video downloader app. Save your favorite Instagram videos easily! 📱✨", comment: "")
    
    var body: some View {
        ZStack {
            // Background
            ProfileAnimatedBackground()
            
            VStack(spacing: 0) {
                // Header
                shareHeader
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // App Preview Card
                        appPreviewCard
                        
                        // Share Options
                        shareOptionsSection
                        
                        // Copy Link Section
                        copyLinkSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showNativeShare) {
            ShareSheet(activityItems: ["\(shareMessage)\n\n\(appLink)"])
        }
    }
    
    // MARK: - Header
    private var shareHeader: some View {
        HStack {
            Button(action: { isPresented = false }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(NSLocalizedString("Share App", comment: ""))
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
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.98), Color.white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - App Preview Card
    private var appPreviewCard: some View {
        VStack(spacing: 20) {
            // App Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("igPink").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image("insaver2")
                    .resizable()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color("igPink").opacity(0.4), radius: 20, x: 0, y: 10)
            }
            
            // App Info
            VStack(spacing: 8) {
                Text("InSave")
                    .font(.system(size: 26, weight: .bold))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
                
                Text(NSLocalizedString("Instagram Video Downloader", comment: ""))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
                
                // Rating
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color("igOrange"))
                    }
                }
                .padding(.top, 4)
            }
            
            // Features
            HStack(spacing: 16) {
                ShareFeatureBadge(icon: "bolt.fill", text: NSLocalizedString("Fast", comment: ""))
                ShareFeatureBadge(icon: "hand.thumbsup.fill", text: NSLocalizedString("Easy", comment: ""))
                ShareFeatureBadge(icon: "checkmark.shield.fill", text: NSLocalizedString("Safe", comment: ""))
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.98), Color.white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color("igPurple").opacity(0.03), Color("igPink").opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color("igPurple").opacity(0.12), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Share Options Section
    private var shareOptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("Share via", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            HStack(spacing: 16) {
                ShareOptionButton(
                    icon: "whatsapp",
                    name: "WhatsApp",
                    color: Color(red: 0.15, green: 0.68, blue: 0.38),
                    isSystemIcon: false
                ) {
                    shareViaWhatsApp()
                }
                
                ShareOptionButton(
                    icon: "message.fill",
                    name: NSLocalizedString("Messages", comment: ""),
                    color: Color.green,
                    isSystemIcon: true
                ) {
                    shareViaMessages()
                }
                
                ShareOptionButton(
                    icon: "square.and.arrow.up",
                    name: NSLocalizedString("More", comment: ""),
                    color: Color("igPink"),
                    isSystemIcon: true
                ) {
                    showNativeShare = true
                }
            }
        }
    }
    
    // MARK: - Copy Link Section
    private var copyLinkSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("App Link", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                // Link display
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("igPurple"))
                    
                    Text(appLink)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                )
                
                // Copy button
                Button(action: copyToClipboard) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: copiedToClipboard ? [Color.green, Color.green.opacity(0.8)] : [Color("igPurple"), Color("igPink")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: (copiedToClipboard ? Color.green : Color("igPink")).opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func shareViaWhatsApp() {
        let message = "\(shareMessage)\n\n\(appLink)"
        let urlString = "whatsapp://send?text=\(message)"
        
        if let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let whatsappURL = URL(string: encodedString) {
            if UIApplication.shared.canOpenURL(whatsappURL) {
                UIApplication.shared.open(whatsappURL)
            } else {
                if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id310633997") {
                    UIApplication.shared.open(appStoreURL)
                }
            }
        }
    }
    
    private func shareViaMessages() {
        let message = "\(shareMessage)\n\n\(appLink)"
        if let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let smsURL = URL(string: "sms:&body=\(encoded)") {
            if UIApplication.shared.canOpenURL(smsURL) {
                UIApplication.shared.open(smsURL)
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = "\(shareMessage)\n\n\(appLink)"
        
        withAnimation(.spring(response: 0.3)) {
            copiedToClipboard = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3)) {
                copiedToClipboard = false
            }
        }
    }
}

// MARK: - Share Feature Badge
struct ShareFeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color("igPink").opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
            }
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Share Option Button
struct ShareOptionButton: View {
    let icon: String
    let name: String
    let color: Color
    let isSystemIcon: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .fill(color)
                        .frame(width: 52, height: 52)
                        .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    if isSystemIcon {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 26, height: 26)
                    }
                }
                
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

