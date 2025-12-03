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
            ZStack {
                GeometryReader { geometry in
                    ZStack {
                        AsyncImage(url: URL(string: "https://images.pexels.com/photos/1640772/pexels-photo-1640772.jpeg")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(1.2)
                        } placeholder: {
                            Color.black
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea(.container, edges: .all)
                        .clipped()
                        .opacity(0.8)
                        
                        LinearGradient(
                            colors: [
                                .black.opacity(0.3),
                                .clear,
                                .black
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .ignoresSafeArea(.container, edges: .all)
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("Food")
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(.white) +
                        Text("Took")
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(.green)
                        
                        Text("Taste the trend.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Spacer()
                    
                    VStack {
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
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(.systemGray6).opacity(0.95), .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .green.opacity(0.2), radius: 40, x: 0, y: -10)
                }
            }
            .preferredColorScheme(.dark)
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
