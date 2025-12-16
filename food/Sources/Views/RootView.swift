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
            let shouldShowStartupSplash = showStartupSplash || !auth.hasResolvedAuth
            
            if shouldShowStartupSplash {
                Color(red: 49/255, green: 209/255, blue: 87/255)
                    .ignoresSafeArea()
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
            
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
                    }
                } else {
                    if shouldShowStartupSplash {
                        EmptyView()
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
            
            if shouldShowStartupSplash {
                StartupSplashView(imageName: "faviconremovedbackground")
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isLoading)
        
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated, let uid = auth.user?.uid else { return }
            
            // 🔍 Verificar si el usuario ya completó el onboarding
            OnboardingService.shared.hasCompletedOnboarding(uid: uid) { completed in
                DispatchQueue.main.async {
                    if !completed {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            self.showOnboarding = true
                        }
                    } else {
                        // Solo verificar rol si el onboarding está completo
                        self.checkUserRole()
                    }
                }
            }
        }
        .onChange(of: auth.hasResolvedAuth) { _, resolved in
            if resolved && showStartupSplash {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showStartupSplash = false
                }
            }
        }
        .onAppear {
            auth.refreshAuthState()
        }
    }
    
    // ✅ CORRECCIÓN: Lógica mejorada para verificar rol del usuario
    private func checkUserRole() {
        guard let uid = auth.user?.uid else { return }
        
        DatabaseService.shared.db.collection("users").document(uid).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data(), let role = data["role"] as? String, !role.isEmpty {
                    // Usuario tiene rol, ir directamente al Feed
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.showRoleSelection = false
                        self.showOnboarding = false
                    }
                } else {
                    // Usuario necesita seleccionar rol
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.showRoleSelection = true
                        self.showOnboarding = false
                    }
                }
            }
        }
    }
}

private struct StartupSplashView: View {
    let imageName: String
    var body: some View {
        ZStack {
            Color(red: 49/255, green: 209/255, blue: 87/255)
                .ignoresSafeArea()
            if let uiImage = loadSplashImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 220, height: 220)
            }
        }
    }
    private func loadSplashImage() -> UIImage? {
        if let img = UIImage(named: imageName) { return img }
        if let url = Bundle.main.url(forResource: imageName, withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) { return img }
        if let img = UIImage(named: "favfavicon") { return img }
        if let url = Bundle.main.url(forResource: "favfavicon", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) { return img }
        if let url = Bundle.main.url(forResource: "favfavicon", withExtension: "jpg"),
           let img = UIImage(contentsOfFile: url.path) { return img }
        if let img = UIImage(named: "favfavicon-removebg-preview") { return img }
        if let url = Bundle.main.url(forResource: "favfavicon-removebg-preview", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) { return img }
        return nil
    }
}

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
