// ProfileView.swift

import SwiftUI
import RevenueCat
import UserMessagingPlatform

struct ProfileView: View {
    @State private var isProUser: Bool = false
    @State private var showHelp = false
    @State private var showPaywall = false
    @State private var showShareSheet = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showPrivacyPolicySheet = false
    @State private var showTermsOfUseSheet = false
    @EnvironmentObject var bottomSheetManager: BottomSheetManager
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var privacyOptionsStatus: UMPPrivacyOptionsRequirementStatus = .unknown
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            Color(.white)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    planCard
                    if !subscriptionManager.isUserSubscribed {
                        downloadLimitSection
                    }
                    quickActionsSection
                    supportSection
                    appInfoSection
                }
                .padding(.horizontal)
                .padding(.top, 5)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onAppear { fetchSubscriptionStatus() }
        .onAppear { checkPrivacyOptionsStatus() }
        .sheet(isPresented: $showShareSheet) {
            CustomShareView(isPresented: $showShareSheet)
        }
        .sheet(isPresented: $showHelp) {
            FeedbackView()
        }
        .sheet(isPresented: $showPrivacyPolicySheet) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfUseSheet) {
            TermsOfUseView()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            NavigationView {
                PaywallView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(instagramGradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
                .shadow(color: Color("igPink").opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("My Account")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Plan Card
    private var planCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Plan")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Text(isProUser ? "PRO PLAN" : "FREE PLAN")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("igPink"))
                }
                Spacer()
                
                Button(action: { showPaywall.toggle() }) {
                    Text("Upgrade")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(instagramGradient)
                        )
                        .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            if !isProUser {
                HStack(spacing: 12) {
                    FeatureItem(
                        icon: "sparkles",
                        text: NSLocalizedString("No Ads", comment: "Feature description indicating no advertisements")
                    )
                    FeatureItem(
                        icon: "video.fill",
                        text: NSLocalizedString("HD Quality", comment: "Feature description indicating high-definition quality")
                    )
                    FeatureItem(
                        icon: "arrow.down.circle.fill",
                        text: NSLocalizedString("Unlimited", comment: "Feature description indicating unlimited usage")
                    )
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("igPurple").opacity(0.2),
                            Color("igPink").opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Download Limit Section
    private var downloadLimitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Download Limit")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                DownloadStatsCard(
                    icon: "arrow.down.circle.fill",
                    title: "\(CoreDataManager.shared.getTodayDownloadCount())",
                    subtitle: NSLocalizedString("Downloads Today", comment: "")
                )
                
                DownloadStatsCard(
                    icon: "number.circle.fill",
                    title: "\(CoreDataManager.shared.getRemainingDownloads())",
                    subtitle: NSLocalizedString("Remaining Today", comment: "")
                )
            }
            
            Button(action: { showPaywall.toggle() }) {
                HStack {
                    Text("Get unlimited downloads")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Color("igPurple"))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color("igPurple").opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: NSLocalizedString("Restore", comment: "Button title to restore purchases"),
                    action: restorePurchases
                )
                
                QuickActionButton(
                    icon: "square.and.arrow.up",
                    title: NSLocalizedString("Share App", comment: "Button title to share the app"),
                    action: { showShareSheet.toggle() }
                )
                
                QuickActionButton(
                    icon: "questionmark.circle",
                    title: NSLocalizedString("Help", comment: "Button title to show help"),
                    action: { showHelp.toggle() }
                )
            }
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
            
            VStack(spacing: 1) {
                MenuLink(
                    title: NSLocalizedString("Privacy Policy", comment: "Menu link title for Privacy Policy"),
                    icon: "hand.raised",
                    action: { showPrivacyPolicySheet.toggle() }
                )
                
                MenuLink(
                    title: NSLocalizedString("Terms of Use", comment: "Menu link title for Terms of Use"),
                    icon: "doc.text",
                    action: { showTermsOfUseSheet.toggle() }
                )

                if privacyOptionsStatus == .required {
                    MenuLink(
                        title: NSLocalizedString("Privacy Options", comment: "Menu link title for Privacy Options"),
                        icon: "gearshape",
                        action: { presentPrivacyOptions() }
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("igPurple").opacity(0.2),
                                Color("igPink").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            LogoView()
            
            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
    
    private func restorePurchases() {
        Purchases.shared.restorePurchases { customerInfo, error in
            if let error = error {
                print("Error restoring purchases: \(error.localizedDescription)")
            } else {
                print("Purchases restored successfully!")
            }
        }
    }
    
    private func fetchSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let error = error {
                print("Error fetching subscription status: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                isProUser = customerInfo.entitlements["pro"]?.isActive == true
            }
        }
    }

    private func checkPrivacyOptionsStatus() {
        self.privacyOptionsStatus = UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus
        print("Checked Privacy Options Status: \(self.privacyOptionsStatus.rawValue)")
    }

    private func presentPrivacyOptions() {
        // Create request parameters and set debug settings for testing
        let parameters = UMPRequestParameters()
        // #if DEBUG
        // let debugSettings = UMPDebugSettings()
        // // Force geography to EEA only for testing the options form presentation
        // // debugSettings.geography = .EEA // <--- COMMENTED OUT for release
        // parameters.debugSettings = debugSettings
        // #endif

        // Request the latest consent info before presenting the form, using debug parameters if applicable.
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { requestError in // Pass parameters here
            if let error = requestError {
                print("UMP Error requesting consent info update for options form: \(error)")
                // Optionally show an alert to the user
                // We might still try to present the form below,
                // as sometimes it might work even with a request error.
            }

            DispatchQueue.main.async { // Ensure UI operations are on the main thread
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else {
                    print("UMP Error: Could not find root view controller when presenting options form.")
                    return
                }

                UMPConsentForm.presentPrivacyOptionsForm(from: rootViewController) { formError in
                    if let error = formError {
                        print("UMP Error presenting privacy options form: \(error)")
                        // Optionally show an alert to the user if the form fails to present
                    } else {
                        print("UMP Privacy options form presented successfully.")
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct FeatureItem: View {
    let icon: String
    let text: String
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(instagramGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color("igPink").opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("igPurple").opacity(0.2),
                            Color("igPink").opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(instagramGradient)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("igPurple").opacity(0.2),
                                Color("igPink").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

struct MenuLink: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color("igPink").opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color("igPink"))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color("igPink"))
            }
            .padding()
            .background(Color.white)
        }
    }
}

struct BackButton: View {
    let action: () -> Void
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(instagramGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct LogoView: View {
    private let instagramGradient = LinearGradient(
        colors: [
            Color("igPurple"),
            Color("igPink"),
            Color("igOrange")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Text("InSave")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color("igPink"))
            .overlay(
                Text("InSave")
                    .font(.system(size: 14, weight: .bold))
                    .mask(
                        Rectangle()
                            .fill(instagramGradient)
                    )
            )
    }
}

// MARK: - Download Stats Card
struct DownloadStatsCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color("igPurple"), Color("igPink")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .shadow(color: Color("igPink").opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("igPurple"))
            
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("igPurple").opacity(0.2),
                            Color("igPink").opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct CustomShareView: View {
    @Binding var isPresented: Bool
    @State private var selectedPlatform: SharePlatform?
    @State private var showNativeShare = false
    
    private let platforms: [SharePlatform] = [
        .init(name: "WhatsApp", icon: "whatsapp", color: Color.green),
        .init(name: "Messages", icon: "message.fill", color: Color("igPurple")),
        .init(name: "Copy Link", icon: "link", color: Color.gray),
        .init(name: "More", icon: "square.and.arrow.up", color: Color("igPink"))
    ]
    
    private let appLink = "https://apps.apple.com/us/app/insave/id6740251620"
    private let shareMessage = "Hey! Check out InSave - The best Instagram video downloader app. Save your favorite Instagram videos easily! 📱✨"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                shareHeader
                
                // Preview Card
                sharePreviewCard
                
                // Platform Buttons
                platformButtons
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Share InSave")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .sheet(isPresented: $showNativeShare) {
                ShareSheet(activityItems: ["\(shareMessage)\n\nDownload now: \(appLink)", UIImage(named: "AppIcon") ?? UIImage()])
            }
        }
    }
    
    private var shareHeader: some View {
        VStack(spacing: 8) {
            Image("insaver2")
                .resizable()
                .frame(width: 80, height: 80)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 10)
            
            Text("Share InSave with friends")
                .font(.system(size: 20, weight: .bold))
            
            Text(NSLocalizedString("Help your friends discover the easiest way\nto save Instagram videos!", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var sharePreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(shareMessage)
                .font(.system(size: 15))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            HStack {
                Text(appLink)
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = "\(shareMessage)\n\nDownload now: \(appLink)"
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color("igPurple"))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var platformButtons: some View {
        VStack(spacing: 16) {
            ForEach(platforms) { platform in
                Button(action: { handleShare(platform) }) {
                    HStack {
                        if platform.name == "WhatsApp" {
                            Image("whatsapp")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .frame(width: 36, height: 36)
                                .background(platform.color)
                                .cornerRadius(18)
                        } else {
                            Image(systemName: platform.icon)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(platform.color)
                                .cornerRadius(18)
                        }
                        
                        Text(platform.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
            }
        }
    }
    
    private func handleShare(_ platform: SharePlatform) {
        switch platform.name {
        case "WhatsApp":
            let message = "\(shareMessage)\n\nDownload now: \(appLink)"
            let urlString = "whatsapp://send?phone=&text=\(message)"
            
            if let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let whatsappURL = URL(string: encodedString) {
                if UIApplication.shared.canOpenURL(whatsappURL) {
                    UIApplication.shared.open(whatsappURL)
                } else {
                    // WhatsApp yüklü değilse App Store'a yönlendir
                    if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id310633997") {
                        UIApplication.shared.open(appStoreURL)
                    }
                }
            }
        case "Messages":
            if let smsURL = URL(string: "sms:&body=\(shareMessage)\n\nDownload now: \(appLink)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                if UIApplication.shared.canOpenURL(smsURL) {
                    UIApplication.shared.open(smsURL)
                }
            }
        case "Copy Link":
            UIPasteboard.general.string = "\(shareMessage)\n\nDownload now: \(appLink)"
        case "More":
            showNativeShare = true
        default:
            break
        }
    }
}

struct SharePlatform: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

