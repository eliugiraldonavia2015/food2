import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import UIKit
import Combine

// MARK: - Domain Models
public struct PasswordStrength {
    public let score: Int
    public let strength: StrengthLevel
    public let feedback: [PasswordFeedback]
    
    public enum StrengthLevel: String, CaseIterable {
        case veryWeak = "Muy débil"
        case weak = "Débil"
        case medium = "Media"
        case strong = "Fuerte"
        case veryStrong = "Muy fuerte"
        
        public var colorIdentifier: String {
            switch self {
            case .veryWeak, .weak: return "red"
            case .medium: return "orange"
            case .strong, .veryStrong: return "green"
            }
        }
        
        public var progressValue: Double {
            switch self {
            case .veryWeak: return 0.2
            case .weak: return 0.4
            case .medium: return 0.6
            case .strong: return 0.8
            case .veryStrong: return 1.0
            }
        }
    }
    
    public struct PasswordFeedback {
        public let type: FeedbackType
        public let message: String
        
        public init(type: FeedbackType, message: String) {
            self.type = type
            self.message = message
        }
    }
    
    public enum FeedbackType {
        case excellent
        case success
        case warning
        case info
        case error
        case requirementMet
        case requirementMissing
        
        public var emoji: String {
            switch self {
            case .excellent: return "🎉"
            case .success: return "✅"
            case .warning: return "⚠️"
            case .info: return "💡"
            case .error: return "❌"
            case .requirementMet: return "✓"
            case .requirementMissing: return ""
            }
        }
    }
}

// ✅ STRUCT AppUser CORREGIDA con propiedad role
public struct AppUser: Identifiable {
    public let id = UUID()
    public let uid: String
    public let email: String?
    public let name: String?
    public let username: String?
    public let phoneNumber: String?
    public let photoURL: URL?
    public let interests: [String]?
    public let role: String?
    public let bio: String?
    public let location: String?
    public let onboardingCompleted: Bool?
    
    public init(
        uid: String,
        email: String?,
        name: String?,
        username: String? = nil,
        phoneNumber: String? = nil,
        photoURL: URL? = nil,
        interests: [String]? = nil,
        role: String? = nil,
        bio: String? = nil,
        location: String? = nil,
        onboardingCompleted: Bool? = nil
    ) {
        self.uid = uid
        self.email = email
        self.name = name
        self.username = username
        self.phoneNumber = phoneNumber
        self.photoURL = photoURL
        self.interests = interests
        self.role = role
        self.bio = bio
        self.location = location
        self.onboardingCompleted = onboardingCompleted
    }
    
    // ✅ Inicializador de compatibilidad
    public init(
        uid: String,
        email: String?,
        name: String?,
        username: String? = nil,
        phoneNumber: String? = nil,
        photoURL: URL?
    ) {
        self.init(
            uid: uid,
            email: email,
            name: name,
            username: username,
            phoneNumber: phoneNumber,
            photoURL: photoURL,
            interests: nil,
            role: nil,
            bio: nil,
            location: nil,
            onboardingCompleted: nil
        )
    }
}

// MARK: - Profile Photo Updates
extension AuthService {
    public func updateProfilePhoto(with url: URL) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        DatabaseService.shared.updateUserDocument(
            uid: currentUser.uid,
            photoURL: url
        )
        
        let changeRequest = currentUser.createProfileChangeRequest()
        changeRequest.photoURL = url
        changeRequest.commitChanges { _ in }
        
        self.user = AppUser(
            uid: currentUser.uid,
            email: self.user?.email,
            name: self.user?.name,
            username: self.user?.username,
            phoneNumber: self.user?.phoneNumber,
            photoURL: url,
            interests: self.user?.interests,
            role: self.user?.role,
            bio: self.user?.bio,
            location: self.user?.location,
            onboardingCompleted: self.user?.onboardingCompleted
        )
    }
    
    public func isFollowingCached(_ uid: String) -> Bool? {
        return followingCache.get(uid)
    }
    
    public func setFollowingCached(_ uid: String, value: Bool) {
        followingCache.set(uid, value: value)
    }
    
    public func recordLocalFollow(followedUid: String) {
        guard let me = Auth.auth().currentUser?.uid else { return }
        followingStore.add(for: me, followedUid: followedUid)
        setFollowingCached(followedUid, value: true)
    }
}

// MARK: - Interest Management
extension AuthService {
    public struct InterestValidation {
        public static let maxInterests = 15
        public static let minInterests = 3
        public static let maxInterestLength = 30
        
        public static func validateInterests(_ interests: [String]) -> InterestValidationResult {
            // Validar cantidad máxima
            if interests.count > maxInterests {
                return .failure(.tooManyInterests(maxAllowed: maxInterests))
            }
            
            // Validar longitud de cada interés
            for interest in interests {
                if interest.count > maxInterestLength {
                    return .failure(.interestTooLong(maxLength: maxInterestLength))
                }
                
                if interest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return .failure(.emptyInterest)
                }
                
                // Validar caracteres permitidos
                let allowedCharacterSet = CharacterSet.letters.union(.decimalDigits).union(.whitespaces).union(CharacterSet(charactersIn: "-"))
                if interest.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                    return .failure(.invalidCharacters)
                }
            }
            
            // Validar duplicados (case insensitive)
            let lowercasedInterests = interests.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            let uniqueInterests = Set(lowercasedInterests)
            if uniqueInterests.count != interests.count {
                return .failure(.duplicateInterests)
            }
            
            return .success(interests)
        }
        
        public static func normalizeInterests(_ interests: [String]) -> [String] {
            return interests.map { interest in
                interest
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .capitalized
            }
        }
    }
    
    public enum InterestValidationError: LocalizedError {
        case tooManyInterests(maxAllowed: Int)
        case interestTooLong(maxLength: Int)
        case emptyInterest
        case invalidCharacters
        case duplicateInterests
        
        public var errorDescription: String? {
            switch self {
            case .tooManyInterests(let maxAllowed):
                return "Puedes seleccionar hasta \(maxAllowed) intereses como máximo."
            case .interestTooLong(let maxLength):
                return "Cada interés no puede tener más de \(maxLength) caracteres."
            case .emptyInterest:
                return "Los intereses no pueden estar vacíos."
            case .invalidCharacters:
                return "Solo se permiten letras, números, espacios y guiones en los intereses."
            case .duplicateInterests:
                return "No puedes tener intereses duplicados."
            }
        }
    }
    
    public enum InterestValidationResult {
        case success([String])
        case failure(InterestValidationError)
    }
}

// MARK: - Authentication Service
public final class AuthService: ObservableObject {
    public static let shared = AuthService()
    
    // MARK: - Published Properties
    // ✅ CORRECCIÓN: Cambiado de private(set) a público para permitir setter externo
    @Published public var user: AppUser?
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var phoneAuthState: PhoneAuthState = .idle
    @Published public private(set) var hasResolvedAuth: Bool = false
    
    // MARK: - Mock Data Flag
    
    /// Habilita o deshabilita el modo demo para el usuario Eliu.
    /// Cambiar a false cuando el desarrollo esté completo y se quiera ver data real incluso con este usuario.
    /// Cuando se elimine el código mock, buscar todas las referencias a `isMockUser` y eliminar la rama true.
    public static let enableMockModeForEliu = true
    
    /// Indica si el usuario actual es el usuario de demostración (Eliu) y el modo está activo.
    /// Si es true, la app debe usar datos hardcoded. Si es false, debe intentar usar datos reales.
    public var isMockUser: Bool {
        guard AuthService.enableMockModeForEliu else { return false }
        return user?.email?.lowercased() == "eliugiraldonavia2015@gmail.com"
    }

    private let followingCache = FollowingCache(capacity: 1024)
    private let followingStore = FollowingStore()
    
    // MARK: - Private Properties
    private let db = DatabaseService.shared.db
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var verificationID: String?
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                self?.updateAuthState(with: firebaseUser)
            }
        }
    }
    
    // ✅ CORREGIDO: Método público como se solicitó
    public func extractUsernameFromName(_ name: String?) -> String? {
        guard let name = name else { return nil }
        
        let username = name
            .lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .components(separatedBy: .whitespaces)
            .joined()
        
        return username.count >= 3 ? username : nil
    }
}

// MARK: - Public Refresh Method (para Onboarding)
extension AuthService {
    /// Refresca el estado de autenticación usando el usuario actual de Firebase.
    public func refreshAuthState() {
        let currentUser = Auth.auth().currentUser
        updateAuthState(with: currentUser)
    }
}

// MARK: - Phone Authentication
extension AuthService {
    public enum PhoneAuthState: Equatable {
        case idle
        case sendingCode
        case awaitingVerification(phoneNumber: String)
        case verified
        case error(String)
        
        public var isAwaitingCode: Bool {
            switch self {
            case .awaitingVerification, .sendingCode:
                return true
            default:
                return false
            }
        }
        
        public var canSendCode: Bool {
            switch self {
            case .idle, .error:
                return true
            default:
                return false
            }
        }
    }
    
    public func sendVerificationCode(phoneNumber: String, presentingVC: UIViewController) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        phoneAuthState = .sendingCode
        
        print("[AuthService] 🔄 Enviando código a: \(phoneNumber)")
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    let nsError = error as NSError
                    print("[AuthService] ❌ Error Firebase: \(error.localizedDescription)")
                    print("[AuthService] 🔍 Código: \(nsError.code), Dominio: \(nsError.domain)")
                    self.handlePhoneAuthError(error)
                    return
                }
                
                guard let verificationID = verificationID else {
                    print("[AuthService] ❌ Error: verificationID es nil")
                    self.phoneAuthState = .error("Error del servidor. Intenta nuevamente.")
                    return
                }
                
                self.verificationID = verificationID
                self.phoneAuthState = .awaitingVerification(phoneNumber: phoneNumber)
                print("[AuthService] ✅ Código enviado. Estado: awaitingVerification")
            }
        }
    }
    
    public func verifyCode(_ code: String) {
        guard !isLoading else { return }
        guard let verificationID = verificationID else {
            handleAuthError("No hay verificación activa. Solicita un nuevo código.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.handlePhoneAuthError(error)
                    return
                }
                
                guard let user = authResult?.user else {
                    self.handleAuthError("Error desconocido al verificar el código")
                    return
                }
                
                self.handlePhoneAuthenticationSuccess(user: user)
            }
        }
    }
    
    private func handlePhoneAuthenticationSuccess(user: User) {
        let isNewUser = user.metadata.creationDate == user.metadata.lastSignInDate
        
        if isNewUser {
            createUserProfileForPhoneAuth(user: user)
        } else {
            updateAuthState(with: user)
        }
        
        phoneAuthState = .verified
        self.verificationID = nil
    }
    
    private func createUserProfileForPhoneAuth(user: User) {
        let phoneNumber = user.phoneNumber ?? "unknown"
        let tempUsername = "user_\(user.uid.prefix(8))"
        let tempName = "Usuario \(user.uid.prefix(6))"
        
        DatabaseService.shared.createUserDocument(
            uid: user.uid,
            name: tempName,
            email: nil,
            username: tempUsername
        )
        DatabaseService.shared.createUsernameIndex(username: tempUsername, uid: user.uid, email: nil)
        
        self.user = AppUser(
            uid: user.uid,
            email: nil,
            name: tempName,
            username: tempUsername,
            phoneNumber: phoneNumber,
            photoURL: nil,
            interests: nil,
            role: nil,
            bio: nil,
            location: nil,
            onboardingCompleted: false
        )
        self.isAuthenticated = true
    }
    
    public func resetPhoneAuth() {
        phoneAuthState = .idle
        verificationID = nil
        errorMessage = nil
    }
}

// MARK: - Authentication Methods
extension AuthService {
    public enum LoginType {
        case email
        case username
        case phone
        case unknown
    }
    
    public func signInWithGoogle(presentingVC: UIViewController) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        resetPhoneAuth()
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { [weak self] signInResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleAuthError("Error de Google: \(error.localizedDescription)")
                return
            }
            
            guard let signInResult = signInResult,
                  let idToken = signInResult.user.idToken?.tokenString else {
                self.handleAuthError("Token de Google inválido")
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: signInResult.user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.handleAuthError("Error de Firebase: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    public func signInWithEmailOrUsername(identifier: String, password: String) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        resetPhoneAuth()
        
        if isValidEmail(identifier) {
            signInWithEmail(email: identifier, password: password)
        } else {
            DatabaseService.shared.getEmailForUsername(username: identifier) { [weak self] email in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    guard let email = email else {
                        self.handleAuthError("Usuario no encontrado")
                        return
                    }
                    self.signInWithEmail(email: email, password: password)
                }
            }
        }
    }
    
    private func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleSignInError(error)
                }
            }
        }
    }
    
    // ✅ MÉTODO ACTUALIZADO con validación de intereses y rol
    public func signUpWithEmail(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        username: String,
        phoneNumber: String? = nil,
        interests: [String]? = nil,
        role: String? = nil
    ) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        resetPhoneAuth()
        
        guard meetsMinimumPasswordRequirements(password) else {
            handleAuthError("La contraseña debe tener al menos 8 caracteres, incluyendo una mayúscula y una minúscula.")
            return
        }
        
        // ✅ Validación de intereses si se proporcionan
        if let interests = interests {
            let validationResult = InterestValidation.validateInterests(interests)
            switch validationResult {
            case .failure(let error):
                handleAuthError(error.localizedDescription)
                return
            case .success:
                // Intereses válidos, continuar
                break
            }
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleSignUpError(error)
                    return
                }
                
                guard let user = result?.user else {
                    self?.handleAuthError("Error desconocido al crear usuario")
                    return
                }
                
                self?.createUserProfileAfterEmailSignUp(
                    user: user,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    username: username,
                    phoneNumber: phoneNumber,
                    interests: interests,
                    role: role
                )
            }
        }
    }
    
    // ✅ Overload original mantenido para compatibilidad
    public func signUpWithEmail(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        username: String,
        phoneNumber: String? = nil
    ) {
        signUpWithEmail(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            username: username,
            phoneNumber: phoneNumber,
            interests: nil,
            role: nil
        )
    }
    
    // ✅ MÉTODO ACTUALIZADO para manejar intereses y rol
    private func createUserProfileAfterEmailSignUp(
        user: User,
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        phoneNumber: String?,
        interests: [String]?,
        role: String?
    ) {
        let fullName = "\(firstName) \(lastName)"
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        changeRequest.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[AuthService] Profile update error: \(error)")
                }
                
                // ✅ LLAMADA ACTUALIZADA para incluir rol
                DatabaseService.shared.createUserDocument(
                    uid: user.uid,
                    name: fullName,
                    email: email,
                    username: username,
                    role: role
                )
                DatabaseService.shared.createUsernameIndex(username: username, uid: user.uid, email: email)
                
                // ✅ Actualizar intereses DESPUÉS usando función existente
                if let interests = interests {
                    let validationResult = InterestValidation.validateInterests(interests)
                    if case .success(let validatedInterests) = validationResult {
                        let normalizedInterests = InterestValidation.normalizeInterests(validatedInterests)
                        
                        DatabaseService.shared.updateUserInterests(
                            uid: user.uid,
                            interests: normalizedInterests
                        ) { error in
                            if let error = error {
                                print("[AuthService] Error updating interests after signup: \(error)")
                            } else {
                                print("[AuthService] ✅ Interests updated successfully after signup")
                            }
                        }
                    }
                }
                
                self?.updateAuthState(with: user)
                self?.isLoading = false
            }
        }
    }
    
    // ✅ Overload original mantenido
    private func createUserProfileAfterEmailSignUp(
        user: User,
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        phoneNumber: String?
    ) {
        createUserProfileAfterEmailSignUp(
            user: user,
            email: email,
            firstName: firstName,
            lastName: lastName,
            username: username,
            phoneNumber: phoneNumber,
            interests: nil,
            role: nil
        )
    }
}

// MARK: - Interest Management Methods
extension AuthService {
    /// Actualiza los intereses del usuario con validación robusta
    public func updateUserInterests(_ interests: [String], completion: @escaping (Result<[String], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"])))
            return
        }
        
        // Validación robusta
        let validationResult = InterestValidation.validateInterests(interests)
        
        switch validationResult {
        case .failure(let error):
            completion(.failure(error))
            return
            
        case .success(let validatedInterests):
            let normalizedInterests = InterestValidation.normalizeInterests(validatedInterests)
            
            DatabaseService.shared.updateUserInterests(
                uid: currentUser.uid,
                interests: normalizedInterests
            ) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // Actualizar usuario local
                        if let currentUser = self.user {
                            self.user = AppUser(
                                uid: currentUser.uid,
                                email: currentUser.email,
                                name: currentUser.name,
                                username: currentUser.username,
                                phoneNumber: currentUser.phoneNumber,
                                photoURL: currentUser.photoURL,
                                interests: normalizedInterests,
                                role: currentUser.role // ✅ MANTENER el rol existente
                            )
                        }
                        completion(.success(normalizedInterests))
                    }
                }
            }
        }
    }
    
    /// Obtener intereses del usuario actual
    public func getCurrentUserInterests() -> [String] {
        return user?.interests ?? []
    }
    
    /// Verifica si un conjunto de intereses es válido sin actualizarlos
    public func validateInterests(_ interests: [String]) -> InterestValidationResult {
        return InterestValidation.validateInterests(interests)
    }
    
    /// Obtener intereses del usuario de forma segura usando funciones existentes
    private func fetchUserInterests(uid: String, completion: @escaping ([String]?) -> Void) {
        DatabaseService.shared.fetchUser(uid: uid) { result in
            switch result {
            case .success(let userData):
                let interests = userData["interests"] as? [String]
                completion(interests)
            case .failure:
                completion(nil)
            }
        }
    }
}

// MARK: - Validation Methods
extension AuthService {
    public func identifyLoginType(_ input: String) -> LoginType {
        if isValidEmail(input) {
            return .email
        } else if isValidUsername(input) {
            return .username
        } else if isValidPhoneNumber(input) {
            return .phone
        } else {
            return .unknown
        }
    }
    
    public func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    public func isValidUsername(_ username: String) -> Bool {
        let usernameRegEx = "^[a-zA-Z0-9.-]{3,30}$"
        let usernamePred = NSPredicate(format:"SELF MATCHES %@", usernameRegEx)
        return usernamePred.evaluate(with: username)
    }
    
    public func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegEx = "^\\+?[1-9]\\d{1,14}$"
        let phonePred = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
        let cleanedNumber = phoneNumber.replacingOccurrences(
            of: "[^0-9+]",
            with: "",
            options: .regularExpression
        )
        return phonePred.evaluate(with: cleanedNumber) && cleanedNumber.count >= 8
    }
    
    public func meetsMinimumPasswordRequirements(_ password: String) -> Bool {
        let hasUpperCase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowerCase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasMinimumLength = password.count >= 8
        return hasUpperCase && hasLowerCase && hasMinimumLength
    }
}

// MARK: - Password Strength Evaluation
extension AuthService {
    public func evaluatePasswordStrength(_ password: String, email: String? = nil, username: String? = nil) -> PasswordStrength {
        var score = 0
        var feedback = [PasswordStrength.PasswordFeedback]()
        
        let length = password.count
        switch length {
        case 16...:
            score += 25
            feedback.append(PasswordStrength.PasswordFeedback(type: .success, message: "Longitud excelente (16+ caracteres)"))
        case 12...15:
            score += 20
            feedback.append(PasswordStrength.PasswordFeedback(type: .success, message: "Longitud muy buena (12-15 caracteres)"))
        case 10...11:
            score += 15
            feedback.append(PasswordStrength.PasswordFeedback(type: .success, message: "Longitud buena (10-11 caracteres)"))
        case 8...9:
            score += 10
            feedback.append(PasswordStrength.PasswordFeedback(type: .warning, message: "Longitud mínima alcanzada (8-9 caracteres)"))
        default:
            score += 0
            feedback.append(PasswordStrength.PasswordFeedback(type: .error, message: "Longitud insuficiente (mínimo 8 caracteres)"))
        }
        
        let hasUpperCase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowerCase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>/?")) != nil
        
        var complexityPoints = 0
        if hasUpperCase {
            complexityPoints += 2
            feedback.append(PasswordStrength.PasswordFeedback(type: .requirementMet, message: "Incluye mayúsculas"))
        } else {
            feedback.append(PasswordStrength.PasswordFeedback(type: .requirementMissing, message: "Agregar mayúsculas mejora la seguridad"))
        }
        
        if hasLowerCase {
            complexityPoints += 2
            feedback.append(PasswordStrength.PasswordFeedback(type: .requirementMet, message: "Incluye minúsculas"))
        } else {
            feedback.append(PasswordStrength.PasswordFeedback(type: .requirementMissing, message: "Agregar minúsculas mejora la seguridad"))
        }
        
        if hasNumbers {
            complexityPoints += 3
            feedback.append(PasswordStrength.PasswordFeedback(type: .requirementMet, message: "Incluye números"))
        } else {
            feedback.append(PasswordStrength.PasswordFeedback(type: .requirementMissing, message: "Agregar números mejora significativamente la seguridad"))
        }
        
        if hasSpecialChars {
            complexityPoints += 4
            feedback.append(PasswordStrength.PasswordFeedback(type: .requirementMet, message: "Incluye caracteres especiales"))
        } else {
            feedback.append(PasswordStrength.PasswordFeedback(type: .requirementMissing, message: "Caracteres especiales (!@# etc.) maximizan la seguridad"))
        }
        
        score += complexityPoints
        
        let commonPatterns = ["123", "abc", "password", "qwerty", "iloveyou", "111", "000"]
        for pattern in commonPatterns {
            if password.lowercased().contains(pattern) {
                feedback.append(PasswordStrength.PasswordFeedback(type: .warning, message: "Contiene patrones comunes - considera cambiarlos"))
                break
            }
        }
        
        if let email = email, !email.isEmpty {
            let emailLocalPart = email.lowercased().components(separatedBy: "@").first ?? ""
            if !emailLocalPart.isEmpty && password.lowercased().contains(emailLocalPart) {
                feedback.append(PasswordStrength.PasswordFeedback(type: .info, message: "Evita usar partes de tu email para mayor seguridad"))
            }
        }
        
        if let username = username, !username.isEmpty {
            if password.lowercased().contains(username.lowercased()) {
                feedback.append(PasswordStrength.PasswordFeedback(type: .info, message: "Evita usar tu nombre de usuario para mayor seguridad"))
            }
        }
        
        if containsSequentialCharacters(password) {
            feedback.append(PasswordStrength.PasswordFeedback(type: .info, message: "Evita secuencias simples (abc, 123) para mayor seguridad"))
        }
        
        let strength: PasswordStrength.StrengthLevel
        let mainFeedback: PasswordStrength.PasswordFeedback
        
        switch score {
        case 35...:
            strength = .veryStrong
            mainFeedback = PasswordStrength.PasswordFeedback(
                type: .excellent,
                message: "¡Contraseña excelente! Cumple con estándares empresariales"
            )
        case 28..<35:
            strength = .strong
            mainFeedback = PasswordStrength.PasswordFeedback(
                type: .success,
                message: "Contraseña segura - adecuada para la mayoría de usos"
            )
        case 20..<28:
            strength = .medium
            mainFeedback = PasswordStrength.PasswordFeedback(
                type: .warning,
                message: "Contraseña aceptable - considera mejoras para mayor seguridad"
            )
        case 12..<20:
            strength = .weak
            mainFeedback = PasswordStrength.PasswordFeedback(
                type: .warning,
                message: "Contraseña básica - cumple requisitos mínimos"
            )
        default:
            strength = .veryWeak
            mainFeedback = PasswordStrength.PasswordFeedback(
                type: .error,
                message: "Contraseña muy débil - recomendamos mejoras"
            )
        }
        
        feedback.insert(mainFeedback, at: 0)
        
        return PasswordStrength(score: score, strength: strength, feedback: feedback)
    }
    
    private func containsSequentialCharacters(_ password: String) -> Bool {
        let sequentialPatterns = [
            "123", "234", "345", "456", "567", "678", "789",
            "abc", "bcd", "cde", "def", "efg", "fgh", "ghi", "hij", "ijk", "jkl", "klm", "lmn", "mno", "nop", "opq", "pqr", "qrs", "rst", "stu", "tuv", "uvw", "vwx", "wxy", "xyz"
        ]
        let lowercasedPassword = password.lowercased()
        return sequentialPatterns.contains { lowercasedPassword.contains($0) }
    }
}

// MARK: - Error Handling
extension AuthService {
    private func handleSignInError(_ error: Error) {
        let nsError = error as NSError
        let errorMessage: String
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            errorMessage = "Contraseña incorrecta"
        case AuthErrorCode.userNotFound.rawValue:
            errorMessage = "No existe una cuenta con este identificador"
        case AuthErrorCode.invalidEmail.rawValue:
            errorMessage = "El identificador no es válido"
        case AuthErrorCode.networkError.rawValue:
            errorMessage = "Error de conexión. Verifica tu conexión a internet"
        case AuthErrorCode.tooManyRequests.rawValue:
            errorMessage = "Demasiados intentos. Por favor, intenta más tarde"
        default:
            errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
        }
        
        handleAuthError(errorMessage)
    }
    
    private func handleSignUpError(_ error: Error) {
        let nsError = error as NSError
        let errorMessage: String
        
        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            errorMessage = "Este email ya está en uso"
        case AuthErrorCode.invalidEmail.rawValue:
            errorMessage = "El email no es válido"
        case AuthErrorCode.weakPassword.rawValue:
            errorMessage = "La contraseña no cumple los requisitos mínimos de seguridad."
        case AuthErrorCode.networkError.rawValue:
            errorMessage = "Error de conexión. Verifica tu conexión a internet"
        default:
            errorMessage = "Error al registrar: \(error.localizedDescription)"
        }
        
        handleAuthError(errorMessage)
    }
    
    private func handlePhoneAuthError(_ error: Error) {
        let nsError = error as NSError
        let errorMessage: String
        
        switch nsError.code {
        case AuthErrorCode.sessionExpired.rawValue:
            errorMessage = "El código de verificación expiró. Por favor, solicita uno nuevo."
        case AuthErrorCode.invalidVerificationCode.rawValue:
            errorMessage = "Código de verificación inválido. Verifica que sea correcto."
        case AuthErrorCode.quotaExceeded.rawValue:
            errorMessage = "Demasiados intentos recientes. Por favor, espera unos minutos e intenta nuevamente."
        case AuthErrorCode.networkError.rawValue:
            errorMessage = "Error de conexión. Verifica tu conexión a internet."
        case AuthErrorCode.missingPhoneNumber.rawValue:
            errorMessage = "Por favor, ingresa un número de teléfono válido."
        default:
            errorMessage = "Error en autenticación por teléfono: \(error.localizedDescription)"
        }
        
        phoneAuthState = .error(errorMessage)
        handleAuthError(errorMessage)
    }
    
    public func handleAuthError(_ message: String) {
        print("[AuthService Error] \(message)")
        DispatchQueue.main.async {
            self.errorMessage = message
            self.isLoading = false
        }
    }
}

// MARK: - User Management
extension AuthService {
    public func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            resetPhoneAuth()
            user = nil
            isAuthenticated = false
            
            // ✅ ANALYTICS: Limpiar identidad
            AnalyticsManager.shared.resetUser()
            
        } catch {
            handleAuthError("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
    
    private func updateAuthState(with firebaseUser: User?) {
        DispatchQueue.main.async {
            if let firebaseUser = firebaseUser {
                // ✅ ANALYTICS: Identificar usuario al iniciar sesión
                AnalyticsManager.shared.identifyUser(userId: firebaseUser.uid)
                
                // Verificar si existe documento de usuario
                DatabaseService.shared.userDocumentExists(uid: firebaseUser.uid) { exists in
                    if !exists {
                        // Crear documento si no existe
                        DatabaseService.shared.createUserDocument(
                            uid: firebaseUser.uid,
                            name: firebaseUser.displayName,
                            email: firebaseUser.email,
                            photoURL: firebaseUser.photoURL,
                            username: self.extractUsernameFromName(firebaseUser.displayName)
                        )
                    } else {
                        // Actualizar último login
                        DatabaseService.shared.updateLastLogin(uid: firebaseUser.uid)
                    }
                }
                
                DatabaseService.shared.fetchUser(uid: firebaseUser.uid) { result in
                    var interests: [String]? = nil
                    var userRole: String? = nil
                    var bio: String? = nil
                    var location: String? = nil
                    var photoURLFromFirestore: URL? = nil
                    var onboardingCompleted: Bool? = nil
                    if case .success(let userData) = result {
                        interests = userData["interests"] as? [String]
                        userRole = userData["role"] as? String
                        bio = userData["bio"] as? String
                        location = userData["location"] as? String
                         if let s = userData["photoURL"] as? String, !s.isEmpty {
                             photoURLFromFirestore = URL(string: s)
                         }
                        onboardingCompleted = userData["onboardingCompleted"] as? Bool
                    }
                    self.user = AppUser(
                        uid: firebaseUser.uid,
                        email: firebaseUser.email,
                        name: firebaseUser.displayName,
                        username: self.extractUsernameFromName(firebaseUser.displayName),
                        phoneNumber: firebaseUser.phoneNumber,
                        photoURL: photoURLFromFirestore ?? firebaseUser.photoURL,
                        interests: interests,
                        role: userRole,
                        bio: bio,
                        location: location,
                        onboardingCompleted: onboardingCompleted
                    )
                    let localList = self.followingStore.load(for: firebaseUser.uid)
                    for uid in localList { self.followingCache.set(uid, value: true) }
                    DatabaseService.shared.fetchFollowingUidsLimited(followerUid: firebaseUser.uid, limit: 256) { list in
                        DispatchQueue.main.async {
                            for uid in list { self.followingCache.set(uid, value: true) }
                        }
                    }
                    self.isAuthenticated = true
                    self.isLoading = false
                    self.hasResolvedAuth = true
                }
            } else {
                self.user = nil
                self.isAuthenticated = false
                self.isLoading = false
                self.hasResolvedAuth = true
            }
        }
    }
    
    public func updateUserProfile(name: String? = nil, photoURL: URL? = nil, phoneNumber: String? = nil) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        DatabaseService.shared.updateUserDocument(
            uid: currentUser.uid,
            name: name,
            photoURL: photoURL
        )
        
        if let name = name {
            // ✅ CORREGIDO: Usar el inicializador correcto con todos los parámetros
            self.user = AppUser(
                uid: currentUser.uid,
                email: self.user?.email,
                name: name,
                username: self.extractUsernameFromName(name),
                phoneNumber: phoneNumber ?? self.user?.phoneNumber,
                photoURL: photoURL ?? self.user?.photoURL,
                interests: self.user?.interests,
                role: self.user?.role // ✅ MANTENER rol existente
            )
        }
    }
}
