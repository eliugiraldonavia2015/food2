import SwiftUI
import PhotosUI
import SDWebImageSwiftUI
import FirebaseAuth

struct EditProfileView: View {
    let onClose: () -> Void

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedCoverImage: UIImage? = nil
    @State private var selectedCoverItem: PhotosPickerItem? = nil
    @State private var isSaving: Bool = false
    @State private var usernameAvailable: Bool? = nil
    @State private var usernameChecking: Bool = false
    @State private var errorText: String? = nil
    @State private var coverUrlString: String = ""
    
    // Animation States
    @State private var appear = false

    @Environment(\.dismiss) private var dismiss

    private var currentUser = AuthService.shared.user

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: {
                        withAnimation { onClose() }
                    }) {
                        Text("Cancelar")
                            .foregroundColor(.primary)
                            .font(.system(size: 17))
                    }
                    
                    Spacer()
                    
                    Text("Editar Perfil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: save) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Guardar")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(canSave ? .fuchsia : .secondary.opacity(0.5))
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(uiColor: .systemBackground).shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5))
                .zIndex(10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section: Images
                        VStack(spacing: 0) {
                            coverPicker
                                .overlay(
                                    avatarPicker
                                        .offset(y: 60), // Half of avatar height
                                    alignment: .bottom
                                )
                                .padding(.bottom, 60) // Space for avatar
                        }
                        .scaleEffect(appear ? 1 : 0.95)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appear)
                        
                        // Section: Fields
                        VStack(spacing: 20) {
                            EditProfileTextField(label: "Nombre", placeholder: "Nombre", text: $name)
                            
                            usernameField
                            
                            EditProfileTextField(label: "Ubicación", placeholder: "Ciudad, País", text: $location)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Biografía")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                
                                TextEditor(text: $bio)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden) // iOS 16+ fix for background
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        .offset(y: appear ? 0 : 30)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appear)
                        
                        errorBanner
                            .padding(.horizontal)
                            .opacity(errorText != nil ? 1 : 0)
                            .animation(.default, value: errorText)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        // Removed forced preferredColorScheme

        .onAppear {
            load()
            withAnimation {
                appear = true
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    withAnimation { selectedImage = img }
                }
            }
        }
        .onChange(of: selectedCoverItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    withAnimation { selectedCoverImage = img }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var coverPicker: some View {
        PhotosPicker(selection: $selectedCoverItem, matching: .images) {
            ZStack {
                Color(uiColor: .secondarySystemBackground)
                
                if let img = selectedCoverImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else if let url = URL(string: coverUrlString), !coverUrlString.isEmpty {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.secondary)
                        .font(.title)
                }
            }
            .frame(height: 180)
            .clipped()
            .overlay(
                Color.black.opacity(0.1)
                    .overlay(
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .padding(8),
                        alignment: .topTrailing
                    )
            )
        }
    }
    
    private var avatarPicker: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                Group {
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else if let url = currentUser?.photoURL {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                }
                .frame(width: 112, height: 112)
                .clipShape(Circle())
                
                // Edit Badge
                Circle()
                    .fill(Color.fuchsia)
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "camera.fill").foregroundColor(.white).font(.system(size: 14)))
                    .offset(x: 40, y: 40)
            }
        }
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Usuario")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            HStack {
                Text("@")
                    .foregroundColor(.secondary)
                TextField("usuario", text: $username)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .foregroundColor(.primary)
                
                if usernameChecking {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let available = usernameAvailable, !username.isEmpty {
                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(available ? .green : .red)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(usernameAvailable == false ? Color.red : Color.secondary.opacity(0.1), lineWidth: 1)
            )
            
            if usernameAvailable == false {
                Text("Este nombre de usuario no está disponible")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
        .onChange(of: username) { _ in checkUsername() }
    }
    
    private var errorBanner: some View {
        Group {
            if let errorText = errorText {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(errorText)
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Logic
    
    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard AuthService.shared.isValidUsername(username) else { return false }
        if let available = usernameAvailable { return available }
        return true
    }
    
    private func load() {
        name = currentUser?.name ?? ""
        username = currentUser?.username ?? ""
        bio = currentUser?.bio ?? ""
        location = currentUser?.location ?? ""
        if !username.isEmpty { checkUsername() }

        if let uid = Auth.auth().currentUser?.uid {
            DatabaseService.shared.fetchUser(uid: uid) { result in
                DispatchQueue.main.async {
                    if case .success(let data) = result {
                        name = (data["name"] as? String) ?? name
                        username = (data["username"] as? String) ?? username
                        bio = (data["bio"] as? String) ?? bio
                        location = (data["location"] as? String) ?? location
                        coverUrlString = (data["coverURL"] as? String) ?? coverUrlString
                    }
                }
            }
        }
    }

    private func checkUsername() {
        guard AuthService.shared.isValidUsername(username) else {
            usernameAvailable = false
            return
        }
        usernameChecking = true
        if let uid = Auth.auth().currentUser?.uid {
            DatabaseService.shared.isUsernameAvailable(for: uid, username: username) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let availableForUser):
                        usernameAvailable = availableForUser
                    case .failure:
                        usernameAvailable = nil
                    }
                    usernameChecking = false
                }
            }
        } else {
            DatabaseService.shared.isUsernameAvailable(username) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let available):
                        usernameAvailable = available
                    case .failure:
                        usernameAvailable = nil
                    }
                    usernameChecking = false
                }
            }
        }
    }

    private func save() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        isSaving = true
        errorText = nil

        var newPhotoURL: URL? = currentUser?.photoURL
        if let image = selectedImage {
            StorageService.shared.uploadProfileImage(uid: firebaseUser.uid, image: image) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url):
                        newPhotoURL = url
                        AuthService.shared.updateProfilePhoto(with: url)
                        maybeUploadCoverAndPersist(uid: firebaseUser.uid, photoURL: newPhotoURL)
                    case .failure(let error):
                        errorText = error.localizedDescription
                        isSaving = false
                    }
                }
            }
        } else {
            maybeUploadCoverAndPersist(uid: firebaseUser.uid, photoURL: newPhotoURL)
        }
    }

    private func maybeUploadCoverAndPersist(uid: String, photoURL: URL?) {
        if let coverImg = selectedCoverImage {
            StorageService.shared.uploadProfileCover(uid: uid, image: coverImg) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url):
                        persist(uid: uid, photoURL: photoURL, coverURL: url)
                    case .failure(let error):
                        errorText = error.localizedDescription
                        isSaving = false
                    }
                }
            }
        } else {
            persist(uid: uid, photoURL: photoURL, coverURL: nil)
        }
    }

    private func persist(uid: String, photoURL: URL?, coverURL: URL?) {
        let email = AuthService.shared.user?.email
        let currentUsername = AuthService.shared.user?.username ?? ""
        
        if !username.isEmpty && username != currentUsername {
            DatabaseService.shared.updateUsername(uid: uid, newUsername: username, email: email) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        errorText = "No se pudo actualizar el usuario: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        DatabaseService.shared.updateUserDocument(
            uid: uid,
            name: name,
            photoURL: photoURL,
            coverURL: coverURL,
            bio: bio,
            location: location
        )

        DatabaseService.shared.fetchUser(uid: uid) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result {
                    AuthService.shared.user = AppUser(
                        uid: uid,
                        email: AuthService.shared.user?.email,
                        name: data["name"] as? String,
                        username: data["username"] as? String,
                        phoneNumber: AuthService.shared.user?.phoneNumber,
                        photoURL: photoURL ?? AuthService.shared.user?.photoURL,
                        interests: AuthService.shared.user?.interests,
                        role: data["role"] as? String,
                        bio: data["bio"] as? String,
                        location: data["location"] as? String
                    )
                    coverUrlString = data["coverURL"] as? String ?? coverUrlString
                    isSaving = false
                    onClose()
                } else {
                    errorText = "No se pudo actualizar el perfil"
                    isSaving = false
                }
            }
        }
    }
}

// Removed duplicate ModernTextField definition
// It was already defined in LoginView.swift, but due to access control issues, we should probably move it to a shared file.
// However, since we cannot easily move files in this context without breaking other things or creating new files,
// we will rename this local version to `EditProfileTextField` to avoid conflict.

struct EditProfileTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.secondary))
                .foregroundColor(.primary)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        }
    }
}
