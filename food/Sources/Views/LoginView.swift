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

// MARK: - UI Helper Extensions
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

// MARK: - Focus Field Enum
private enum FocusField: Hashable {
    case firstName, lastName, email, emailOrUsername, username, password, confirmPassword, phone, phoneVerificationCode
}

// MARK: - Main Login View
struct LoginView: View {
    @StateObject private var auth = AuthService.shared
    @State private var emailOrUsername = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var isUsernameAvailable = true
    @State private var checkingUsername = false
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isShowingSignUp = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var canResendCode = false
    @State private var resendTimer = 60
    @State private var resendTimerTask: Task<Void, Never>?
    
    @State private var timerStartTime: Date?
    @State private var backgroundTime: Date?
    
    @State private var passwordStrength: PasswordStrength?
    @State private var loginType: AuthService.LoginType = .unknown
    
    @State private var currentAuthFlow: AuthFlow = .main
    @State private var isShowingForgotPassword = false
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    @FocusState private var focusedField: FocusField?
    private let loginUseCase = LoginUseCase()
    private let signupUseCase = SignupUseCase()
    #if canImport(PhoneNumberKit)
    private let phoneNumberKit = PhoneNumberKit()
    private lazy var partialFormatter = PartialFormatter(phoneNumberKit: phoneNumberKit, defaultRegion: "EC")
    #endif
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Nuevo diseño con fondo animado
                if currentAuthFlow == .phone {
                    phoneAuthFlowView
                } else if isShowingForgotPassword {
                    forgotPasswordView
                } else {
                    mainAuthView
                }
            }
            .background(.black)
            .preferredColorScheme(.dark)
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    showAlert = false
                }
            } message: {
                Text(alertMessage)
            }
            .overlay(
                Group {
                    if auth.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(1.5)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
                .edgesIgnoringSafeArea(.all)
                .opacity(auth.isLoading ? 1 : 0)
            )
            .onReceive(auth.$errorMessage) { errorMessage in
                if let error = errorMessage {
                    alertMessage = error
                    showAlert = true
                }
            }
            .onChange(of: isShowingSignUp) { _, _ in
                resetSignUpFields()
            }
            .onChange(of: auth.phoneAuthState) { oldState, newState in
                handlePhoneAuthStateChange(newState)
            }
            .onDisappear {
                resendTimerTask?.cancel()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                handleAppBackground()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                handleAppForeground()
            }
        }
    }
    
    // MARK: - Nuevo Main Auth View con diseño FoodFeed
    private var mainAuthView: some View {
        ZStack(alignment: .top) {
            // Background Image
            GeometryReader { geometry in
                AsyncImage(url: URL(string: "https://images.pexels.com/photos/1640772/pexels-photo-1640772.jpeg")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.4) // Reduced height
                        .clipped()
                } placeholder: {
                    Color.gray
                }
            }
            .ignoresSafeArea()
            
            // White Container Bottom Sheet
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 120) // Push down the sheet even more
                
                ZStack(alignment: .top) {
                    // White Background
                    Color.white
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                        .ignoresSafeArea(edges: .bottom)
                    
                    // Content
                    VStack(spacing: 0) { // Changed spacing to 0, handling it in child views
                        Spacer().frame(height: 40) // Space for Logo overlap
                        
                        // Header Text
                        VStack(spacing: 8) {
                            Text("FoodTook")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)
                            
                            Text(isShowingSignUp ? "Join the food revolution." : "Welcome Back!")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black.opacity(0.8))
                            
                            if !isShowingSignUp {
                                Text("Login to continue your tasty journey.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 30) // Add padding after header
                        
                        // Scrollable Content
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 30) {
                                // Form
                                if isShowingSignUp {
                                    signUpFormView
                                } else {
                                    signInFormView
                                }
                                
                                // Social Login
                                VStack(spacing: 20) {
                                    HStack {
                                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                        Text(isShowingSignUp ? "OR CONTINUE WITH" : "Or login with")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 8)
                                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                    }
                                    
                                    HStack(spacing: 20) {
                                        // Google
                                        Button(action: {
                                            handleGoogleSignIn()
                                        }) {
                                            CircularSocialButton(icon: "g.circle.fill", color: .red) // Placeholder symbol
                                        }
                                        
                                        // Apple
                                        Button(action: {}) {
                                            CircularSocialButton(icon: "apple.logo", color: .black)
                                        }
                                        
                                        // Phone
                                        Button(action: {
                                            withAnimation {
                                                currentAuthFlow = .phone
                                            }
                                        }) {
                                            CircularSocialButton(icon: "phone.fill", color: .green)
                                        }
                                    }
                                }
                                
                                // Toggle
                                HStack {
                                    Text(isShowingSignUp ? "Already have an account?" : "Don't have an account?")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) { // Optimized animation duration
                                            isShowingSignUp.toggle()
                                        }
                                    }) {
                                        Text(isShowingSignUp ? "Log in" : "Sign up")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(fuchsiaColor)
                                    }
                                }
                                .padding(.bottom, 30)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    // Logo (Floating)
                    BrandLogoView()
                        .offset(y: -50) // Adjust overlap
                }
                .frame(maxHeight: .infinity)
            }
            
            // Back Button (Top Left)
            VStack {
                HStack {
                    Button(action: {
                        // Action for back button
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }
    
    struct GoogleBrandView: UIViewRepresentable {
        func makeUIView(context: Context) -> GIDSignInButton {
            let button = GIDSignInButton()
            return button
        }
        func updateUIView(_ uiView: GIDSignInButton, context: Context) {}
    }
    
    // MARK: - Nuevo Sign In Form
    private var signInFormView: some View {
        VStack(spacing: 16) {
            // Email/Username Field
            CustomTextField(
                text: $emailOrUsername,
                placeholder: "Email or Username",
                icon: "envelope",
                isSecure: false,
                isAvailable: nil,
                isChecking: false
            )
            .focused($focusedField, equals: .emailOrUsername)
            .onChange(of: emailOrUsername) { _, newValue in
                loginType = auth.identifyLoginType(newValue)
            }
            
            // Password Field
            VStack(alignment: .trailing, spacing: 8) {
                CustomTextField(
                    text: $password,
                    placeholder: "Password",
                    icon: "lock",
                    isSecure: true,
                    isAvailable: nil,
                    isChecking: false
                )
                .focused($focusedField, equals: .password)
                
                Button("Forgot Password?") {
                    isShowingForgotPassword = true
                }
                .font(.caption)
                .foregroundColor(fuchsiaColor)
                .fontWeight(.bold)
            }
            
            // Login Button
            Button(action: {
                Task { await loginUseCase.signIn(identifier: emailOrUsername, password: password) }
            }) {
                HStack {
                    Text("Log In")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(fuchsiaColor)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: fuchsiaColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .allowsHitTesting(isSignInFormValid && !auth.isLoading)
            .opacity(isSignInFormValid ? 1 : 0.7)
        }
    }
    
    // MARK: - Nuevo Sign Up Form
    private var signUpFormView: some View {
        VStack(spacing: 16) {
            // Personal Information
            HStack(spacing: 12) {
                CustomTextField(
                    text: $firstName,
                    placeholder: "First Name",
                    icon: "person",
                    isSecure: false,
                    isAvailable: nil,
                    isChecking: false
                )
                .focused($focusedField, equals: .firstName)
                .id(FocusField.firstName)
                
                CustomTextField(
                    text: $lastName,
                    placeholder: "Last Name",
                    icon: "person",
                    isSecure: false,
                    isAvailable: nil,
                    isChecking: false
                )
                .focused($focusedField, equals: .lastName)
                .id(FocusField.lastName)
            }
            
            // Email Field
            CustomTextField(
                text: $email,
                placeholder: "Email Address",
                icon: "envelope",
                isSecure: false,
                isAvailable: nil,
                isChecking: false
            )
            .focused($focusedField, equals: .email)
            .id(FocusField.email)
            
            // Username Field with Availability Check
            CustomTextField(
                text: $username,
                placeholder: "Username",
                icon: "at",
                isSecure: false,
                isAvailable: isUsernameAvailable,
                isChecking: checkingUsername
            )
            .focused($focusedField, equals: .username)
            .id(FocusField.username)
            
            usernameValidationView
            
            // Password Field
            VStack(alignment: .leading, spacing: 10) {
                CustomTextField(
                    text: $password,
                    placeholder: "Password",
                    icon: "lock",
                    isSecure: true,
                    isAvailable: nil,
                    isChecking: false
                )
                .focused($focusedField, equals: .password)
                .id(FocusField.password)
                .onChange(of: password) { _, newPass in
                    passwordStrength = auth.evaluatePasswordStrength(newPass, email: email, username: username)
                }
                
                if let strength = passwordStrength {
                    PasswordStrengthView(strength: strength)
                        .background(Color.gray.opacity(0.15)) // Increased opacity for better contrast
                        .cornerRadius(8)
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 5) {
                CustomTextField(
                    text: $confirmPassword,
                    placeholder: "Confirm Password",
                    icon: "checkmark.shield",
                    isSecure: true,
                    isAvailable: nil,
                    isChecking: false
                )
                .focused($focusedField, equals: .confirmPassword)
                .id(FocusField.confirmPassword)
                
                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 12)
                }
            }
            
            // Register Button
            Button(action: registerUser) {
                HStack {
                    Text("Sign Up")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(fuchsiaColor)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: fuchsiaColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .allowsHitTesting(isSignUpFormValid && !auth.isLoading)
            .opacity(isSignUpFormValid ? 1 : 0.7)
            .padding(.top)
            
            if !password.isEmpty {
                minimumRequirementsView
            }
        }
    }
    
    // MARK: - Forgot Password View
    private var forgotPasswordView: some View {
        ZStack(alignment: .top) {
            // Background Image (Same as Main)
            GeometryReader { geometry in
                AsyncImage(url: URL(string: "https://images.pexels.com/photos/1640772/pexels-photo-1640772.jpeg")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                        .clipped()
                } placeholder: {
                    Color.gray
                }
            }
            .ignoresSafeArea()
            
            // White Container Bottom Sheet
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 120)
                
                ZStack(alignment: .top) {
                    // White Background
                    Color.white
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                        .ignoresSafeArea(edges: .bottom)
                    
                    // Content
                    VStack(spacing: 0) {
                        Spacer().frame(height: 40) // Space for Logo overlap
                        
                        // Header Text
                        VStack(spacing: 8) {
                            Text("FoodTook")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)
                            
                            Text("Olvidé Contraseña")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black.opacity(0.8))
                            
                            Text("Ingresa tu correo electrónico y te enviaremos un enlace para recuperar tu acceso.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }
                        .padding(.bottom, 40)
                        
                        // Form
                        VStack(spacing: 24) {
                            CustomTextField(
                                text: $email,
                                placeholder: "Correo electrónico",
                                icon: "envelope",
                                isSecure: false,
                                isAvailable: nil,
                                isChecking: false
                            )
                            
                            Button(action: {
                                // Action placeholder
                            }) {
                                HStack {
                                    Text("Enviar")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(fuchsiaColor)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .shadow(color: fuchsiaColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        // Back Button
                        Button(action: {
                            isShowingForgotPassword = false
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Volver a Iniciar Sesión")
                            }
                            .foregroundColor(.black)
                            .font(.system(size: 16))
                        }
                        .padding(.bottom, 40)
                    }
                    
                    // Logo (Floating)
                    BrandLogoView()
                        .offset(y: -50)
                }
                .frame(maxHeight: .infinity)
            }
            
            // Top Left Back Button
            VStack {
                HStack {
                    Button(action: {
                        isShowingForgotPassword = false
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }

    // MARK: - Phone Auth Flow (manteniendo la funcionalidad existente)
    private var phoneAuthFlowView: some View {
        VStack(spacing: 20) {
            phoneAuthHeader
            
            if auth.phoneAuthState.isAwaitingCode {
                phoneVerificationView
            } else {
                phoneNumberInputView
            }
            
            Spacer()
            
            if !auth.phoneAuthState.isAwaitingCode {
                backToMainLoginButton
            }
        }
        .padding()
        .background(.black)
    }
    
    private var phoneAuthHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "phone.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Iniciar con Teléfono")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Ingresa tu número para recibir un código de verificación")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var phoneNumberInputView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Número de teléfono")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("+593")
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    
                    TextField("99 123 4567", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .onChange(of: phoneNumber) { _, newValue in
                            formatPhoneNumber(newValue)
                        }
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                if !phoneNumber.isEmpty && !isValidPhoneNumber {
                    Text("Por favor ingresa un número válido")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Button(action: sendPhoneVerificationCode) {
                HStack {
                    if auth.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "message.fill")
                    }
                    
                    Text("Enviar código SMS")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidPhoneNumber ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!isValidPhoneNumber || auth.isLoading)
            
            Text("Pueden aplicarse cargos por mensajes de texto")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var phoneVerificationView: some View {
        VStack(spacing: 20) {
            verificationHeader
            
            verificationCodeField
            
            resendTimerView
            
            resendCodeButton
        }
        .padding()
    }
    
    private var verificationHeader: some View {
        VStack(spacing: 8) {
            Text("Verificación por SMS")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if case .awaitingVerification(let phoneNumber) = auth.phoneAuthState {
                Text("Hemos enviado un código de 6 dígitos a:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(phoneNumber)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            } else {
                Text("Hemos enviado un código de 6 dígitos a tu teléfono")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .multilineTextAlignment(.center)
    }
    
    private var verificationCodeField: some View {
        TextField("Código de verificación", text: $verificationCode)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($focusedField, equals: .phoneVerificationCode)
            .onChange(of: verificationCode) { _, newValue in
                let filtered = newValue.filter { $0.isNumber }
                if filtered.count > 6 {
                    verificationCode = String(filtered.prefix(6))
                } else {
                    verificationCode = filtered
                }
                
                if verificationCode.count == 6 {
                    auth.verifyCode(verificationCode)
                }
            }
    }
    
    private var resendTimerView: some View {
        Group {
            if !canResendCode {
                Text("Puedes reenviar el código en \(resendTimer) segundos")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var resendCodeButton: some View {
        Button(action: handleResendCode) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Reenviar código")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canResendCode ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(!canResendCode || auth.isLoading)
    }
    
    private var backToMainLoginButton: some View {
        Button(action: {
            withAnimation {
                currentAuthFlow = .main
            }
        }) {
            Text("← Volver a otras opciones")
                .foregroundColor(.blue)
                .font(.subheadline)
        }
    }
    
    // MARK: - Component Subviews (manteniendo la funcionalidad)
    private var usernameValidationView: some View {
        VStack(alignment: .leading) {
            if !username.isEmpty {
                if checkingUsername {
                    Text("Verificando disponibilidad...")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if isUsernameAvailable {
                    Text("Nombre de usuario disponible")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Nombre de usuario no disponible")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .onChange(of: username) { _, newUsername in
            guard !newUsername.isEmpty else {
                isUsernameAvailable = true
                checkingUsername = false
                return
            }
            checkUsernameAvailability(newUsername)
        }
    }
    
    private var minimumRequirementsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Requisitos mínimos:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.black) // Changed to black
            
            HStack(alignment: .top) {
                Image(systemName: meetsMinimumRequirements ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(meetsMinimumRequirements ? .green : .gray)
                Text("8+ caracteres, 1 mayúscula, 1 minúscula")
                    .font(.caption)
                    .foregroundColor(.black) // Changed to black
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(meetsMinimumRequirements ? Color.green : Color.gray, lineWidth: 1)
                .background(Color.gray.opacity(0.15)) // Increased opacity for better contrast
        )
    }
    
    // MARK: - Password Strength Component (sin cambios)
    private struct PasswordStrengthView: View {
        let strength: PasswordStrength
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Nivel de seguridad")
                            .font(.caption)
                            .foregroundColor(.black) // Changed to black
                        
                        Text(strength.strength.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(strength.strength.uiColor)
                    }
                    
                    Spacer()
                    
                    Text("\(strength.score)/40")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.black) // Changed to black
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(strength.strength.uiColor.opacity(0.2))
                        .cornerRadius(8)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(height: 6)
                            .foregroundColor(.gray.opacity(0.3))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .frame(
                                width: geometry.size.width * strength.strength.uiProgressValue,
                                height: 6
                            )
                            .foregroundColor(strength.strength.uiColor)
                    }
                }
                .frame(height: 6)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(strength.feedback.prefix(4).enumerated()), id: \.offset) { _, feedback in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: iconForFeedback(feedback))
                                .font(.caption2)
                                .foregroundColor(colorForFeedback(feedback))
                                .padding(.top, 2)
                            
                            Text(feedback.message)
                                .font(.caption)
                                .foregroundColor(.black) // Changed to black
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            // Removed internal background to allow parent to control it or keep it transparent
        }
        
        private func iconForFeedback(_ feedback: PasswordStrength.PasswordFeedback) -> String {
            let message = feedback.message
            if message.contains("🎉") || message.contains("✅") {
                return "star.fill"
            } else if message.contains("✓") {
                return "checkmark.circle.fill"
            } else if message.contains("⚠️") {
                return "exclamationmark.triangle.fill"
            } else if message.contains("💡") {
                return "lightbulb.fill"
            } else {
                return "info.circle.fill"
            }
        }
        
        private func colorForFeedback(_ feedback: PasswordStrength.PasswordFeedback) -> Color {
            let message = feedback.message
            if message.contains("🎉") || message.contains("✅") || message.contains("✓") {
                return .green
            } else if message.contains("⚠️") {
                return .orange
            } else if message.contains("💡") {
                return .blue
            } else {
                return .black
            }
        }
    }
    
    // MARK: - Computed Properties (sin cambios)
    private var loginTypeColor: Color {
        switch loginType {
        case .email: return .green
        case .username: return .blue
        case .phone: return .purple
        case .unknown: return .gray
        }
    }
    
    private var loginTypeMessage: String {
        switch loginType {
        case .email: return "Identificador de tipo: email"
        case .username: return "Identificador de tipo: nombre de usuario"
        case .phone: return "Identificador de tipo: teléfono"
        case .unknown: return ""
        }
    }
    
    private var passwordsMatch: Bool {
        !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    private var borderColor: Color {
        if confirmPassword.isEmpty {
            return Color.gray
        } else if passwordsMatch {
            return Color.green
        } else {
            return Color.red
        }
    }
    
    private var meetsMinimumRequirements: Bool {
        auth.meetsMinimumPasswordRequirements(password)
    }
    
    private var isSignInFormValid: Bool {
        !emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }
    
    private var isSignUpFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        auth.isValidEmail(email) &&
        !password.isEmpty &&
        password == confirmPassword &&
        meetsMinimumRequirements &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isUsernameAvailable
    }
    
    private var isValidPhoneNumber: Bool {
        #if canImport(PhoneNumberKit)
        let digits = phoneNumber.filter { $0.isNumber }
        let fullNumber = "+593" + digits
        return (try? phoneNumberKit.parse(fullNumber, withRegion: "EC")) != nil
        #else
        let fullNumber = "+593\(phoneNumber.filter { $0.isNumber })"
        return auth.isValidPhoneNumber(fullNumber) && phoneNumber.count >= 8
        #endif
    }
    
    // MARK: - Helper Methods (sin cambios)
    private func resetSignUpFields() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        username = ""
        isUsernameAvailable = true
        checkingUsername = false
        passwordStrength = nil
        focusedField = nil
        loginType = .unknown
    }
    
    private func registerUser() {
        guard isSignUpFormValid else { return }
        Task { await signupUseCase.signUp(email: email, password: password, firstName: firstName, lastName: lastName, username: username) }
    }
    
    private func checkUsernameAvailability(_ username: String) {
        checkingUsername = true
        isUsernameAvailable = false
        
        DatabaseService.shared.isUsernameAvailable(username) { result in
            DispatchQueue.main.async {
                self.checkingUsername = false
                switch result {
                case .success(let isAvailable):
                    self.isUsernameAvailable = isAvailable
                case .failure(let error):
                    print("Error checking username: \(error)")
                    self.isUsernameAvailable = false
                    self.alertMessage = "Error verificando nombre de usuario: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ input: String) {
        #if canImport(PhoneNumberKit)
        let digits = input.filter { $0.isNumber }
        phoneNumber = partialFormatter.formatPartial(digits)
        #else
        let numbers = input.filter { $0.isNumber }
        if numbers.count <= 9 {
            var formatted = ""
            let count = numbers.count
            if count > 0 { formatted = String(numbers.prefix(2)) }
            if count > 2 { formatted += " " + String(numbers.dropFirst(2).prefix(3)) }
            if count > 5 { formatted += " " + String(numbers.dropFirst(5).prefix(4)) }
            phoneNumber = formatted
        } else {
            phoneNumber = String(numbers.prefix(9))
        }
        #endif
    }
    
    private func sendPhoneVerificationCode() {
        guard isValidPhoneNumber else { return }
        
        let fullNumber = "+593\(phoneNumber.filter { $0.isNumber })"
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            auth.handleAuthError("No se pudo obtener el contexto de la ventana")
            return
        }
        
        auth.sendVerificationCode(phoneNumber: fullNumber, presentingVC: rootViewController)
        setupResendTimer()
    }
    
    private func handleResendCode() {
        guard canResendCode else { return }
        sendPhoneVerificationCode()
    }
    
    private func setupResendTimer() {
        resendTimerTask?.cancel()
        canResendCode = false
        resendTimer = 60
        timerStartTime = Date()
        
        resendTimerTask = Task {
            while resendTimer > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                
                await MainActor.run {
                    resendTimer -= 1
                    if resendTimer <= 0 {
                        canResendCode = true
                        timerStartTime = nil
                    }
                }
            }
        }
    }
    
    private func handleAppBackground() {
        backgroundTime = Date()
        resendTimerTask?.cancel()
    }
    
    private func handleAppForeground() {
        guard let backgroundTime = backgroundTime,
              let timerStartTime = timerStartTime,
              resendTimer > 0 else { return }
        
        _ = Int(Date().timeIntervalSince(backgroundTime))
        let elapsedTime = Int(Date().timeIntervalSince(timerStartTime))
        let remainingTime = max(0, 60 - elapsedTime)
        
        resendTimer = remainingTime
        
        if resendTimer > 0 {
            resumeResendTimer()
        } else {
            canResendCode = true
            self.timerStartTime = nil
        }
        
        self.backgroundTime = nil
    }
    
    private func resumeResendTimer() {
        resendTimerTask?.cancel()
        
        resendTimerTask = Task {
            while resendTimer > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                
                await MainActor.run {
                    resendTimer -= 1
                    if resendTimer <= 0 {
                        canResendCode = true
                        timerStartTime = nil
                    }
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            alertMessage = "No se pudo obtener el contexto de la ventana"
            showAlert = true
            return
        }
        
        auth.signInWithGoogle(presentingVC: rootViewController)
    }
    
    private func handlePhoneAuthStateChange(_ newState: AuthService.PhoneAuthState) {
        switch newState {
        case .awaitingVerification:
            verificationCode = ""
            focusedField = .phoneVerificationCode
            timerStartTime = nil
            backgroundTime = nil
        case .idle, .error:
            verificationCode = ""
            resendTimerTask?.cancel()
            timerStartTime = nil
            backgroundTime = nil
        case .verified:
            phoneNumber = ""
            verificationCode = ""
            resendTimerTask?.cancel()
            timerStartTime = nil
            backgroundTime = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    currentAuthFlow = .main
                }
            }
        default:
            break
        }
    }
}

// MARK: - Components
struct CircularSocialButton: View {
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
        }
    }
}

// MARK: - Previews
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
