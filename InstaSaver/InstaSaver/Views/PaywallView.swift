import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var selectedPackage: Package?
    @State private var packages: [Package] = []
    @State private var isYearlySelected = true
    @State private var showLoader = false
    
    private let gradient = LinearGradient(
        colors: [Color("igPurple"), Color("igPink"), Color("igOrange")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // Background
            Color.white.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // Header Section
                    headerSection
                    
                    // Features Section
                    featuresSection
                    
                    // Pricing Section
                    pricingSection
                    
                    // Social Proof
                    socialProofSection
                    
                    // Money Back Guarantee
                    guaranteeSection
                }
                .padding(.bottom, 30)
            }
            
            // Bottom Purchase Button
            VStack {
                Spacer()
                purchaseButton
            }
            .edgesIgnoringSafeArea(.bottom)
            
            if showLoader {
                LoaderView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeButton
            }
        }
        .onAppear {
            loadOfferings()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Pro Badge
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                Text("PRO")
                    .font(.system(size: 24, weight: .black))
            }
            .foregroundColor(Color("igPurple"))
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(Color("igPurple").opacity(0.15))
            )
            
            Text(NSLocalizedString("Unlock Premium Features", comment: ""))
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("Join thousands of satisfied users", comment: ""))
                .font(.system(size: 17))
                .foregroundColor(.gray)
        }
        .padding(.top, 30)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            FeatureRow(
                icon: "arrow.down.circle.fill",
                title: NSLocalizedString("HD Quality Downloads", comment: ""),
                subtitle: NSLocalizedString("Get the highest quality videos", comment: "")
            )
            FeatureRow(
                icon: "infinity",
                title: NSLocalizedString("Unlimited Downloads", comment: ""),
                subtitle: NSLocalizedString("No daily download limits", comment: "")
            )
            FeatureRow(
                icon: "xmark.circle.fill",
                title: NSLocalizedString("Ad-Free Experience", comment: ""),
                subtitle: NSLocalizedString("Enjoy without interruptions", comment: "")
            )
            FeatureRow(
                icon: "star.fill",
                title: NSLocalizedString("Priority Support", comment: ""),
                subtitle: NSLocalizedString("Get help when you need it", comment: "")
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            // Toggle
            HStack(spacing: 0) {
                PricingToggleButton(
                    isSelected: !isYearlySelected,
                    title: NSLocalizedString("Monthly", comment: ""),
                    action: { isYearlySelected = false }
                )
                
                PricingToggleButton(
                    isSelected: isYearlySelected,
                    title: NSLocalizedString("Yearly", comment: ""),
                    action: { isYearlySelected = true }
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            // Selected Plan Card
            VStack(spacing: 8) {
                if let package = selectedPackage {
                    Text(isYearlySelected ? NSLocalizedString("BEST VALUE", comment: "") : NSLocalizedString("FLEXIBLE PLAN", comment: ""))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color("igPurple"))
                    
                    Text(package.storeProduct.localizedPriceString)
                        .font(.system(size: 36, weight: .bold))
                    
                    if isYearlySelected {
                        Text(NSLocalizedString("Save 50%", comment: ""))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color("igPink"))
                            .cornerRadius(8)
                    }
                    
                    Text(isYearlySelected ? NSLocalizedString("per year", comment: "") : NSLocalizedString("per month", comment: ""))
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var socialProofSection: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("Trusted by 50,000+ Users", comment: ""))
                .font(.system(size: 17, weight: .semibold))
            
            HStack(spacing: 20) {
                RatingView(rating: "4.8", count: "1.2K")
                RatingView(rating: "99%", count: NSLocalizedString("Satisfaction", comment: ""))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var guaranteeSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(Color("igPurple"))
            
            Text(NSLocalizedString("7-Day Money Back Guarantee", comment: ""))
                .font(.system(size: 15, weight: .semibold))
            
            Text(NSLocalizedString("Not satisfied? Get a full refund within 7 days", comment: ""))
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
    
    private var purchaseButton: some View {
        Button(action: {
            handlePurchase()
        }) {
            HStack {
                Text(NSLocalizedString("Upgrade Now", comment: ""))
                    .font(.system(size: 18, weight: .bold))
                
                if let package = selectedPackage {
                    Text("• \(package.storeProduct.localizedPriceString)")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(gradient)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.white.shadow(radius: 20))
    }
    
    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .padding(10)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func loadOfferings() {
        Purchases.shared.getOfferings { offerings, error in
            if let current = offerings?.current, let package = current.availablePackages.first {
                selectedPackage = package
            }
        }
    }
    
    private func handlePurchase() {
        guard let package = selectedPackage else { return }
        
        showLoader = true
        Purchases.shared.purchase(package: package) { transaction, purchaserInfo, error, userCancelled in
            showLoader = false
            if let error = error {
                print("Purchase error: \(error.localizedDescription)")
            } else if !userCancelled {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color("igPurple"))
                .frame(width: 44, height: 44)
                .background(Color("igPurple").opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

struct PricingToggleButton: View {
    let isSelected: Bool
    let title: String
    let action: () -> Void
    
    private let gradient = LinearGradient(
        colors: [Color("igPurple"), Color("igPink")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(width: 120, height: 40)
                .background(
                    isSelected ? gradient : Color.clear
                )
                .cornerRadius(10)
        }
    }
}

struct RatingView: View {
    let rating: String
    let count: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(rating)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("igPurple"))
            
            Text(count)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .frame(width: 100, height: 80)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct LoaderView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }
} 