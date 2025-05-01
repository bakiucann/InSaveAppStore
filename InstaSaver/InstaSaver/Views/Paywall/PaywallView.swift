// PaywallView.swift

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var offering: Offering?
    @State private var selectedPackage: Package?
    @State private var showLoading = false
    @State private var animateGradient = false
    @State private var isLoadingOfferings = true
    @StateObject private var specialOfferViewModel = SpecialOfferViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var configManager = ConfigManager.shared
    
    // Alert için state değişkenleri
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private let premiumGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.08),
            Color(red: 0.08, green: 0.08, blue: 0.12)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let accentColor = Color(red: 0.88, green: 0.27, blue: 0.67)
    private let secondaryAccent = Color(red: 0.92, green: 0.47, blue: 0.33)
    private let tertiaryAccent = Color(red: 0.45, green: 0.23, blue: 0.86)
    
    var body: some View {
        ZStack {
            // MARK: - Background
            premiumGradient
                .edgesIgnoringSafeArea(.all)
            
            // Animated overlay
            VStack {
                ZStack {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            tertiaryAccent.opacity(0.08),
                            accentColor.opacity(0.08),
                            Color.clear
                        ]),
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 400
                    )
                    
                    RadialGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.08),
                            secondaryAccent.opacity(0.08),
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 400
                    )
                }
                .frame(height: 400)
                .rotationEffect(.degrees(animateGradient ? 350 : 0))
                .animation(
                    Animation.easeInOut(duration: 20)
                        .repeatForever(autoreverses: true),
                    value: animateGradient
                )
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            
            // MARK: - Content
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        // Comment out the notification post to prevent showing Special Offer after closing Paywall
                        // DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        //     NotificationCenter.default.post(name: Notification.Name("ShowSpecialOffer"), object: nil)
                        // }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accentColor)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if isLoadingOfferings {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .accentColor(.white)
                        Text("Loading Premium Features...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            // MARK: - Hero Section
                            VStack(spacing: 10) {
                                ZStack {
                                    Image("insaver2")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                    
                                    // PRO badge
                                    Text("PRO")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.3))
                                        )
                                        .offset(x: 25, y: -25)
                                }
                                
                                VStack(spacing: 6) {
                                    Text(NSLocalizedString("Unlock All Features", comment: ""))
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(NSLocalizedString("Experience Instagram without limitations", comment: ""))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.top, 12)
                            
                            // MARK: - Features Section
                            VStack(spacing: 20) {
                                if Locale.current.languageCode != "en" || configManager.showDownloadButtons {
                                    PremiumFeatureRow(
                                        icon: "arrow.down.circle.fill",
                                        title: NSLocalizedString("Premium Downloads", comment: ""),
                                        subtitle: NSLocalizedString("Download stories, posts & reels in HD", comment: "")
                                    )
                                    
                                    PremiumFeatureRow(
                                        icon: "square.stack.fill",
                                        title: NSLocalizedString("Batch Downloads", comment: ""),
                                        subtitle: NSLocalizedString("Save time with multiple downloads at once", comment: "")
                                    )
                                }
                                
                                PremiumFeatureRow(
                                    icon: "infinity.circle.fill",
                                    title: NSLocalizedString("Unlimited Access", comment: ""),
                                    subtitle: NSLocalizedString("No restrictions, download as much as you want", comment: "")
                                )
                                
                                PremiumFeatureRow(
                                    icon: "xmark.circle.fill",
                                    title: NSLocalizedString("Ad-Free Experience", comment: ""),
                                    subtitle: NSLocalizedString("Enjoy a clean, distraction-free experience", comment: "")
                                )
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 15)
                            
                            // MARK: - Pricing Section
                            if let offering = offering {
                                VStack(spacing: 12) {
                                    packageSection(offering: offering)
                                }
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: 12) {
                                    // Placeholder for Annual Package
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 100)
                                        .overlay(
                                            ProgressView()
                                                .accentColor(.white)
                                        )
                                    
                                    // Placeholder for Monthly Package
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 80)
                                        .overlay(
                                            ProgressView()
                                                .accentColor(.white)
                                        )
                                }
                                .padding(.horizontal)
                                .redacted(reason: .placeholder)
                                .shimmering()
                            }
                            
                            // MARK: - CTA Section
                            VStack(spacing: 12) {
                                Button(action: {
                                    if let package = selectedPackage {
                                        purchasePackage(package: package)
                                    }
                                }) {
                                    Text(NSLocalizedString("Unlock Premium Access", comment: ""))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(
                                            LinearGradient(
                                                colors: [tertiaryAccent, accentColor, secondaryAccent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 26))
                                        .shadow(color: accentColor.opacity(0.3), radius: 15)
                                }
                                .disabled(selectedPackage == nil)
                                .padding(.horizontal)
                                
                                Button(action: {
                                    restorePurchases()
                                }) {
                                    Text(NSLocalizedString("Restore Purchases", comment: ""))
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(accentColor)
                                    Text(NSLocalizedString("Secured by Apple", comment: ""))
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.bottom, 4)
                            }
//                            .padding(.vertical, 1)
                            
                            // MARK: - Terms Section
                            HStack(spacing: 5) {
                                linkButton(NSLocalizedString("Terms", comment: ""), urlString: "https://kitgetapp.netlify.app/terms-of-use")
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                linkButton(NSLocalizedString("Privacy", comment: ""), urlString: "https://kitgetapp.netlify.app/privacy-policy")
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                linkButton("EULA", urlString: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 12)
                        }
                    }
                }
            }
            
            if showLoading {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                ProgressView()
                    .accentColor(.white)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            configManager.reloadConfig()
            fetchOfferings()
            animateGradient = true
        }
        // .sheet(isPresented: $specialOfferViewModel.isPresented) {
        //     SpecialOfferView(viewModel: specialOfferViewModel)
        // }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.75))
            }
            
            Spacer()
        }
    }
}

// MARK: - Package Section
extension PaywallView {
    @ViewBuilder
    func packageSection(offering: Offering) -> some View {
        VStack(spacing: 12) {
            if let annual = offering.annual {
                if let perMonth = annual.storeProduct.localizedPricePerMonth {
                    packageRow(
                        title: NSLocalizedString("Annual", comment: ""),
                        price: annual.storeProduct.localizedPriceString,
                        perMonth: perMonth,
                        highlight: NSLocalizedString("BEST OFFER", comment: ""),
                        package: annual,
                        isRecommended: true,
                        savings: NSLocalizedString("Save 33%", comment: "")
                    )
                }
            }
            
            if let monthly = offering.monthly {
                packageRow(
                    title: NSLocalizedString("Monthly", comment: ""),
                    price: monthly.storeProduct.localizedPriceString,
                    package: monthly
                )
            }
            
            if let weekly = offering.weekly {
                packageRow(
                    title: NSLocalizedString("Weekly", comment: ""),
                    price: weekly.storeProduct.localizedPriceString,
                    package: weekly
                )
            }
        }
    }
    
    func packageRow(
        title: String,
        price: String,
        perMonth: String? = nil,
        highlight: String? = nil,
        package: Package,
        isRecommended: Bool = false,
        savings: String? = nil
    ) -> some View {
        Button(action: {
            selectedPackage = package
        }) {
            VStack(spacing: 0) {
                if let highlight = highlight {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                        Text(highlight)
                            .font(.system(size: 10, weight: .heavy))
                            .kerning(0.3)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [tertiaryAccent, accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: accentColor.opacity(0.2), radius: 8, x: 0, y: 2)
                    .offset(y: -10)
                }
                
                HStack(spacing: 0) {
                    // Sol taraf - Radio button ve başlık
                    HStack(spacing: 14) {
                        // Radio button - daha minimal tasarım
                        Circle()
                            .strokeBorder(
                                selectedPackage == package ?
                                    LinearGradient(
                                        colors: [tertiaryAccent, accentColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) : LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                lineWidth: 1.5
                            )
                            .background(
                                Circle()
                                    .fill(selectedPackage == package ?
                                          LinearGradient(
                                            colors: [tertiaryAccent, accentColor],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          ) : LinearGradient(
                                            colors: [Color.clear, Color.clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          ))
                                    .padding(5)
                            )
                            .frame(width: 20, height: 20)
                        
                        // Başlık ve detaylar
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if let savings = savings {
                                    Text(savings)
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(accentColor)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(accentColor.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            
                            if let perMonth = perMonth {
                                Text(String(format: NSLocalizedString("Only %@ per month", comment: ""), "\(perMonth)"))
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Sağ taraf - Fiyat
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        
                        if isRecommended {
                            Text(NSLocalizedString("Most Popular", comment: ""))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(accentColor)
                                .padding(.top, 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                    
                    // Selected state overlay
                    if selectedPackage == package {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tertiaryAccent.opacity(0.1),
                                        accentColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Subtle border
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [tertiaryAccent.opacity(0.3), accentColor.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    }
                    
                    // Recommended state overlay
                    if isRecommended && selectedPackage != package {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tertiaryAccent.opacity(0.05),
                                        accentColor.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            .animation(.easeInOut(duration: 0.2), value: selectedPackage)
        }
    }
}

// MARK: - Terms Section
extension PaywallView {
    private var termsSection: some View {
        HStack(spacing: 5) {
            linkButton(NSLocalizedString("Terms", comment: ""), urlString: "https://kitgetapp.netlify.app/terms-of-use")
            Text("•")
                .foregroundColor(.white.opacity(0.5))
            linkButton(NSLocalizedString("Privacy", comment: ""), urlString: "https://kitgetapp.netlify.app/privacy-policy")
        }
        .font(.system(size: 12))
        .foregroundColor(.white.opacity(0.7))
    }
    
    private func linkButton(_ title: String, urlString: String) -> some View {
        Button {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Text(title)
                .underline()
        }
    }
}

// MARK: - RevenueCat İşlemleri
extension PaywallView {
    private func fetchOfferings() {
        isLoadingOfferings = true
        Purchases.shared.getOfferings { (offerings, error) in
            isLoadingOfferings = false
            if let error = error {
                print("Error fetching offerings: \(error.localizedDescription)")
            } else if let offerings = offerings {
                self.offering = offerings.current
                // Annual paketi varsayılan seçim:
                if let annualPackage = offerings.current?.annual {
                    self.selectedPackage = annualPackage
                }
            }
        }
    }
    
    private func restorePurchases() {
        showLoading = true
        Purchases.shared.restorePurchases { (customerInfo, error) in
            DispatchQueue.main.async {
                self.showLoading = false
                
                if let error = error {
                    print("Error restoring purchases: \(error.localizedDescription)")
                    self.alertTitle = NSLocalizedString("Restore Failed", comment: "")
                    self.alertMessage = NSLocalizedString("Failed to restore purchases. Please try again later.", comment: "")
                    self.showAlert = true
                } else if let customerInfo = customerInfo,
                          customerInfo.entitlements["pro"]?.isActive == true {
                    // Başarılı restore
                    self.alertTitle = NSLocalizedString("Success", comment: "")
                    self.alertMessage = NSLocalizedString("Your purchases have been successfully restored!", comment: "")
                    self.showAlert = true
                    
                    // Abonelik durumunu güncelle
                    self.subscriptionManager.isUserSubscribed = true
                    self.subscriptionManager.checkSubscriptionStatus()
                    
                    // Abonelik değişikliğini bildir
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionChanged"), object: nil)
                    
                    // Alert kapandıktan sonra view'i kapat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    // Restore edilecek satın alım bulunamadı
                    print("No active entitlement found during restore.")
                    self.alertTitle = NSLocalizedString("No Purchases Found", comment: "")
                    self.alertMessage = NSLocalizedString("No previous purchases were found to restore.", comment: "")
                    self.showAlert = true
                }
            }
        }
    }
    
    private func purchasePackage(package: Package) {
        showLoading = true
        Purchases.shared.purchase(package: package) { (transaction, customerInfo, error, userCancelled) in
            DispatchQueue.main.async {
                self.showLoading = false
                
                if let error = error {
                    print("Error purchasing package: \(error.localizedDescription)")
                    self.alertTitle = NSLocalizedString("Purchase Failed", comment: "")
                    self.alertMessage = NSLocalizedString("Failed to complete the purchase. Please try again later.", comment: "")
                    self.showAlert = true
                } else if let customerInfo = customerInfo,
                          customerInfo.entitlements["pro"]?.isActive == true {
                    self.alertTitle = NSLocalizedString("Success", comment: "")
                    self.alertMessage = NSLocalizedString("Thank you for your purchase!", comment: "")
                    self.showAlert = true
                    
                    // Abonelik durumunu güncelle
                    self.subscriptionManager.isUserSubscribed = true
                    self.subscriptionManager.checkSubscriptionStatus()
                    
                    // Abonelik değişikliğini bildir
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionChanged"), object: nil)
                    
                    // Alert kapandıktan sonra view'i kapat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } else if userCancelled {
                    print("User cancelled the purchase.")
                }
            }
        }
    }
}

// MARK: - Shimmering Effect
extension View {
    func shimmering() -> some View {
        self.modifier(ShimmeringEffect())
    }
}

struct ShimmeringEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.1), location: 0.3),
                            .init(color: .white.opacity(0.2), location: 0.5),
                            .init(color: .white.opacity(0.1), location: 0.7),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width)
                    .offset(x: geo.size.width * phase)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .onAppear {
                phase = 1
            }
            .clipped()
    }
}
