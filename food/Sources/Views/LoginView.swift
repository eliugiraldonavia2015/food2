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

// MARK: - Login View 3.0 (Modern, Vistoso & Comodo)
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
    @State private var backgroundOffset: CGFloat = 0
    
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Vivid Animated Background
                VividMeshBackground()
                    .ignoresSafeArea()
                    .onTapGesture { focusedField = nil }
                
                // 2. Main Content - Bottom Sheet Style
                VStack(spacing: 0) {
                    // Top Space / Logo Area
                    if focusedField == nil {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            BrandLogoView()
                                .scaleEffect(1.5)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                            
                            Text("FoodTook")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                            
                            Text(isSignUp ? "Únete a la revolución" : "El sabor te espera")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, 40)
                    }
                    
                    Spacer()
                    
                    // Glass Card Container
                    ZStack {
                        // Glass Background
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
                            .shadow(color: .black.opacity(0.15), radius: 30, y: -5)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 32) {
                                // Drag Handle
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 16)
                                
                                // Content Switcher
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
                    }
                    .frame(height: UIScreen.main.bounds.height * (focusedField == nil ? 0.65 : 0.9))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: focusedField)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                
                // 3. Success Animation Overlay
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
        }
    }
    
    // MARK: - Main Auth Content
    private var mainAuthContent: some View {
        VStack(spacing: 24) {
            // Toggle Switch
            AuthToggle(isSignUp: $isSignUp)
            
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
            
            // Divider
            HStack {
                VStack { Divider().background(Color.black.opacity(0.1)) }
                Text("O CONTINÚA CON")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                VStack { Divider().background(Color.black.opacity(0.1)) }
            }
            
            // Social Buttons
            HStack(spacing: 20) {
                SocialIconBtn(icon: "g.circle.fill", color: .red) { handleGoogleSignIn() }
                SocialIconBtn(icon: "apple.logo", color: .black) { /* Apple */ }
                SocialIconBtn(icon: "phone.circle.fill", color: .green) {
                    withAnimation { currentAuthFlow = .phone }
                }
            }
        }
    }
    
    // MARK: - Login Form
    private var loginForm: some View {
        VStack(spacing: 20) {
            AuthTextField(
                text: $emailOrUsername,
                placeholder: "Usuario o Email",
                icon: "person.fill",
                focusedField: $focusedField,
                fieldId: .emailOrUser
            )
            
            VStack(alignment: .trailing, spacing: 8) {
                AuthTextField(
                    text: $password,
                    placeholder: "Contraseña",
                    icon: "lock.fill",
                    isSecure: true,
                    focusedField: $focusedField,
                    fieldId: .password
                )
                
                Button(action: { withAnimation { isShowingForgotPassword = true } }) {
                    Text("¿Olvidaste tu contraseña?")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
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
                    placeholder: "Usuario (@ejemplo)",
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
            
            AuthTextField(text: $confirmPassword, placeholder: "Confirmar Contraseña", icon: "lock.shield", isSecure: true, focusedField: $focusedField, fieldId: .confirmPass)
            
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
            headerWithBack(title: "Acceso con Móvil") { currentAuthFlow = .main }
            
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
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)
                        
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
            headerWithBack(title: "Recuperar Cuenta") { isShowingForgotPassword = false }
            
            Text("Ingresa tu correo para recibir instrucciones.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            AuthTextField(text: $email, placeholder: "tucorreo@ejemplo.com", icon: "envelope", focusedField: $focusedField, fieldId: .email)
            
            BigGradientButton(title: "ENVIAR ENLACE", isLoading: auth.isLoading) {
                // Logic
            }
        }
    }
    
    private func headerWithBack(title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Button(action: { withAnimation { action() } }) {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.title)
                    .foregroundColor(.primary)
            }
            Spacer()
            Text(title).font(.headline.bold())
            Spacer()
            Color.clear.frame(width: 30)
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

// MARK: - Custom Components

struct VividMeshBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.black
            
            // Orbes animados
            GeometryReader { geo in
                Circle().fill(Color(red: 244/255, green: 37/255, blue: 123/255))
                    .frame(width: 350, height: 350)
                    .blur(radius: 100)
                    .offset(x: animate ? -50 : 150, y: animate ? -100 : -200)
                
                Circle().fill(Color.orange)
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: animate ? 150 : -50, y: animate ? 300 : 100)
                
                Circle().fill(Color.purple)
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: animate ? -100 : 200, y: animate ? 500 : 400)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

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
                .foregroundColor(focusedField.wrappedValue == fieldId ? .black : .gray)
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
        .padding()
        .background(Color.white.opacity(0.5)) // Semi-transparent white
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(focusedField.wrappedValue == fieldId ? Color.black : Color.clear, lineWidth: 1.5)
        )
        .focused(focusedField, equals: fieldId)
        .scaleEffect(focusedField.wrappedValue == fieldId ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: focusedField.wrappedValue)
        .foregroundColor(.black)
    }
}

struct BigGradientButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.headline.bold())
                        .tracking(1)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(colors: [Color(red: 244/255, green: 37/255, blue: 123/255), Color.orange], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.4), radius: 10, y: 5)
        }
    }
}

struct AuthToggle: View {
    @Binding var isSignUp: Bool
    
    var body: some View {
        HStack {
            AuthTab(title: "Log In", isSelected: !isSignUp) { withAnimation { isSignUp = false } }
            AuthTab(title: "Sign Up", isSelected: isSignUp) { withAnimation { isSignUp = true } }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct AuthTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(12)
                .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 2, y: 1)
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
                .frame(width: 50, height: 50)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
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
