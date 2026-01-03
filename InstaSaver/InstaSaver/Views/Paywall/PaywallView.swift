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
    @State private var pulseAnimation = false
    @State private var particleAnimation = false
    @StateObject private var specialOfferViewModel = SpecialOfferViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var configManager = ConfigManager.shared
    
    // Alert için state değişkenleri
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private let instagramGradient = LinearGradient(
        colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // MARK: - Cinematic Dark Background
            CinematicPaywallBackground(animateGradient: $animateGradient, particleAnimation: $particleAnimation)
            
            // MARK: - Content
            VStack(spacing: 0) {
                // Navigation Bar
                paywallHeader
                
                if isLoadingOfferings {
                    Spacer()
                    PremiumLoadingView()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            // MARK: - Premium Hero Section
                            premiumHeroSection
                            
                            // MARK: - Features Grid
                            featuresGrid
                            
                            // MARK: - Pricing Section
                            pricingSection
                            
                            // MARK: - CTA Section
                            ctaSection
                            
                            // MARK: - Terms Section
                            termsFooter
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        }
                    }
                }
            
            // Loading Overlay
            if showLoading {
                PremiumPurchaseLoadingView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            configManager.reloadConfig()
            fetchOfferings()
            withAnimation {
            animateGradient = true
                pulseAnimation = true
                particleAnimation = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Header
    private var paywallHeader: some View {
        HStack {
            Spacer()
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                ZStack {
                    // Glowing ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color("igPink").opacity(0.5), Color("igPurple").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 34, height: 34)
                    
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Premium Hero Section
    private var premiumHeroSection: some View {
        VStack(spacing: 10) {
            // App Icon with glow
            ZStack {
                // Outer ring glow
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Color("igPurple"), Color("igPink"), Color("igOrange"), Color("igPurple")],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 88, height: 88)
                    .blur(radius: 4)
                    .opacity(0.6)
                
                // Glass container
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image("insaver2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            }
            
            // Title
            VStack(spacing: 6) {
                Text(NSLocalizedString("Unlock All Features", comment: ""))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(NSLocalizedString("Experience Instagram without limitations", comment: ""))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Grid
    private var featuresGrid: some View {
        VStack(spacing: 0) {
            // Feature items - 2 column grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                if configManager.shouldShowDownloadButtons {
                    FeatureCard(
                        icon: "arrow.down.to.line.compact",
                        title: NSLocalizedString("Premium Downloads", comment: ""),
                        subtitle: NSLocalizedString("Download stories, posts & reels in HD", comment: ""),
                        accentColor: Color("igPurple")
                    )
                    
                    FeatureCard(
                        icon: "square.stack.3d.up.fill",
                        title: NSLocalizedString("Batch Downloads", comment: ""),
                        subtitle: NSLocalizedString("Save time with multiple downloads at once", comment: ""),
                        accentColor: Color("igPink")
                    )
                }
                
                FeatureCard(
                    icon: "infinity",
                    title: NSLocalizedString("Unlimited Access", comment: ""),
                    subtitle: NSLocalizedString("No restrictions, download as much as you want", comment: ""),
                    accentColor: Color("igOrange")
                )
                
                FeatureCard(
                    icon: "eye.slash.fill",
                    title: NSLocalizedString("Ad-Free Experience", comment: ""),
                    subtitle: NSLocalizedString("Enjoy a clean, distraction-free experience", comment: ""),
                    accentColor: Color(red: 0.4, green: 0.8, blue: 0.6)
                )
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color("igPurple").opacity(0.3), Color("igPink").opacity(0.2), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        Group {
            if let offering = offering {
                VStack(spacing: 8) {
                    packageSection(offering: offering)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.04))
                            .frame(height: 80)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color("igPink")))
                            )
                            .shimmering()
                    }
                }
            }
        }
    }
    
    // MARK: - CTA Section
    private var ctaSection: some View {
        VStack(spacing: 10) {
            // Main CTA Button
            Button(action: {
                if let package = selectedPackage {
                    purchasePackage(package: package)
                }
            }) {
                ZStack {
                    // Animated gradient background
                    Capsule()
                        .fill(instagramGradient)
                    
                    // Glass shine
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                    
                    // Content
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(NSLocalizedString("Unlock Premium Access", comment: ""))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 54)
                .shadow(color: Color("igPink").opacity(0.5), radius: 16, x: 0, y: 8)
                .scaleEffect(pulseAnimation ? 1.0 : 0.97)
                .animation(
                    Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            }
            .disabled(selectedPackage == nil)
            .opacity(selectedPackage == nil ? 0.5 : 1.0)
            
            // Restore Purchases
            Button(action: { restorePurchases() }) {
                Text(NSLocalizedString("Restore Purchases", comment: ""))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("igPink"))
            }
            
            // Security Badge
            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                
                Text(NSLocalizedString("Secured by Apple", comment: ""))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Terms Footer
    private var termsFooter: some View {
        HStack(spacing: 6) {
            linkButton(NSLocalizedString("Terms", comment: ""), urlString: "https://insaveapp.vercel.app/terms")
            Text("·")
                .foregroundColor(.white.opacity(0.3))
            linkButton(NSLocalizedString("Privacy", comment: ""), urlString: "https://insaveapp.vercel.app/privacypolicy")
            Text("·")
                .foregroundColor(.white.opacity(0.3))
            linkButton("EULA", urlString: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
        }
        .font(.system(size: 11))
        .foregroundColor(.white.opacity(0.5))
        .padding(.top, 8)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .blur(radius: 4)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(0.5), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 95)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Cinematic Paywall Background
struct CinematicPaywallBackground: View {
    @Binding var animateGradient: Bool
    @Binding var particleAnimation: Bool
    
    var body: some View {
        ZStack {
            // Deep space gradient
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.08),
                    Color(red: 0.06, green: 0.04, blue: 0.12),
                    Color(red: 0.08, green: 0.05, blue: 0.14),
                    Color(red: 0.04, green: 0.03, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Nebula effect
            GeometryReader { geo in
                ZStack {
                    // Purple nebula
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color("igPurple").opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 300)
                        .offset(x: -100, y: -50)
                        .blur(radius: 60)
                        .rotationEffect(.degrees(animateGradient ? 8 : -8))
                    
                    // Pink nebula
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color("igPink").opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 350, height: 280)
                        .offset(x: geo.size.width - 150, y: 100)
                        .blur(radius: 50)
                        .rotationEffect(.degrees(animateGradient ? -5 : 5))
                    
                    // Orange accent
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color("igOrange").opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(x: geo.size.width / 2 - 50, y: geo.size.height - 300)
                        .blur(radius: 40)
                    
                    // Floating particles
                    ForEach(0..<12, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                            .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                            .offset(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: particleAnimation ? CGFloat.random(in: 0...geo.size.height) : CGFloat.random(in: 0...geo.size.height) - 20
                            )
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 3...6))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: particleAnimation
                            )
                    }
                }
            }
            .animation(
                Animation.easeInOut(duration: 6).repeatForever(autoreverses: true),
                value: animateGradient
            )
            
            // Noise texture overlay
            Rectangle()
                .fill(Color.white.opacity(0.015))
                .ignoresSafeArea()
        }
    }
}

// MARK: - Premium Loading View
struct PremiumLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Outer rotating ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Color("igPurple"), Color("igPink"), Color("igOrange"), Color("igPurple")],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                
                // Inner pulse
                Circle()
                    .fill(Color("igPink").opacity(0.2))
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            pulseScale = 1.3
                        }
                    }
                
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text("Loading Premium Features...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Premium Purchase Loading View
struct PremiumPurchaseLoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [Color("igPurple"), Color("igPink"), Color("igOrange"), Color.clear],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
            }
            
                Text(NSLocalizedString("Processing...", comment: ""))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color("igPurple").opacity(0.4), Color("igPink").opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color("igPink").opacity(0.3), radius: 30, x: 0, y: 10)
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
    }
}

// MARK: - Package Section
extension PaywallView {
    @ViewBuilder
    func packageSection(offering: Offering) -> some View {
        VStack(spacing: 10) {
            if let annual = offering.annual {
                if let perMonth = annual.storeProduct.localizedPricePerMonth {
                    premiumPackageCard(
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
                premiumPackageCard(
                    title: NSLocalizedString("Monthly", comment: ""),
                    price: monthly.storeProduct.localizedPriceString,
                    package: monthly
                )
            }
            
            if let weekly = offering.weekly {
                premiumPackageCard(
                    title: NSLocalizedString("Weekly", comment: ""),
                    price: weekly.storeProduct.localizedPriceString,
                    package: weekly
                )
            }
        }
    }
    
    func premiumPackageCard(
        title: String,
        price: String,
        perMonth: String? = nil,
        highlight: String? = nil,
        package: Package,
        isRecommended: Bool = false,
        savings: String? = nil
    ) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedPackage = package
            }
        }) {
            ZStack(alignment: .top) {
                // Main card
                    HStack(spacing: 14) {
                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(
                                selectedPackage == package ?
                                    LinearGradient(
                                    colors: [Color("igPurple"), Color("igPink")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                    ) : LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 20, height: 20)
                        
                        if selectedPackage == package {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("igPurple"), Color("igPink")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    // Title and details
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if let savings = savings {
                                    Text(savings)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color("igOrange"))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                    .background(Color("igOrange").opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            
                            if let perMonth = perMonth {
                                Text(String(format: NSLocalizedString("Only %@ per month", comment: ""), "\(perMonth)"))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    // Price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if isRecommended {
                            Text(NSLocalizedString("Most Popular", comment: ""))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color("igPink"))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, highlight != nil ? 20 : 16)
            .background(
                ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(selectedPackage == package ? 0.08 : 0.04))
                        
                        if selectedPackage == package {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                LinearGradient(
                                        colors: [Color("igPurple").opacity(0.7), Color("igPink").opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                            )
                        } else {
                        RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                    }
                )
                
                // Badge
                if let highlight = highlight {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        
                        Text(highlight)
                            .font(.system(size: 10, weight: .heavy))
                            .kerning(0.5)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color("igPurple"), Color("igPink")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color("igPink").opacity(0.4), radius: 8, x: 0, y: 4)
                    .offset(y: -12)
                    }
            }
            .scaleEffect(selectedPackage == package ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: selectedPackage)
        }
    }
}

// MARK: - Terms Section
extension PaywallView {
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
                    self.alertTitle = NSLocalizedString("Success", comment: "")
                    self.alertMessage = NSLocalizedString("Your purchases have been successfully restored!", comment: "")
                    self.showAlert = true
                    
                    self.subscriptionManager.isUserSubscribed = true
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionChanged"), object: nil)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } else {
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
                    
                    self.subscriptionManager.isUserSubscribed = true
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionChanged"), object: nil)
                    
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
                            .init(color: .white.opacity(0.08), location: 0.3),
                            .init(color: .white.opacity(0.15), location: 0.5),
                            .init(color: .white.opacity(0.08), location: 0.7),
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
