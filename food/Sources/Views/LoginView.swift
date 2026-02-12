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

// MARK: - Modern Login View
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
    
    // Validation & Feedback
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isUsernameAvailable = true
    @State private var checkingUsername = false
    @State private var passwordStrength: PasswordStrength?
    @State private var shakeOffset: CGFloat = 0
    
    // Focus
    @FocusState private var focusedField: FocusField?
    enum FocusField {
        case emailOrUser, password, firstName, lastName, email, username, confirmPass, phone, code
    }
    
    // Dependencies
    private let loginUseCase = LoginUseCase()
    private let signupUseCase = SignupUseCase()
    #if canImport(PhoneNumberKit)
    private let phoneNumberKit = PhoneNumberKit()
    #endif
    
    // Theme Colors
    private let brandPrimary = Color(red: 244/255, green: 37/255, blue: 123/255) // Brand Pink
    private let brandSecondary = Color(red: 255/255, green: 149/255, blue: 0/255) // Orange
    private let darkBg = Color(red: 18/255, green: 18/255, blue: 20/255)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Dynamic Background
                DynamicBackgroundView()
                    .ignoresSafeArea()
                    .onTapGesture { focusedField = nil }
                
                // 2. Main Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 60)
                        
                        // Header Logo
                        VStack(spacing: 16) {
                            BrandLogoView()
                                .shadow(color: brandPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
                                .scaleEffect(1.2)
                            
                            Text("FoodTook")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .tracking(1)
                        }
                        .padding(.bottom, 40)
                        
                        // Content Card
                        VStack(spacing: 24) {
                            if currentAuthFlow == .phone {
                                phoneAuthContent
                                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            } else if isShowingForgotPassword {
                                forgotPasswordContent
                                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            } else {
                                mainAuthContent
                                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color(uiColor: .systemGray6).opacity(0.1))
                                .background(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 40)
                    }
                    .frame(minHeight: UIScreen.main.bounds.height)
                }
                
                // 3. Success Overlay
                if showSuccessAnimation {
                    SuccessOverlayView()
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .alert("FoodTook", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    triggerSuccessAnimation()
                }
            }
            .onChange(of: auth.errorMessage) { _, error in
                if let error = error {
                    alertMessage = error
                    showAlert = true
                    shakeForm()
                }
            }
        }
    }
    
    // MARK: - Main Auth Content
    private var mainAuthContent: some View {
        VStack(spacing: 24) {
            // Segmented Control
            HStack(spacing: 0) {
                TabButton(title: "Log In", isSelected: !isSignUp) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isSignUp = false }
                }
                TabButton(title: "Sign Up", isSelected: isSignUp) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isSignUp = true }
                }
            }
            .background(Color.black.opacity(0.2))
            .clipShape(Capsule())
            .padding(.bottom, 10)
            
            // Forms
            Group {
                if isSignUp {
                    signUpForm
                } else {
                    loginForm
                }
            }
            .offset(x: shakeOffset)
            
            // Divider
            HStack {
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                Text("OR")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
            }
            
            // Social Buttons
            HStack(spacing: 20) {
                SocialCircleButton(image: "g.circle.fill", color: .white) { handleGoogleSignIn() }
                SocialCircleButton(image: "apple.logo", color: .white) { /* Apple Auth */ }
                SocialCircleButton(image: "phone.fill", color: .green) {
                    withAnimation { currentAuthFlow = .phone }
                }
            }
        }
    }
    
    // MARK: - Login Form
    private var loginForm: some View {
        VStack(spacing: 16) {
            ModernTextField(
                text: $emailOrUsername,
                placeholder: "Email or Username",
                icon: "person.fill",
                focusedField: $focusedField,
                fieldId: .emailOrUser
            )
            
            VStack(alignment: .trailing, spacing: 8) {
                ModernTextField(
                    text: $password,
                    placeholder: "Password",
                    icon: "lock.fill",
                    isSecure: true,
                    focusedField: $focusedField,
                    fieldId: .password
                )
                
                Button(action: { withAnimation { isShowingForgotPassword = true } }) {
                    Text("Forgot Password?")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(brandPrimary)
                }
            }
            
            SmartLoadingButton(
                title: "Log In",
                isLoading: auth.isLoading,
                action: {
                    Task { await loginUseCase.signIn(identifier: emailOrUsername, password: password) }
                }
            )
            .disabled(emailOrUsername.isEmpty || password.isEmpty)
            .opacity(emailOrUsername.isEmpty || password.isEmpty ? 0.6 : 1)
        }
    }
    
    // MARK: - Sign Up Form
    private var signUpForm: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ModernTextField(text: $firstName, placeholder: "First", icon: "person", focusedField: $focusedField, fieldId: .firstName)
                ModernTextField(text: $lastName, placeholder: "Last", icon: "person", focusedField: $focusedField, fieldId: .lastName)
            }
            
            ModernTextField(text: $email, placeholder: "Email", icon: "envelope", focusedField: $focusedField, fieldId: .email)
            
            VStack(spacing: 4) {
                ModernTextField(
                    text: $username,
                    placeholder: "Username",
                    icon: "at",
                    focusedField: $focusedField,
                    fieldId: .username,
                    statusIcon: isUsernameAvailable && !username.isEmpty ? "checkmark.circle.fill" : nil,
                    statusColor: .green
                )
                .onChange(of: username) { _, newValue in
                    checkUsernameAvailability(newValue)
                }
                
                if !username.isEmpty && !isUsernameAvailable {
                    Text("Username taken")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                }
            }
            
            VStack(spacing: 4) {
                ModernTextField(text: $password, placeholder: "Password", icon: "lock", isSecure: true, focusedField: $focusedField, fieldId: .password)
                    .onChange(of: password) { _, newValue in
                        passwordStrength = auth.evaluatePasswordStrength(newValue, email: email, username: username)
                    }
                
                if let strength = passwordStrength {
                    PasswordStrengthLine(strength: strength)
                }
            }
            
            ModernTextField(text: $confirmPassword, placeholder: "Confirm Password", icon: "lock.shield", isSecure: true, focusedField: $focusedField, fieldId: .confirmPass)
            
            SmartLoadingButton(
                title: "Create Account",
                isLoading: auth.isLoading,
                action: registerUser
            )
            .disabled(!isSignUpFormValid)
            .opacity(isSignUpFormValid ? 1 : 0.6)
        }
    }
    
    // MARK: - Phone Auth Content
    private var phoneAuthContent: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Button(action: { withAnimation { currentAuthFlow = .main } }) {
                    Image(systemName: "arrow.left")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Phone Login")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 24)
            }
            
            if auth.phoneAuthState.isAwaitingCode {
                VStack(spacing: 20) {
                    Text("Enter Verification Code")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Sent to \(phoneNumber)")
                        .foregroundColor(.gray)
                    
                    ModernTextField(
                        text: $verificationCode,
                        placeholder: "000000",
                        icon: "key",
                        focusedField: $focusedField,
                        fieldId: .code
                    )
                    .keyboardType(.numberPad)
                    
                    SmartLoadingButton(title: "Verify", isLoading: auth.isLoading) {
                        auth.verifyCode(verificationCode)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Text("What's your number?")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Text("🇪🇨 +593")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                        
                        ModernTextField(
                            text: $phoneNumber,
                            placeholder: "99 123 4567",
                            icon: "phone",
                            focusedField: $focusedField,
                            fieldId: .phone
                        )
                        .keyboardType(.numberPad)
                    }
                    
                    SmartLoadingButton(title: "Send Code", isLoading: auth.isLoading) {
                        sendVerificationCode()
                    }
                }
            }
        }
    }
    
    // MARK: - Forgot Password Content
    private var forgotPasswordContent: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { withAnimation { isShowingForgotPassword = false } }) {
                    Image(systemName: "arrow.left")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Recovery")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 24)
            }
            
            Text("Don't worry, happens to the best of us.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            ModernTextField(
                text: $email,
                placeholder: "Enter your email",
                icon: "envelope",
                focusedField: $focusedField,
                fieldId: .email
            )
            
            SmartLoadingButton(title: "Send Reset Link", isLoading: auth.isLoading) {
                // Trigger password reset logic
            }
        }
    }
    
    // MARK: - Actions & Helpers
    
    private func triggerSuccessAnimation() {
        withAnimation {
            showSuccessAnimation = true
        }
        // Let animation play before navigating/dismissing (handled by RootView usually)
    }
    
    private func shakeForm() {
        let duration = 0.5
        withAnimation(.linear(duration: duration)) {
            shakeOffset = 10
        }
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            withAnimation { shakeOffset = -10 }
            try? await Task.sleep(nanoseconds: 50_000_000)
            withAnimation { shakeOffset = 10 }
            try? await Task.sleep(nanoseconds: 50_000_000)
            withAnimation { shakeOffset = 0 }
        }
    }
    
    private func checkUsernameAvailability(_ username: String) {
        guard !username.isEmpty else { return }
        checkingUsername = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            DatabaseService.shared.isUsernameAvailable(username) { result in
                DispatchQueue.main.async {
                    if case .success(let available) = result {
                        self.isUsernameAvailable = available
                    } else {
                        self.isUsernameAvailable = false
                    }
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
    
    private func registerUser() {
        Task { await signupUseCase.signUp(email: email, password: password, firstName: firstName, lastName: lastName, username: username) }
    }
    
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        auth.signInWithGoogle(presentingVC: rootViewController)
    }
    
    private var isSignUpFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !firstName.isEmpty && !username.isEmpty && password == confirmPassword
    }
}

// MARK: - Components

struct DynamicBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 12/255) // Almost black
            
            // Animated Blobs
            GeometryReader { geo in
                Circle()
                    .fill(Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.4))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: animate ? -50 : 50, y: animate ? -100 : 0)
                
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .offset(x: geo.size.width - (animate ? 100 : 200), y: geo.size.height - (animate ? 150 : 250))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    var focusedField: FocusState<LoginView.FocusField?>.Binding
    var fieldId: LoginView.FocusField
    var statusIcon: String? = nil
    var statusColor: Color = .green
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(focusedField.wrappedValue == fieldId ? .white : .gray)
                .frame(width: 24)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.7)))
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.7)))
            }
            
            if let statusIcon = statusIcon {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(focusedField.wrappedValue == fieldId ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .foregroundColor(.white)
        .focused(focusedField, equals: fieldId)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.white : Color.clear)
                .clipShape(Capsule())
                .padding(2)
        }
    }
}

struct SmartLoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .bold()
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(red: 244/255, green: 37/255, blue: 123/255), Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

struct SocialCircleButton: View {
    let image: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: image)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

struct PasswordStrengthLine: View {
    let strength: PasswordStrength
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(strength.strength.uiProgressValue * 4) ? strength.strength.uiColor : Color.white.opacity(0.1))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Success Overlay
struct SuccessOverlayView: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color(red: 244/255, green: 37/255, blue: 123/255) // Brand Pink Flood
                .ignoresSafeArea()
            
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                
                Text("Welcome!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                opacity = 1.0
            }
        }
    }
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
