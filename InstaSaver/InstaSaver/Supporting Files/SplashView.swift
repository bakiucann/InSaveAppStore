// LaunchScreenView.swift
import SwiftUI
import Network

struct SplashView: View {
    @Binding var isConnected: Bool
    @State private var showAlert = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showProgress: Bool = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arka plan - LaunchScreen.storyboard ile aynı
                Color("inSaveBackground")
                    .ignoresSafeArea()
                
                // Merkez içerik - LaunchScreen.storyboard ile tamamen aynı layout
                VStack(spacing: 20) {
                    // Logo - LaunchScreen.storyboard ile aynı boyut ve stil (120x120)
                    Image("insaver2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    // "InSave" yazısı - LaunchScreen.storyboard ile aynı gradient (igPurple -> igPink)
                    Text("InSave")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.clear)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color("igPurple"),
                                    Color("igPink")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text("InSave")
                                    .font(.system(size: 26, weight: .bold))
                            )
                        )
                    
                    // Progress indicator - sadece bağlantı yoksa göster
                    if showProgress && !isConnected {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding(.top, 20)
                            .transition(.opacity)
                    }
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            setupNetworkMonitoring()
            
            // Daha belirgin animasyonlar
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 1
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.6)) {
                scale = 1.1
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.6).delay(0.3)) {
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showProgress = true
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("İnternet Bağlantısı Yok"),
                message: Text("Lütfen internet bağlantınızı kontrol edin."),
                primaryButton: .default(Text("Tekrar Dene")) {
                    retryConnection()
                },
                secondaryButton: .cancel(Text("İptal"))
            )
        }
    }
    
    private func setupNetworkMonitoring() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.monitor.pathUpdateHandler = { path in
                DispatchQueue.main.async {
                    withAnimation {
                        isConnected = path.status == .satisfied
                        if !isConnected {
                            showAlert = true
                        }
                    }
                }
            }
            monitor.start(queue: queue)
        }
    }
    
    private func retryConnection() {
        showAlert = false
        withAnimation {
            isConnected = monitor.currentPath.status == .satisfied
            if !isConnected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    SplashView(isConnected: .constant(false))
}
