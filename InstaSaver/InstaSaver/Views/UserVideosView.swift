// UserVideosView.swift
//import SwiftUI

//struct UserVideosView: View {
//    @ObservedObject var viewModel: VideoViewModel
//    @StateObject private var subscriptionManager = SubscriptionManager()
//    @Environment(\.presentationMode) var presentationMode
//    let interstitial = InterstitialAd()
//    
//    var body: some View {
//        ZStack {
//            // Arka plan (HomeView ile tutarlı şekilde beyaz)
//            Color.white
//                .edgesIgnoringSafeArea(.all)
//            
//            VStack(spacing: 16) {
//                
//                // PROFIL ALANI
//                if let firstVideo = viewModel.userVideos.first,
//                   let author = firstVideo.author {
//                    
//                    VStack {
//                        // Üst kısım: Profil fotoğrafı + Username
//                        HStack(spacing: 16) {
//                            // Profil fotoğrafı
//                            if let avatarUrl = author.avatar,
//                               let url = URL(string: avatarUrl) {
//                                VideoCoverImage(urlString: url.absoluteString)
//                                    .frame(width: 80, height: 80)
//                                    .clipShape(Circle())
//                                    .overlay(
//                                        Circle()
//                                            .stroke(Color.black, lineWidth: 2)
//                                    )
//                            } else {
//                                Circle()
//                                    .fill(Color.gray)
//                                    .frame(width: 80, height: 80)
//                                    .overlay(
//                                        Circle()
//                                            .stroke(Color.black, lineWidth: 2)
//                                    )
//                            }
//                            
//                            // Kullanıcı Bilgileri
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(author.nickname)
//                                    .font(.headline)
//                                    .fontWeight(.bold)
//                                    .foregroundColor(.black)
//                                
//                                Text("@\(author.uniqueId)")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                            }
//                            
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                        
//                        // TikTok'ta Aç Butonu (Turuncu renk)
//                        Button(action: {
//                            if !subscriptionManager.isUserSubscribed {
//                                interstitial.showAd(
//                                    from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
//                                ) {
//                                    openTikTokUserProfile()
//                                }
//                            } else {
//                                openTikTokUserProfile()
//                            }
//                        }) {
//                            HStack(spacing: 8) {
//                                Image("tiktok_icon")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .frame(width: 20, height: 20)
//                                
//                                Text("Open on TikTok")
//                                    .font(.callout)
//                                    .bold()
//                                    .fontWeight(.semibold)
//                            }
//                            .foregroundColor(.white)
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            // Sadece turuncu renk kullandık
//                            .background(Color.orange)
//                            .cornerRadius(10)
//                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
//                            .padding(.horizontal)
//                        }
//                    }
//                    .padding(.top)
//                    
//                } else {
//                    Text("User information not available")
//                        .font(.headline)
//                        .foregroundColor(.black)
//                        .padding()
//                }
//                
//                // VIDEOLAR GRID
//                let screenWidth: CGFloat = UIScreen.main.bounds.width
//                let padding: CGFloat = 6
//                let spacing: CGFloat = 3
//                let numberOfColumns: Int = 3
//                
//                let availableWidth = screenWidth - (padding * 2) - (spacing * CGFloat(numberOfColumns - 1))
//                let itemWidth = availableWidth / CGFloat(numberOfColumns)
//                let itemHeight = (itemWidth * 4) / 3
//                
//                ScrollView {
//                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: numberOfColumns), spacing: spacing) {
//                        ForEach(viewModel.userVideos, id: \.videoId) { video in
//                            if let originCover = video.originCover,
//                               let url = URL(string: originCover) {
//                                VideoCoverImage(urlString: url.absoluteString)
//                                    .frame(width: itemWidth, height: itemHeight)
//                                    .cornerRadius(8)
//                            } else {
//                                Rectangle()
//                                    .fill(Color.gray.opacity(0.2))
//                                    .frame(width: itemWidth, height: itemHeight)
//                                    .cornerRadius(8)
//                            }
//                        }
//                    }
//                    .padding(.horizontal, padding)
//                }
//            }
//        }
//        .navigationTitle(capitalizedUsername)
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackButtonHidden(true)
//        .navigationBarItems(
//            leading: Button(action: {
//                presentationMode.wrappedValue.dismiss()
//            }) {
//                HStack(spacing: 6) {
//                    // chevron.left ikonu
//                    Image(systemName: "chevron.left")
//                        .font(.system(size: 16, weight: .bold))
//                        .foregroundColor(.white)
//                    
//                    //                    // İsteğe bağlı olarak "Back" yazısı
//                    //                    Text("Back")
//                    //                        .foregroundColor(.white)
//                    //                        .font(.custom("Helvetica-Bold", size: 16))
//                }
//                .padding(.horizontal, 10)
//                .padding(.vertical, 6)
//                .background(
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            Color(red: 0.4, green: 0.2, blue: 0.9),
//                            Color(red: 0.6, green: 0.3, blue: 0.95)
//                        ]),
//                        startPoint: .leading,
//                        endPoint: .trailing
//                    )
//                )
//                .cornerRadius(12)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(Color.white, lineWidth: 2)
//                )
//                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
//            }
//        )
//        .onAppear {
//            // View açıldığında veri yükleme
//            if viewModel.userVideos.isEmpty {
//                viewModel.fetchUserInfo(username: viewModel.username)
//            }
//        }
//    }
//    
//    // TikTok Profilini açma
//    private func openTikTokUserProfile() {
//        if let firstVideo = viewModel.userVideos.first,
//           let userId = firstVideo.author?.uniqueId {
//            let urlString = "https://www.tiktok.com/@\(userId)"
//            if let url = URL(string: urlString) {
//                if UIApplication.shared.canOpenURL(url) {
//                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                }
//            }
//        }
//    }
//    
//    // Navigation Title için kullanıcı adı
//    private var capitalizedUsername: String {
//        guard let username = viewModel.userVideos.first?.author?.nickname else {
//            return "User Videos"
//        }
//        return username.capitalized
//    }
//}

import Foundation

struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: Error
}


