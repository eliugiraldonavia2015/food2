// Sources/Views/RootView.swift
import SwiftUI
import UIKit
import Firebase
import FirebaseAuth

struct RootView: View {
    @StateObject private var auth = AuthService.shared
    @State private var showOnboarding = false
    @State private var showRoleSelection = false
    
    var body: some View {
        ZStack(alignment: .top) { // Alignment top para el overlay
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
                    // Estado de carga inicial o transición (Splash simulado)
                    // Debe coincidir EXACTAMENTE con LaunchScreen.storyboard
                    ZStack {
                        Color(red: 244/255, green: 37/255, blue: 123/255)
                            .ignoresSafeArea()
                        Image("foodtook_isotipo_blanco")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .offset(x: -30) // Offset idéntico al LaunchScreen
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
            
            // 🚀 Overlay de Subida de Video (Zero-Wait)
            // NOTA: Usamos el componente público definido en Components/UploadStatusOverlay.swift
            // No redeclaramos una estructura interna aquí para evitar conflictos.
            UploadStatusOverlay()
                .padding(.top, 40) // Espacio para Dynamic Island / Notch
                .zIndex(500)
        }
        .background(Color(red: 244/255, green: 37/255, blue: 123/255))
        .animation(.easeInOut(duration: 0.3), value: auth.isLoading)
        
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            
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
// Se eliminó la redeclaración de UploadStatusOverlay para usar la versión pública compartida

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
