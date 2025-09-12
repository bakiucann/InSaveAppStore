// TabBarView.swift

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var bottomSheetManager: BottomSheetManager
    @StateObject private var collectionsViewModel = CollectionsViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                switch selectedTab {
                case .home:
                    HomeView(selectedTab: $selectedTab)
                        .navigationViewStyle(StackNavigationViewStyle())
                case .collections:
                    NavigationView {
                        CollectionsView(viewModel: collectionsViewModel, onCollectionSelected: { _ in })
                    } .navigationViewStyle(StackNavigationViewStyle())
                case .history:
                    NavigationView {
                        HistoryView(viewModel: HistoryViewModel())
                    } .navigationViewStyle(StackNavigationViewStyle())
                }
                
                // Eğer kullanıcı pro değilse BannerAdView göster
                if !subscriptionManager.isUserSubscribed {
                    BannerAdView()
                        .frame(width: UIScreen.main.bounds.width, height: 50)
                        .padding(.bottom, 10)
                }
                
                CustomTabBar(currentTab: $selectedTab)
            }
            
            CustomBottomSheet(
                isShowing: $bottomSheetManager.showBottomSheet,
                actions: bottomSheetManager.actions,
                onCancel: {
                    bottomSheetManager.showBottomSheet = false
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            setupActions()
        }
    }
    
    private func setupActions() {
        bottomSheetManager.actions = [
            BottomSheetAction(label: "Rename", background: .red, textColor: .black) {
                print("Rename action triggered")
            },
            BottomSheetAction(label: "Delete", background: .red, textColor: .white) {
                print("Delete action triggered")
            }
        ]
    }
    
    private func setupSubscriptionObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SubscriptionChanged"),
            object: nil,
            queue: .main
        ) { _ in
            print("Abonelik durumu değişti, SubscriptionManager'ı güncelliyorum")
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var bottomSheetManager = BottomSheetManager()
        TabBarView()
            .environmentObject(bottomSheetManager)
    }
}
