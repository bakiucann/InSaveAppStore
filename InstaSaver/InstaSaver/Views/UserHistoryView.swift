//// UserHistoryView.swift
//
//import SwiftUI
//
//struct UserHistoryView: View {
//    @ObservedObject var viewModel: UserHistoryViewModel
//    @ObservedObject var subscriptionManager = SubscriptionManager()
//    @Environment(\.presentationMode) var presentationMode
//    @State private var showClearAlert = false
//    @State private var showPaywall = false
//    
//    var body: some View {
//        ZStack {
//            // Arka plan
//            Color.white.ignoresSafeArea()
//            
//            VStack {
//                // Boş mu?
//                if viewModel.userSearchHistory.isEmpty {
//                    // Boş State Kartı
//                    VStack(spacing: 10) {
//                        Image(systemName: "clock.fill")
//                            .font(.system(size: 32))
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.orange)
//                            .cornerRadius(12)
//                            .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 3)
//                        
//                        Text("No Search History")
//                            .font(.system(size: 18, weight: .bold))
//                            .foregroundColor(.gray)
//                        
//                        Text("Your username searches will appear here.")
//                            .font(.system(size: 14))
//                            .foregroundColor(.gray)
//                            .padding(.top, 2)
//                    }
//                    .padding(20)
//                    .background(Color.white)
//                    .cornerRadius(16)
//                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
//                    .padding()
//                    
//                } else {
//                    // Geçmişte aramalar varsa
//                    List {
//                        ForEach(viewModel.userSearchHistory, id: \.username) { searchItem in
//                            HStack(spacing: 16) {
//                                // Avatar
//                                CustomAsyncImage(
//                                    url: URL(string: searchItem.avatarUrl ?? ""),
//                                    placeholder: Image(systemName: "person.circle.fill")
//                                )
//                                .frame(width: 50, height: 50)
//                                .clipShape(Circle())
//                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
//                                
//                                // Kullanıcı adı
//                                Text(searchItem.username)
//                                    .font(.system(size: 15, weight: .semibold))
//                                    .foregroundColor(.black)
//                                
//                                Spacer()
//                            }
//                            .padding(.vertical, 8)
//                            .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
//                        }
//                        .onDelete(perform: delete)
//                    }
//                    .listStyle(PlainListStyle())
//                }
//            }
//            
//            // Premium değilse blur + kilit overlay
//            if !subscriptionManager.isUserSubscribed {
//                BlurView()
//                    .edgesIgnoringSafeArea(.all)
//                    .overlay(
//                        VStack(spacing: 12) {
//                            Image(systemName: "lock.square.fill")
//                                .font(.system(size: 34))
//                                .foregroundColor(.white)
//                                .padding()
//                                .background(Color.orange)
//                                .cornerRadius(12)
//                                .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 3)
//                            
//                            Text("User History is a Premium Feature")
//                                .font(.system(size: 18, weight: .bold))
//                                .foregroundColor(.gray)
//                            
//                            Text("Please upgrade your plan")
//                                .font(.system(size: 14))
//                                .foregroundColor(.gray)
//                            
//                            Button(action: {
//                                showPaywall = true
//                            }) {
//                                Text("Unlock Feature")
//                                    .font(.system(size: 16, weight: .bold))
//                                    .foregroundColor(.white)
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 10)
//                                    .background(Color.orange)
//                                    .cornerRadius(10)
//                                    .shadow(color: .orange.opacity(0.3), radius: 3, x: 0, y: 2)
//                            }
//                            .padding(.top, 4)
//                        }
//                            .padding(24)
//                            .background(Color.white)
//                            .cornerRadius(16)
//                            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
//                            .padding(24)
//                    )
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationTitle("User History")
//        // Navigation
//        .navigationBarItems(
//            leading: Button(action: {
//                presentationMode.wrappedValue.dismiss()
//            }) {
//                Image(systemName: "chevron.left")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .frame(width: 32, height: 32)
//                    .background(Color.orange)
//                    .cornerRadius(10)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 10)
//                            .stroke(Color.white, lineWidth: 2)
//                    )
//                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
//            },
//            trailing: Button(action: {
//                showClearAlert = true
//            }) {
//                Image(systemName: "trash")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .frame(width: 32, height: 32)
//                    .background(Color.orange)
//                    .cornerRadius(10)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 10)
//                            .stroke(Color.white, lineWidth: 2)
//                    )
//                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
//            }
//                .disabled(!subscriptionManager.isUserSubscribed)
//        )
//        // Uyarı
//        .alert(isPresented: $showClearAlert) {
//            Alert(
//                title: Text("Clear History"),
//                message: Text("Are you sure you want to clear all search history?"),
//                primaryButton: .destructive(Text("Clear")) {
//                    viewModel.clearAllHistory()
//                },
//                secondaryButton: .cancel()
//            )
//        }
//        // Paywall
//        .fullScreenCover(isPresented: $showPaywall) {
//            NavigationView {
//                PaywallView()
//            }
//        }
//    }
//    
//    private func delete(at offsets: IndexSet) {
//        offsets.forEach { index in
//            viewModel.deleteSearch(at: index)
//        }
//    }
//}
//
//// Blur efekti için SwiftUI view
//struct BlurView: UIViewRepresentable {
//    func makeUIView(context: Context) -> UIVisualEffectView {
//        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
//}
