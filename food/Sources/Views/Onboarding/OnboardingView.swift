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
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geometry in
                    ZStack {
                        Group {
                            if let uiImage = UIImage(named: "fondoonboarding") {
                                Image(uiImage: uiImage)
                                    .resizable()
                            } else if let url = Bundle.main.url(forResource: "fondoonboarding", withExtension: "png"),
                                      let img = UIImage(contentsOfFile: url.path) {
                                Image(uiImage: img)
                                    .resizable()
                            } else {
                                Color.black
                            }
                        }
                        .scaledToFill()
                        .scaleEffect(1.2)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea(.container, edges: .all)
                        .clipped()
                        .opacity(0.8)
                        
                        LinearGradient(
                            colors: [
                                .black.opacity(0.45),
                                .clear,
                                .black.opacity(0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .ignoresSafeArea(.container, edges: .all)
                
                VStack {
                    if viewModel.currentStep == .welcome {
                        Spacer().frame(height: 180)
                        welcomeView
                            .padding(.horizontal, 24)
                        Spacer()
                    } else if viewModel.currentStep == .photo {
                        Spacer()
                        ProfilePictureSetupView(viewModel: viewModel)
                            .padding(.horizontal, 24)
                        Spacer()
                    } else if viewModel.currentStep == .interests {
                        Spacer()
                        InterestSelectionView(viewModel: viewModel)
                            .padding(.horizontal, 24)
                        Spacer()
                    } else if viewModel.currentStep == .role {
                        Spacer()
                        RoleSelectionView(viewModel: RoleSelectionViewModel(), onCompletion: { viewModel.nextStep() })
                            .padding(.horizontal, 24)
                        Spacer()
                    } else {
                        VStack {
                            switch viewModel.currentStep {
                            case .photo:
                                ProfilePictureSetupView(viewModel: viewModel)
                            case .interests:
                                InterestSelectionView(viewModel: viewModel)
                            case .role:
                                RoleSelectionView(viewModel: RoleSelectionViewModel(), onCompletion: { viewModel.nextStep() })
                            case .done:
                                doneView
                            default:
                                EmptyView()
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
            }
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep == .photo || viewModel.currentStep == .interests || viewModel.currentStep == .role {
                        Button(action: { viewModel.goBack() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(fuchsiaColor)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep != .done {
                        Button("Saltar") {
                            viewModel.skipOnboarding()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
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
            BrandLogoView()
            
            Text("¡Bienvenido!")
                .font(.largeTitle.bold())
            
            (
                Text("Descubre los mejores ")
                    .foregroundColor(.white.opacity(0.9)) +
                Text("platos")
                    .foregroundColor(fuchsiaColor) +
                Text(" a través de videos y recíbelos en tu puerta.")
                    .foregroundColor(.white.opacity(0.9))
            )
            .font(.body)
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
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(fuchsiaColor)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: fuchsiaColor.opacity(0.3), radius: 10, x: 0, y: 5)
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
