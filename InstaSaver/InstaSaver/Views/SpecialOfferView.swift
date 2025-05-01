// import SwiftUI
// import RevenueCat

// struct SpecialOfferView: View {
//     @ObservedObject var viewModel: SpecialOfferViewModel
//     @Environment(\.presentationMode) var presentationMode
//     @State private var animateGradient = false
//     @State private var showConfetti = false
//     @State private var showLoading = false
//     @StateObject private var configManager = ConfigManager.shared
    
//     // MARK: - Colors and Gradients
//     private let premiumGradient = LinearGradient(
//         colors: [
//             Color(red: 0.1, green: 0.1, blue: 0.15),
//             Color(red: 0.15, green: 0.15, blue: 0.2)
//         ],
//         startPoint: .top,
//         endPoint: .bottom
//     )
    
//     private let accentColor = Color(red: 0.25, green: 0.6, blue: 0.8)
//     private let secondaryAccent = Color(red: 0.95, green: 0.5, blue: 0.3)
//     private let tertiaryAccent = Color(red: 0.8, green: 0.4, blue: 0.6)
    
//     var body: some View {
//         ZStack {
//             // MARK: - Background
//             premiumGradient
//                 .edgesIgnoringSafeArea(.all)
            
//             // Animated Background Effects
//             VStack {
//                 ZStack {
//                     // Top Gradient
//                     RadialGradient(
//                         gradient: Gradient(colors: [
//                             tertiaryAccent.opacity(0.12),
//                             accentColor.opacity(0.08),
//                             Color.clear
//                         ]),
//                         center: .topTrailing,
//                         startRadius: 0,
//                         endRadius: 400
//                     )
                    
//                     // Bottom Gradient
//                     RadialGradient(
//                         gradient: Gradient(colors: [
//                             accentColor.opacity(0.12),
//                             secondaryAccent.opacity(0.08),
//                             Color.clear
//                         ]),
//                         center: .bottomLeading,
//                         startRadius: 0,
//                         endRadius: 400
//                     )
//                 }
//                 .frame(height: 400)
//                 .rotationEffect(.degrees(animateGradient ? 350 : 0))
//                 .animation(
//                     Animation.easeInOut(duration: 20)
//                         .repeatForever(autoreverses: true),
//                     value: animateGradient
//                 )
//                 Spacer()
//             }
//             .edgesIgnoringSafeArea(.all)
            
//             VStack(spacing: 0) {
//                 // MARK: - Main Content
//                 ScrollView(showsIndicators: false) {
//                     VStack(spacing: 0) {
//                         // Navigation Bar
//                         HStack {
//                             Spacer()
//                             Button {
//                                 viewModel.dismissOffer()
//                                 presentationMode.wrappedValue.dismiss()
//                             } label: {
//                                 Image(systemName: "xmark")
//                                     .font(.system(size: 16, weight: .bold))
//                                     .foregroundColor(.white)
//                                     .padding(8)
//                                     .background(Color.white.opacity(0.1))
//                                     .clipShape(Circle())
//                             }
//                         }
//                         .padding(.horizontal)
//                         .padding(.top, 8)
                        
//                         // MARK: - Hero Section
//                         VStack(spacing: 20) {
//                             // Timer Badge
//                             ZStack {
//                                 Circle()
//                                     .fill(
//                                         LinearGradient(
//                                             colors: [tertiaryAccent, accentColor],
//                                             startPoint: .topLeading,
//                                             endPoint: .bottomTrailing
//                                         )
//                                     )
//                                     .frame(width: 100, height: 100)
//                                     .overlay(
//                                         Circle()
//                                             .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
//                                     )
//                                     .shadow(color: accentColor.opacity(0.3), radius: 15)

//                                 VStack(spacing: 4) {
//                                     Image(systemName: "star.circle.fill")
//                                         .font(.system(size: 28))
//                                         .foregroundColor(.white)
                                    
//                                     Text("LIMITED")
//                                         .font(.system(size: 10, weight: .black))
//                                         .foregroundColor(.white)
//                                 }
//                             }
//                             .overlay(
//                                 ZStack {
//                                     ForEach(0..<2) { i in
//                                         Circle()
//                                             .stroke(Color.white.opacity(0.1), lineWidth: 2)
//                                             .scaleEffect(showConfetti ? 2 : 1)
//                                             .opacity(showConfetti ? 0 : 1)
//                                             .animation(
//                                                 Animation.easeOut(duration: 1)
//                                                     .repeatForever(autoreverses: false)
//                                                     .delay(Double(i) * 0.5),
//                                                 value: showConfetti
//                                             )
//                                     }
//                                 }
//                             )
                            
//                             // Title and Timer
//                             VStack(spacing: 12) {
//                                 Text(NSLocalizedString("🎉 EXCLUSIVE OFFER!", comment: ""))
//                                     .font(.system(size: 28, weight: .heavy))
//                                     .foregroundColor(.white)
//                                     .multilineTextAlignment(.center)
                                
//                                 Text(viewModel.timerString)
//                                     .font(.system(size: 32, weight: .heavy))
//                                     .foregroundColor(.white)
//                                     .padding(.horizontal, 30)
//                                     .padding(.vertical, 15)
//                                     .background(
//                                         RoundedRectangle(cornerRadius: 20)
//                                             .fill(
//                                                 LinearGradient(
//                                                     colors: [tertiaryAccent.opacity(0.3), accentColor.opacity(0.3)],
//                                                     startPoint: .leading,
//                                                     endPoint: .trailing
//                                                 )
//                                             )
//                                             .overlay(
//                                                 RoundedRectangle(cornerRadius: 20)
//                                                     .strokeBorder(
//                                                         LinearGradient(
//                                                             colors: [tertiaryAccent, accentColor],
//                                                             startPoint: .leading,
//                                                             endPoint: .trailing
//                                                         ),
//                                                         lineWidth: 1
//                                                     )
//                                             )
//                                     )
//                                     .shadow(color: accentColor.opacity(0.2), radius: 10)
//                             }
                            
//                             // Subtitle
//                             Text(NSLocalizedString("Don't miss out on this incredible deal!", comment: ""))
//                                 .font(.system(size: 16))
//                                 .foregroundColor(.white.opacity(0.8))
//                                 .multilineTextAlignment(.center)
//                                 .padding(.top, 4)
//                         }
//                         .padding(.top, 10)
                        
//                         // MARK: - Features Section
//                         VStack(spacing: 12) {
//                             Text(NSLocalizedString("What You'll Get", comment: ""))
//                                 .font(.system(size: 18, weight: .bold))
//                                 .foregroundColor(.white)
//                                 .padding(.top, 8)
                            
//                             VStack(spacing: 8) {
//                                 if Locale.current.languageCode != "en" || configManager.showDownloadButtons {
//                                     SpecialOfferFeatureRow(
//                                         icon: "arrow.down.circle.fill",
//                                         title: NSLocalizedString("Premium Downloads", comment: ""),
//                                         subtitle: NSLocalizedString("Download stories, posts & reels in HD", comment: ""),
//                                         gradient: [tertiaryAccent, accentColor]
//                                     )
//                                 }
                                
//                                 SpecialOfferFeatureRow(
//                                     icon: "infinity.circle.fill",
//                                     title: NSLocalizedString("Unlimited Access", comment: ""),
//                                     subtitle: NSLocalizedString("No restrictions, download as much as you want", comment: ""),
//                                     gradient: [accentColor, secondaryAccent]
//                                 )
                                
//                                 SpecialOfferFeatureRow(
//                                     icon: "xmark.circle.fill",
//                                     title: NSLocalizedString("Ad-Free Experience", comment: ""),
//                                     subtitle: NSLocalizedString("Enjoy a clean, distraction-free experience", comment: ""),
//                                     gradient: [secondaryAccent, tertiaryAccent]
//                                 )
//                             }
//                             .padding(.horizontal)
//                         }
//                         .padding(.top, 16)
                        
//                         // MARK: - Pricing Section
//                         VStack(spacing: 20) {
//                             ForEach(viewModel.packages, id: \.identifier) { package in
//                                 SpecialOfferPackageRow(
//                                     package: package,
//                                     isSelected: viewModel.selectedPackage?.identifier == package.identifier,
//                                     action: { viewModel.selectedPackage = package }
//                                 )
//                             }
//                         }
//                         .padding(.horizontal)
//                         .padding(.top, 20)
                        
//                         // MARK: - CTA Section
//                         VStack(spacing: 16) {
//                             // Security Badge
//                             HStack(spacing: 6) {
//                                 Image(systemName: "checkmark.shield.fill")
//                                     .font(.system(size: 12))
//                                     .foregroundColor(accentColor)
//                                 Text("Secured by Apple")
//                                     .font(.system(size: 12))
//                                     .foregroundColor(.white.opacity(0.6))
//                             }
//                             .padding(.top, 8)

//                             // Links Section
//                             HStack(spacing: 5) {
//                                 linkButton(NSLocalizedString("Terms", comment: ""), urlString: "https://kitgetapp.netlify.app/terms-of-use")
//                                 Text("•").foregroundColor(.white.opacity(0.5))
//                                 linkButton(NSLocalizedString("Privacy", comment: ""), urlString: "https://kitgetapp.netlify.app/privacy-policy")
//                                 Text("•").foregroundColor(.white.opacity(0.5))
//                                 linkButton("EULA", urlString: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
//                             }
//                             .font(.system(size: 12))
//                             .foregroundColor(.white.opacity(0.7))
//                             .padding(.top, 4)
                            
//                             // Restore Purchases Butonu
//                             Button(action: {
//                                 viewModel.restorePurchases()
//                             }) {
//                                 Text(NSLocalizedString("Restore Purchases", comment: ""))
//                                     .font(.system(size: 14))
//                                     .foregroundColor(.white.opacity(0.7))
//                                     .underline()
//                             }
//                             .padding(.top, 8)
//                         }
//                         .padding(.vertical, 20)
//                         .padding(.bottom, 1)
//                     }
//                 }
                
//                 // Fixed CTA Button at the bottom
//                 VStack(spacing: 8) {
//                     Button(action: {
//                         viewModel.acceptOffer()
//                     }) {
//                         if viewModel.showLoading {
//                             ProgressView()
//                                 .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                                 .frame(maxWidth: .infinity)
//                                 .frame(height: 56)
//                                 .background(
//                                     LinearGradient(
//                                         colors: [tertiaryAccent, accentColor, secondaryAccent],
//                                         startPoint: .leading,
//                                         endPoint: .trailing
//                                     )
//                                 )
//                                 .clipShape(RoundedRectangle(cornerRadius: 28))
//                                 .shadow(color: accentColor.opacity(0.3), radius: 15)
//                         } else {
//                             Text(NSLocalizedString("Claim Your Offer Now!", comment: ""))
//                                 .font(.system(size: 18, weight: .bold))
//                                 .foregroundColor(.white)
//                                 .frame(maxWidth: .infinity)
//                                 .frame(height: 56)
//                                 .background(
//                                     LinearGradient(
//                                         colors: [tertiaryAccent, accentColor, secondaryAccent],
//                                         startPoint: .leading,
//                                         endPoint: .trailing
//                                     )
//                                 )
//                                 .clipShape(RoundedRectangle(cornerRadius: 28))
//                                 .shadow(color: accentColor.opacity(0.3), radius: 15)
//                                 .overlay(
//                                     RoundedRectangle(cornerRadius: 28)
//                                         .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
//                                 )
//                         }
//                     }
//                     .disabled(viewModel.showLoading)
//                     .padding(.horizontal)
//                 }
//                 .padding(.bottom, 1)
//                 .padding(.top, 10)
//                 .background(
//                     Rectangle()
//                         .fill(.clear)
//                 )
//             }
//         }
//         .navigationBarHidden(true)
//         .onAppear {
//             animateGradient = true
//             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                 withAnimation(.spring()) {
//                     showConfetti = true
//                 }
//             }
//         }
//         .alert(isPresented: $viewModel.showAlert) {
//             Alert(
//                 title: Text(viewModel.alertTitle),
//                 message: Text(viewModel.alertMessage),
//                 dismissButton: .default(Text("OK"))
//             )
//         }
//     }

//     // MARK: - Link Button Function
//     private func linkButton(_ title: String, urlString: String) -> some View {
//         Button {
//             if let url = URL(string: urlString) {
//                 UIApplication.shared.open(url)
//             }
//         } label: {
//             Text(title)
//                 .underline()
//                 .foregroundColor(accentColor)
//         }
//     }
// }

// // MARK: - Feature Row Component
// struct SpecialOfferFeatureRow: View {
//     let icon: String
//     let title: String
//     let subtitle: String
//     let gradient: [Color]
    
//     var body: some View {
//         HStack(spacing: 12) {
//             // Icon Container
//             ZStack {
//                 Circle()
//                     .fill(
//                         LinearGradient(
//                             colors: gradient,
//                             startPoint: .topLeading,
//                             endPoint: .bottomTrailing
//                         )
//                     )
//                     .frame(width: 38, height: 38)
//                     .overlay(
//                         Circle()
//                             .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
//                     )
                
//                 Image(systemName: icon)
//                     .font(.system(size: 16))
//                     .foregroundColor(.white)
//             }
            
//             VStack(alignment: .leading, spacing: 2) {
//                 Text(title)
//                     .font(.system(size: 15, weight: .semibold))
//                     .foregroundColor(.white)
                
//                 Text(subtitle)
//                     .font(.system(size: 13))
//                     .foregroundColor(.white.opacity(0.7))
//             }
            
//             Spacer()
//         }
//         .padding(.vertical, 10)
//         .padding(.horizontal, 12)
//         .background(
//             RoundedRectangle(cornerRadius: 14)
//                 .fill(Color.white.opacity(0.05))
//         )
//         .overlay(
//             RoundedRectangle(cornerRadius: 14)
//                 .strokeBorder(
//                     LinearGradient(
//                         colors: [gradient[0].opacity(0.3), gradient[1].opacity(0.3)],
//                         startPoint: .leading,
//                         endPoint: .trailing
//                     ),
//                     lineWidth: 1
//                 )
//         )
//     }
// }

// // MARK: - Package Row Component
// struct SpecialOfferPackageRow: View {
//     let package: Package
//     let isSelected: Bool
//     let action: () -> Void
    
//     private let accentColor = Color(red: 0.25, green: 0.6, blue: 0.8)
//     private let tertiaryAccent = Color(red: 0.8, green: 0.4, blue: 0.6)
//     private let secondaryAccent = Color(red: 0.95, green: 0.5, blue: 0.3)
    
//     var body: some View {
//         Button(action: action) {
//             HStack {
//                 // Package Info
//                 VStack(alignment: .leading, spacing: 4) {
//                     if let period = package.storeProduct.subscriptionPeriod {
//                         Text(period.unit == .month ? "Monthly" : "Annual")
//                             .font(.system(size: 18, weight: .semibold))
//                             .foregroundColor(.white)
//                     }
                    
//                     if let perMonth = package.storeProduct.localizedPricePerMonth {
//                         Text(String(format: NSLocalizedString("Only %@ per month", comment: ""), "\(perMonth)"))
//                             .font(.system(size: 14))
//                             .foregroundColor(.white.opacity(0.7))
//                     }
//                 }
                
//                 Spacer()
                
//                 // Price
//                 Text(package.storeProduct.localizedPriceString)
//                     .font(.system(size: 24, weight: .bold))
//                     .foregroundColor(.white)
//             }
//             .padding()
//             .background(
//                 RoundedRectangle(cornerRadius: 16)
//                     .fill(isSelected ? 
//                         LinearGradient(
//                             colors: [tertiaryAccent.opacity(0.3), accentColor.opacity(0.3), secondaryAccent.opacity(0.3)],
//                             startPoint: .leading,
//                             endPoint: .trailing
//                         ) : LinearGradient(
//                             colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)],
//                             startPoint: .leading,
//                             endPoint: .trailing
//                         )
//                     )
//             )
//             .overlay(
//                 RoundedRectangle(cornerRadius: 16)
//                     .strokeBorder(
//                         isSelected ?
//                             LinearGradient(
//                                 colors: [tertiaryAccent, accentColor, secondaryAccent],
//                                 startPoint: .leading,
//                                 endPoint: .trailing
//                             ) : LinearGradient(
//                                 colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
//                                 startPoint: .leading,
//                                 endPoint: .trailing
//                             ),
//                         lineWidth: 2
//                     )
//             )
//             .shadow(color: isSelected ? accentColor.opacity(0.3) : Color.clear, radius: 8)
//             .scaleEffect(isSelected ? 1.02 : 1.0)
//             .animation(.easeInOut(duration: 0.2), value: isSelected)
//         }
//     }
// }

// struct SpecialOfferView_Previews: PreviewProvider {
//     static var previews: some View {
//         SpecialOfferView(viewModel: SpecialOfferViewModel())
//             .preferredColorScheme(.dark) // Karanlık modda önizleme
//     }
// } 
