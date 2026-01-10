// Sources/ViewModels/OnboardingViewModel.swift
import Combine
import UIKit
import FirebaseAuth

@MainActor
public final class OnboardingViewModel: ObservableObject {
    @Published public private(set) var currentStep: Step = .welcome
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    
    @Published public var interests: [InterestOption] = [
        .init(name: "Comida rápida", isSelected: false),
        .init(name: "Comida saludable", isSelected: false),
        .init(name: "Hamburguesas", isSelected: false),
        .init(name: "Pizza", isSelected: false),
        .init(name: "Sushi", isSelected: false),
        .init(name: "Pastas", isSelected: false),
        .init(name: "Ensaladas", isSelected: false),
        .init(name: "Asados", isSelected: false),
        .init(name: "Tacos y Comida Mexicana", isSelected: false),
        .init(name: "Comida China", isSelected: false),
        .init(name: "Comida Árabe", isSelected: false),
        .init(name: "Mariscos", isSelected: false),
        .init(name: "Comida típica", isSelected: false),
        .init(name: "Sándwiches", isSelected: false),
        .init(name: "Desayunos", isSelected: false),
        .init(name: "Brunch", isSelected: false),
        .init(name: "Postres", isSelected: false),
        .init(name: "Helados", isSelected: false),
        .init(name: "Panadería", isSelected: false),
        .init(name: "Donas", isSelected: false),
        .init(name: "Tortas y Pasteles", isSelected: false),
        .init(name: "Café", isSelected: false),
        .init(name: "Jugos naturales", isSelected: false),
        .init(name: "Cerveza", isSelected: false),
        .init(name: "Vinos", isSelected: false),
        .init(name: "Cocteles", isSelected: false),
        .init(name: "Malteadas", isSelected: false),
        .init(name: "Snacks", isSelected: false),
        .init(name: "Tapas y Entradas", isSelected: false)
    ]
    
    @Published public var profileImage: UIImage?
    
    private let service = OnboardingService.shared
    private let auth = AuthService.shared
    private let storage = StorageService.shared
    
    public enum Step {
        case welcome
        case photo
        case interests
        case role
        case done
    }
    
    public struct InterestOption: Identifiable, Equatable {
        public let id = UUID()
        public let name: String
        public var isSelected: Bool
    }
    
    // ✅ AGREGADO: Propiedades para el progreso
    public let totalSteps = 5
    public var currentStepIndex: Int {
        switch currentStep {
        case .welcome: return 0
        case .photo: return 1
        case .interests: return 2
        case .role: return 3
        case .done: return 4
        }
    }
    
    // MARK: - Public API
    public func startFlow() async {
        guard let user = auth.user else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let completed: Bool = try await withCheckedThrowingContinuation { continuation in
                service.hasCompletedOnboarding(uid: user.uid) { result in
                    continuation.resume(returning: result)
                }
            }
            
            if !completed {
                currentStep = .welcome
            }
        } catch {
            print("[OnboardingVM] Error checking status: \(error)")
        }
    }
    
    public func nextStep() {
        switch currentStep {
        case .welcome: currentStep = .photo
        case .photo: currentStep = .interests
        case .interests: currentStep = .role
        case .role: Task { await finishOnboarding() }
        case .done: break
        }
    }
    
    public func skipOnboarding() {
        Task { await finishOnboarding() }
    }
    
    // MARK: - Public Navigation Control
    public func goBack() {
        switch currentStep {
        case .photo:
            currentStep = .welcome
        case .interests:
            currentStep = .photo
        case .role:
            currentStep = .interests
        default:
            break
        }
    }

    // MARK: - Private Implementation
    private func finishOnboarding() async {
        guard let user = auth.user else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            var uploadedPhotoURL: URL?
            
            // 1️⃣ Subir foto si existe
            if let image = profileImage {
                uploadedPhotoURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                    storage.uploadProfileImage(uid: user.uid, image: image) { result in
                        switch result {
                        case .success(let url):
                            continuation.resume(returning: url)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                if let url = uploadedPhotoURL {
                    auth.updateProfilePhoto(with: url)
                }
            }
            
            // 2️⃣ Guardar intereses
            if !selectedInterests.isEmpty {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    DatabaseService.shared.updateUserInterests(
                        uid: user.uid,
                        interests: selectedInterests
                    ) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            }
            
            // 3️⃣ Marcar onboarding como completado
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                service.markOnboardingAsCompleted(uid: user.uid) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            
            // 4️⃣ ✅ CORREGIDO: Actualizar estado local SOLO después de confirmar guardado
            await MainActor.run {
                currentStep = .done
                // Ejecutar inmediatamente sin delay forzado
                self.auth.refreshAuthState()
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Error guardando datos. Continúa usando la app normalmente."
                print("[OnboardingVM] \(error)")
            }
        }
    }
    
    private var selectedInterests: [String] {
        interests.compactMap { $0.isSelected ? $0.name : nil }
    }
}
