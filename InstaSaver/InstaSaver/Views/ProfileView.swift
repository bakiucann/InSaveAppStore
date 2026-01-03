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
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var privacyOptionsStatus: UMPPrivacyOptionsRequirementStatus = .unknown
    
    // Restore states
    @State private var isRestoring = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertTitle = ""
    @State private var restoreAlertMessage = ""
    
    // Dynamic version info
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ZStack {
            ProfileAnimatedBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    glassmorphicHeader
                    glassmorphicPlanCard
                    
                    if !subscriptionManager.isUserSubscribed {
                        glassmorphicDownloadLimitSection
                    }
                    
                    glassmorphicQuickActionsSection
                    glassmorphicSupportSection
                    glassmorphicAppInfoSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            fetchSubscriptionStatus()
            checkPrivacyOptionsStatus()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareView(isPresented: $showShareSheet)
        }
        .fullScreenCover(isPresented: $showHelp) {
            NavigationView {
                FeedbackView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
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
        .alert(isPresented: $showRestoreAlert) {
            Alert(
                title: Text(restoreAlertTitle),
                message: Text(restoreAlertMessage),
                dismissButton: .default(Text(NSLocalizedString("OK", comment: "")))
            )
        }
        .overlay(
            Group {
                if isRestoring {
                    restoreLoadingOverlay
                }
            }
        )
    }
    
    // MARK: - Restore Loading Overlay
    private var restoreLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("igPink")))
                    .scaleEffect(1.3)
                
                Text(NSLocalizedString("Restoring...", comment: ""))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
        }
    }
    
    // MARK: - Header
    private var glassmorphicHeader: some View {
        HStack(spacing: 14) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                }
            }
            
            Spacer()
            
            Text(NSLocalizedString("My Account", comment: ""))
                .font(.system(size: 20, weight: .bold))
                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color("igPink").opacity(0.3), Color.clear], center: .center, startRadius: 10, endRadius: 25))
                    .frame(width: 50, height: 50)
                
                Circle()
                    .fill(LinearGradient(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color("igPink").opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(glassmorphicCardBackground(cornerRadius: 20))
    }
    
    // MARK: - Plan Card
    private var glassmorphicPlanCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("Current Plan", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Text(isProUser ? "PRO" : "FREE")
                            .font(.system(size: 26, weight: .bold))
                            .gradientForeground(colors: isProUser ? [Color("igPurple"), Color("igPink")] : [Color.gray, Color.gray.opacity(0.7)])
                        
                        if isProUser {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .medium))
                                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
                }
                    }
                }
                
                Spacer()
                
                if !isProUser {
                Button(action: { showPaywall.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                            Text(NSLocalizedString("Upgrade", comment: ""))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color("igPurple"), Color("igPink")], startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: Color("igPink").opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                }
            }
            
            if !isProUser {
                HStack(spacing: 10) {
                    GlassmorphicFeatureItem(icon: "sparkles", text: NSLocalizedString("No Ads", comment: ""))
                    GlassmorphicFeatureItem(icon: "video.fill", text: NSLocalizedString("HD Quality", comment: ""))
                    GlassmorphicFeatureItem(icon: "infinity", text: NSLocalizedString("Unlimited", comment: ""))
                }
            }
        }
        .padding(18)
        .background(glassmorphicCardBackground(cornerRadius: 20))
        .shadow(color: Color("igPurple").opacity(0.1), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Download Limit Section
    private var glassmorphicDownloadLimitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("Daily Download Limit", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                GlassmorphicDownloadStatsCard(
                    icon: "arrow.down.circle.fill",
                    value: "\(CoreDataManager.shared.getTodayDownloadCount())",
                    label: NSLocalizedString("Today", comment: "")
                )
                
                GlassmorphicDownloadStatsCard(
                    icon: "hourglass.circle.fill",
                    value: "\(CoreDataManager.shared.getRemainingDownloads())",
                    label: NSLocalizedString("Left", comment: "")
                )
            }
            
            Button(action: { showPaywall.toggle() }) {
                HStack {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 18))
                        .gradientForeground(colors: [Color("igPurple"), Color("igPink")])
                    
                    Text(NSLocalizedString("Get unlimited downloads", comment: ""))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("igPink"))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color("igPurple").opacity(0.08)))
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var glassmorphicQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("Quick Actions", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                GlassmorphicQuickActionButton(icon: "arrow.clockwise", title: NSLocalizedString("Restore", comment: ""), action: restorePurchases)
                GlassmorphicQuickActionButton(icon: "square.and.arrow.up", title: NSLocalizedString("Share", comment: ""), action: { showShareSheet.toggle() })
                GlassmorphicQuickActionButton(icon: "questionmark.circle", title: NSLocalizedString("Help", comment: ""), action: { showHelp.toggle() })
            }
        }
    }
    
    // MARK: - Support Section
    private var glassmorphicSupportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("Support", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            VStack(spacing: 2) {
                GlassmorphicMenuLink(title: NSLocalizedString("Privacy Policy", comment: ""), icon: "hand.raised.fill", isFirst: true, isLast: privacyOptionsStatus != .required, action: { showPrivacyPolicySheet.toggle() })
                GlassmorphicMenuLink(title: NSLocalizedString("Terms of Use", comment: ""), icon: "doc.text.fill", isFirst: false, isLast: privacyOptionsStatus != .required, action: { showTermsOfUseSheet.toggle() })

                if privacyOptionsStatus == .required {
                    GlassmorphicMenuLink(title: NSLocalizedString("Privacy Options", comment: ""), icon: "gearshape.fill", isFirst: false, isLast: true, action: { presentPrivacyOptions() })
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.5), Color("igPink").opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: Color("igPurple").opacity(0.08), radius: 12, x: 0, y: 6)
        }
    }
    
    // MARK: - App Info Section
    private var glassmorphicAppInfoSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color("igPink").opacity(0.2), Color.clear], center: .center, startRadius: 15, endRadius: 40))
                    .frame(width: 80, height: 80)
                
                Image("insaver2")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color("igPink").opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            Text("InSave")
                .font(.system(size: 18, weight: .bold))
                .gradientForeground(colors: [Color("igPurple"), Color("igPink"), Color("igOrange")])
            
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Views
    private func glassmorphicCardBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(LinearGradient(colors: [Color("igPurple").opacity(0.03), Color("igPink").opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(LinearGradient(colors: [Color.white.opacity(0.6), Color("igPink").opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Helper Functions
    private func restorePurchases() {
        isRestoring = true
        
        Purchases.shared.restorePurchases { customerInfo, error in
            DispatchQueue.main.async {
                isRestoring = false
                
            if let error = error {
                print("Error restoring purchases: \(error.localizedDescription)")
                    restoreAlertTitle = NSLocalizedString("Restore Failed", comment: "")
                    restoreAlertMessage = NSLocalizedString("Failed to restore purchases. Please try again later.", comment: "")
                    showRestoreAlert = true
                } else if let customerInfo = customerInfo,
                          customerInfo.entitlements["pro"]?.isActive == true {
                    // Başarılı restore
                    restoreAlertTitle = NSLocalizedString("Success", comment: "")
                    restoreAlertMessage = NSLocalizedString("Your purchases have been successfully restored!", comment: "")
                    showRestoreAlert = true
                    
                    // Update subscription status
                    subscriptionManager.isUserSubscribed = true
                    isProUser = true
                    
                    // Notify subscription change
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionChanged"), object: nil)
            } else {
                    // No active subscription found
                    restoreAlertTitle = NSLocalizedString("No Purchases Found", comment: "")
                    restoreAlertMessage = NSLocalizedString("No previous purchases were found to restore.", comment: "")
                    showRestoreAlert = true
                }
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
    }

    private func presentPrivacyOptions() {
        let parameters = UMPRequestParameters()
        
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { requestError in
            if let error = requestError {
                print("UMP Error: \(error)")
            }

            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else { return }

                UMPConsentForm.presentPrivacyOptionsForm(from: rootViewController) { formError in
                    if let error = formError {
                        print("UMP Error presenting form: \(error)")
                    }
                }
            }
        }
    }
}
