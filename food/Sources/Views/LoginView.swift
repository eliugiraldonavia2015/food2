// food/food/Sources/Views/LoginView.swift
import SwiftUI
import GoogleSignIn
import UIKit
#if canImport(PhoneNumberKit)
import PhoneNumberKit
#endif

// MARK: - AuthFlow Enum
enum AuthFlow {
    case main
    case phone
}

// MARK: - Login View 4.0 (Clean Card Style)
struct LoginView: View {
    @StateObject private var auth = AuthService.shared
    
    // Form States
    @State private var emailOrUsername = ""
    @State private var password = ""
    @State private var email = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    
    // UI States
    @State private var isSignUp = false
    @State private var currentAuthFlow: AuthFlow = .main
    @State private var isShowingForgotPassword = false
    @State private var showSuccessAnimation = false
    
    // Validation
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isUsernameAvailable = true
    @State private var checkingUsername = false
    @State private var passwordStrength: PasswordStrength?
    
    // Focus
    @FocusState private var focusedField: AuthFocusField?
    enum AuthFocusField {
        case emailOrUser, password, firstName, lastName, email, username, confirmPass, phone, code
    }
    
    // Dependencies
    private let loginUseCase = LoginUseCase()
    private let signupUseCase = SignupUseCase()
    #if canImport(PhoneNumberKit)
    private let phoneNumberKit = PhoneNumberKit()
    #endif
    
    // Colors
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let brandOrange = Color.orange
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 1. Top Background Layer
                VStack(spacing: 0) {
                    brandPink
                        .ignoresSafeArea()
                        .frame(height: 0) // Hide pink background
                    Spacer()
                }
                .background(Color.white) // Bottom part white fallback
                
                // 2. Header Content (on Pink)
                VStack {
                    HStack {
                        if currentAuthFlow == .phone || isShowingForgotPassword {
                            Button(action: {
                                withAnimation {
                                    if currentAuthFlow == .phone { currentAuthFlow = .main }
                                    else { isShowingForgotPassword = false }
                                }
                            }) {
                                Image(systemName: "arrow.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                    .frame(height: 50)
                    
                    if focusedField == nil {
                        VStack(spacing: 8) {
                            Image("foodtook_isotipo_magenta") // Use new magenta logo
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .padding(.bottom, 10)
                            
                            Text("FoodTook")
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(brandPink) // Change text to pink
                            
                            Text(isSignUp ? "Crea tu cuenta" : "Bienvenido de nuevo")
                                .font(.headline)
                                .foregroundColor(.gray) // Change text to gray
                        }
                        .padding(.top, 20)
                        .transition(.scale.combined(with: .opacity))
                    }
                    Spacer()
                }
                .zIndex(1)
                
                // 3. White Card Content
                ZStack {
                    RoundedRectangle(cornerRadius: 35)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 20, y: -5)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // Drag Indicator
                            Capsule()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 4)
                                .padding(.top, 16)
                            
                            if currentAuthFlow == .phone {
                                phoneAuthContent
                            } else if isShowingForgotPassword {
                                forgotPasswordContent
                            } else {
                                mainAuthContent
                            }
                            
                            Spacer().frame(height: 50)
                        }
                        .padding(.horizontal, 24)
                    }
                    // Prevent scrolling from covering the rounded corners visually if bounced
                    .clipShape(RoundedRectangle(cornerRadius: 35))
                }
                .frame(height: UIScreen.main.bounds.height * (focusedField == nil ? 0.70 : 0.85)) // Card Height
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: focusedField)
                .zIndex(2)
                
                // 4. Success Overlay
                if showSuccessAnimation {
                    SuccessExplosionView()
                        .zIndex(100)
                }
            }
            .navigationBarHidden(true)
            .alert("Aviso", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    withAnimation { showSuccessAnimation = true }
                }
            }
            .onChange(of: auth.errorMessage) { _, error in
                if let error = error {
                    alertMessage = error
                    showAlert = true
                }
            }
            // Tap background to dismiss keyboard
            .onTapGesture {
                focusedField = nil
            }
        }
    }
    
    // MARK: - Main Auth Content
    private var mainAuthContent: some View {
        VStack(spacing: 24) {
            
            // Social Icons Row (Top of Card)
            HStack(spacing: 25) {
                SocialIconBtn(icon: "g.circle.fill", color: .red) { handleGoogleSignIn() }
                SocialIconBtn(icon: "apple.logo", color: .black) { /* Apple */ }
                SocialIconBtn(icon: "phone.circle.fill", color: .green) {
                    withAnimation { currentAuthFlow = .phone }
                }
            }
            .padding(.bottom, 10)
            
            // Toggle Login/Signup Text
            HStack {
                Text(isSignUp ? "Registrarse" : "Iniciar Sesión")
                    .font(.title2.bold())
                    .foregroundColor(.black)
                Spacer()
            }
            
            // Forms
            Group {
                if isSignUp {
                    signUpForm
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    loginForm
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            
            // Bottom Switcher
            Button(action: { withAnimation { isSignUp.toggle() } }) {
                HStack {
                    Text(isSignUp ? "¿Ya tienes cuenta?" : "¿No tienes cuenta?")
                        .foregroundColor(.gray)
                    Text(isSignUp ? "Inicia Sesión" : "Regístrate")
                        .fontWeight(.bold)
                        .foregroundColor(brandPink)
                }
                .font(.subheadline)
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Login Form
    private var loginForm: some View {
        VStack(spacing: 20) {
            AuthTextField(
                text: $emailOrUsername,
                placeholder: "Usuario o Email",
                icon: "person",
                focusedField: $focusedField,
                fieldId: .emailOrUser
            )
            
            VStack(alignment: .trailing, spacing: 8) {
                AuthTextField(
                    text: $password,
                    placeholder: "Contraseña",
                    icon: "lock",
                    isSecure: true,
                    focusedField: $focusedField,
                    fieldId: .password
                )
                
                Button(action: { withAnimation { isShowingForgotPassword = true } }) {
                    Text("¿Olvidaste tu contraseña?")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
            }
            
            BigGradientButton(title: "INICIAR SESIÓN", isLoading: auth.isLoading) {
                Task { await loginUseCase.signIn(identifier: emailOrUsername, password: password) }
            }
            .disabled(emailOrUsername.isEmpty || password.isEmpty)
            .opacity(emailOrUsername.isEmpty || password.isEmpty ? 0.6 : 1)
        }
    }
    
    // MARK: - Sign Up Form
    private var signUpForm: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                AuthTextField(text: $firstName, placeholder: "Nombre", icon: "person", focusedField: $focusedField, fieldId: .firstName)
                AuthTextField(text: $lastName, placeholder: "Apellido", icon: "person", focusedField: $focusedField, fieldId: .lastName)
            }
            
            AuthTextField(text: $email, placeholder: "Correo Electrónico", icon: "envelope", focusedField: $focusedField, fieldId: .email)
            
            VStack(spacing: 4) {
                AuthTextField(
                    text: $username,
                    placeholder: "Usuario",
                    icon: "at",
                    focusedField: $focusedField,
                    fieldId: .username,
                    isValid: isUsernameAvailable && !username.isEmpty
                )
                .onChange(of: username) { _, val in checkUsernameAvailability(val) }
                
                if !username.isEmpty && !isUsernameAvailable {
                    Text("Usuario no disponible")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                }
            }
            
            VStack(spacing: 4) {
                AuthTextField(text: $password, placeholder: "Contraseña", icon: "lock", isSecure: true, focusedField: $focusedField, fieldId: .password)
                    .onChange(of: password) { _, val in
                        passwordStrength = auth.evaluatePasswordStrength(val, email: email, username: username)
                    }
                
                if let strength = passwordStrength {
                    PasswordStrengthLine(strength: strength)
                }
            }
            
            AuthTextField(text: $confirmPassword, placeholder: "Confirmar", icon: "lock.shield", isSecure: true, focusedField: $focusedField, fieldId: .confirmPass)
            
            BigGradientButton(title: "CREAR CUENTA", isLoading: auth.isLoading) {
                registerUser()
            }
            .disabled(!isSignUpFormValid)
            .opacity(isSignUpFormValid ? 1 : 0.6)
        }
    }
    
    // MARK: - Phone & Forgot Password
    private var phoneAuthContent: some View {
        VStack(spacing: 24) {
            Text("Acceso con Móvil")
                .font(.title2.bold())
                .foregroundColor(.black)
            
            if auth.phoneAuthState.isAwaitingCode {
                VStack(spacing: 20) {
                    Text("Código enviado a \(phoneNumber)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    AuthTextField(text: $verificationCode, placeholder: "123456", icon: "key", focusedField: $focusedField, fieldId: .code)
                        .keyboardType(.numberPad)
                    
                    BigGradientButton(title: "VERIFICAR", isLoading: auth.isLoading) {
                        auth.verifyCode(verificationCode)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Text("🇪🇨 +593")
                            .font(.headline)
                            .padding()
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(30)
                        
                        AuthTextField(text: $phoneNumber, placeholder: "99 999 9999", icon: "phone", focusedField: $focusedField, fieldId: .phone)
                            .keyboardType(.numberPad)
                    }
                    
                    BigGradientButton(title: "ENVIAR CÓDIGO", isLoading: auth.isLoading) {
                        sendVerificationCode()
                    }
                }
            }
        }
    }
    
    private var forgotPasswordContent: some View {
        VStack(spacing: 24) {
            Text("Recuperar Cuenta")
                .font(.title2.bold())
                .foregroundColor(.black)
            
            Text("Ingresa tu correo para recibir instrucciones.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            AuthTextField(text: $email, placeholder: "tucorreo@ejemplo.com", icon: "envelope", focusedField: $focusedField, fieldId: .email)
            
            BigGradientButton(title: "ENVIAR ENLACE", isLoading: auth.isLoading) {
                // Logic placeholder
            }
        }
    }
    
    // MARK: - Logic
    private func checkUsernameAvailability(_ username: String) {
        guard !username.isEmpty else { return }
        checkingUsername = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            DatabaseService.shared.isUsernameAvailable(username) { result in
                DispatchQueue.main.async {
                    if case .success(let available) = result { self.isUsernameAvailable = available }
                    else { self.isUsernameAvailable = false }
                    self.checkingUsername = false
                }
            }
        }
    }
    
    private func sendVerificationCode() {
        let fullNumber = "+593" + phoneNumber.filter { $0.isNumber }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        auth.sendVerificationCode(phoneNumber: fullNumber, presentingVC: rootViewController)
    }
    
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        auth.signInWithGoogle(presentingVC: rootViewController)
    }
    
    private func registerUser() {
        Task { await signupUseCase.signUp(email: email, password: password, firstName: firstName, lastName: lastName, username: username) }
    }
    
    private var isSignUpFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !firstName.isEmpty && !username.isEmpty && password == confirmPassword
    }
}

// MARK: - Custom Components (Clean Pill Style)

struct AuthTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    var focusedField: FocusState<LoginView.AuthFocusField?>.Binding
    var fieldId: LoginView.AuthFocusField
    var isValid: Bool? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(focusedField.wrappedValue == fieldId ? Color(red: 244/255, green: 37/255, blue: 123/255) : .gray)
                .font(.system(size: 18))
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            
            if let valid = isValid {
                Image(systemName: valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(valid ? .green : .red)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(uiColor: .systemGray6)) // Light gray background
        .clipShape(Capsule()) // Pill shape
        .overlay(
            Capsule()
                .stroke(focusedField.wrappedValue == fieldId ? Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .focused(focusedField, equals: fieldId)
        .foregroundColor(.black)
    }
}

struct BigGradientButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    // Brand Colors
    private let brandPink = Color(red: 244/255.0, green: 37/255.0, blue: 123/255.0)
    private let brandOrange = Color.orange
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProfessionalSpinner()
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text(title)
                        .font(.headline.bold())
                        .tracking(1)
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            // Morphing Geometry
            .frame(width: isLoading ? 56 : nil, height: 56)
            .frame(maxWidth: isLoading ? 56 : .infinity)
            .background(
                ZStack {
                    if isLoading {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
                    } else {
                        LinearGradient(colors: [brandPink, brandOrange], startPoint: .leading, endPoint: .trailing)
                            .clipShape(Capsule())
                    }
                }
            )
            // Animations
            .clipShape(Capsule())
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isLoading)
            .shadow(color: isLoading ? .clear : brandPink.opacity(0.4), radius: 10, y: 5)
        }
        .disabled(isLoading)
    }
}

struct ProfessionalSpinner: View {
    @State private var isAnimating = false
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    var body: some View {
        ZStack {
            // Outer Ring (Gradient)
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [brandPink, brandPink.opacity(0.3)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 32, height: 32)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1.0)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            // Inner Ring (Counter-rotating)
            Circle()
                .trim(from: 0, to: 0.6)
                .stroke(
                    brandPink.opacity(0.5),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 18, height: 18)
                .rotationEffect(Angle(degrees: isAnimating ? -360 : 0))
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .onAppear {
            DispatchQueue.main.async {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

struct SocialIconBtn: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(Color(uiColor: .systemGray6))
                .clipShape(Circle())
        }
    }
}

// MARK: - Success Animation
struct SuccessExplosionView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -45
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            // Confetti or abstract shapes
            ForEach(0..<10) { i in
                Circle()
                    .fill(colors.randomElement()!)
                    .frame(width: CGFloat.random(in: 10...30))
                    .offset(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -300...300))
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            
            VStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 244/255, green: 37/255, blue: 123/255), Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                
                Text("¡Bienvenido!")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                scale = 1.0
                opacity = 1.0
                rotation = 0
            }
        }
    }
    
    let colors: [Color] = [.red, .orange, .purple, .pink, .yellow]
}

struct PasswordStrengthLine: View {
    let strength: PasswordStrength
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(strength.strength.uiProgressValue * 4) ? strength.strength.uiColor : Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Extensions Recovery
fileprivate extension PasswordStrength.StrengthLevel {
    var uiColor: Color {
        switch self.colorIdentifier {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        default: return .gray
        }
    }
    
    var uiProgressValue: CGFloat {
        return CGFloat(self.progressValue)
    }
}
