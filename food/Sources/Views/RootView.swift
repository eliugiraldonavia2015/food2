// Sources/Views/RootView.swift
import SwiftUI
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
                        Color.black
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
        .animation(.easeInOut(duration: 0.3), value: auth.isLoading)
        
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated, let uid = auth.user?.uid else { return }
            if showStartupSplash {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showStartupSplash = false
                }
            }
            
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
    var body: some View {
        ZStack {
            Color(red: 241/255, green: 28/255, blue: 46/255)
                .ignoresSafeArea()
            Image("favfavicon")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
        }
    }
}

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
