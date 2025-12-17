// Sources/Views/RootView.swift
import SwiftUI
import UIKit
import Firebase
import FirebaseAuth

struct RootView: View {
    @StateObject private var auth = AuthService.shared
    @State private var showOnboarding = false
    @State private var showRoleSelection = false
    @State private var showStartupSplash = Auth.auth().currentUser != nil
    
    var body: some View {
        ZStack {
            Group {
                if auth.isAuthenticated {
                    if showRoleSelection {
                        // 👥 Pantalla de selección de rol
                        RoleSelectionView(
                            viewModel: RoleSelectionViewModel(),
                            onCompletion: {
                                withAnimation(.easeInOut) {
                                    self.showRoleSelection = false
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading))
                        )
                    } else if showOnboarding {
                        // 🧩 Pantalla de onboarding
                        OnboardingView {
                            withAnimation(.easeInOut) {
                                self.showOnboarding = false
                                self.checkUserRole()
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading))
                        )
                    } else {
                        // 🏠 Pantalla principal
                        MainTabView()
                            .transition(.opacity)
                    }
                } else {
                    if showStartupSplash {
                        Color(red: 49/255, green: 209/255, blue: 87/255)
                    } else {
                        // 🔐 Pantalla de login
                        LoginView()
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
            
            // ⏳ Overlay de carga global
            if auth.isLoading {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    .scaleEffect(1.5)
            }
            
            if showStartupSplash {
                StartupSplashView()
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .background(showStartupSplash ? Color(red: 49/255, green: 209/255, blue: 87/255) : Color(.systemBackground))
        .animation(.easeInOut(duration: 0.3), value: auth.isLoading)
        
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            if showStartupSplash {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showStartupSplash = false
                }
            }
            
            let completed = auth.user?.onboardingCompleted ?? false
            if !completed {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.showOnboarding = true
                }
            } else {
                self.checkUserRole()
            }
        }
    }
    
    private func checkUserRole() {
        let role = auth.user?.role ?? ""
        if !role.isEmpty {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.showRoleSelection = false
                self.showOnboarding = false
            }
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.showRoleSelection = true
                self.showOnboarding = false
            }
        }
    }
}

private struct StartupSplashView: View {
    var body: some View {
        ZStack {
            Color(red: 49/255, green: 209/255, blue: 87/255)
                .ignoresSafeArea()
            if let uiImage = loadSplashImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
            }
        }
    }

    private func loadSplashImage() -> UIImage? {
        if let img = UIImage(named: "faviconremovedbackground") {
            return img
        }
        if let url = Bundle.main.url(forResource: "faviconremovedbackground", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        if let img = UIImage(named: "favfavicon") {
            return img
        }
        if let url = Bundle.main.url(forResource: "favfavicon", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        if let url = Bundle.main.url(forResource: "favfavicon", withExtension: "jpg"),
           let img = UIImage(contentsOfFile: url.path) {
            return img
        }
        return nil
    }
}

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
