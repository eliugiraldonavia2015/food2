//
//  RoleSelectionViewModel.swift
//  food
//
//  Created by eliu giraldo on 28/11/25.
//

// Sources/Presentation/Authentication/RoleSelection/RoleSelectionViewModel.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
public final class RoleSelectionViewModel: ObservableObject {
    @Published private(set) var selectedRole: Role? = nil
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    public enum Role: String, CaseIterable {
        case client = "client"
        case rider = "rider"
        case restaurant = "restaurant"
    }
    
    public var isRoleSelected: Bool {
        selectedRole != nil
    }
    
    public init() {}
    
    public func loadUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Usuario no autenticado"
            return
        }
        
        // Cargar rol existente si existe
        DatabaseService.shared.db.collection("users").document(uid).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data(), let role = data["role"] as? String {
                    self.selectedRole = Role(rawValue: role)
                }
            }
        }
    }
    
    public func selectRole(_ role: Role) {
        selectedRole = role
    }
    
    public func confirmSelection() {
        guard let role = selectedRole else { return }
        
        isLoading = true
        saveUserRole(role) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error guardando rol: \(error.localizedDescription)"
                    return
                }
                
                // Actualizar estado local con el nuevo rol
                self.updateAuthStateWithRole(role)
            }
        }
    }
    
    private func saveUserRole(_ role: Role, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "RoleSelection", code: 401,
                               userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"]))
            return
        }
        
        let updateData: [String: Any] = [
            "role": role.rawValue,
            "roleSelectedAt": Timestamp(date: Date())
        ]
        
        DatabaseService.shared.db
            .collection("users")
            .document(uid)
            .updateData(updateData) { error in
                completion(error)
            }
    }
    
    private func updateAuthStateWithRole(_ role: Role) {
        guard let user = Auth.auth().currentUser else { return }
        
        let updatedUser = AppUser(
            uid: user.uid,
            email: user.email,
            name: user.displayName,
            username: AuthService.shared.extractUsernameFromName(user.displayName),
            phoneNumber: user.phoneNumber,
            photoURL: user.photoURL,
            interests: AuthService.shared.getCurrentUserInterests(),
            role: role.rawValue // ✅ CORRECCIÓN: Agregar el rol al usuario
        )
        
        AuthService.shared.user = updatedUser
    }
}
