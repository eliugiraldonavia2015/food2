//
//  OnboardingView.swift
//  food
//
//  Created by Gabriel Barzola arana on 10/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    var onCompletion: () -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    welcomeView
                case .photo:
                    ProfilePictureSetupView(viewModel: viewModel)
                case .interests:
                    InterestSelectionView(viewModel: viewModel)
                case .role:
                    RoleSelectionView(viewModel: RoleSelectionViewModel(), onCompletion: { viewModel.nextStep() })
                case .done:
                    doneView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep != .done {
                        Button("Saltar") {
                            viewModel.skipOnboarding()
                        }
                        .tint(.green)
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .overlay(loadingOverlay)
            .task {
                await viewModel.startFlow()
            }
            .onChange(of: viewModel.currentStep) { _, step in
                if step == .done {
                    onCompletion()
                }
            }
            .animation(.easeInOut, value: viewModel.currentStep)
            .safeAreaInset(edge: .bottom) {
                OnboardingProgressView(
                    totalSteps: viewModel.totalSteps,
                    currentStep: viewModel.currentStepIndex
                )
                .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Step: Welcome
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .symbolEffect(.bounce, options: .repeat(3), value: true)
            
            Text("¡Bienvenido a Food!")
                .font(.largeTitle.bold())
            
            Text("Completa estos pasos rápidos para personalizar tu experiencia.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                viewModel.nextStep()
            }) {
                Text("Comenzar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal)
        }
        .padding()
        .navigationBarHidden(true)
    }
    
    // MARK: - Step: Done
    private var doneView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .symbolEffect(.bounce, options: .repeat(2), value: true)
            
            Text("¡Listo!")
                .font(.largeTitle.bold())
            
            Text("Tu cuenta está lista. Ahora puedes explorar la app.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding()
        .navigationBarHidden(true)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 10) {
                        ProgressView("Guardando...")
                            .progressViewStyle(.circular)
                            .tint(.orange)
                            .scaleEffect(1.3)
                        Text("Por favor espera...")
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.isLoading)
    }
}

// ✅ ELIMINAR COMPLETAMENTE esta estructura duplicada
// El OnboardingProgressView del archivo separado es MEJOR y MÁS COMPLETO
