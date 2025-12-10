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
    @State private var isSaving: Bool = false
    @State private var usernameAvailable: Bool? = nil
    @State private var usernameChecking: Bool = false
    @State private var errorText: String? = nil

    @Environment(\.dismiss) private var dismiss

    private var currentUser = AuthService.shared.user

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    private func header() -> some View {
        HStack {
            Button(action: { onClose() }) {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
            }
            Spacer()
            Text("Editar Perfil")
                .foregroundColor(.white)
                .font(.title3.bold())
            Spacer()
            Button(action: save) {
                if isSaving {
                    ProgressView().tint(.green)
                } else {
                    Text("Guardar")
                        .foregroundColor(.black)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
            }
            .disabled(!canSave || isSaving)
            .opacity(!canSave || isSaving ? 0.6 : 1.0)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard AuthService.shared.isValidUsername(username) else { return false }
        if let available = usernameAvailable { return available }
        return true
    }

    private func avatarPicker() -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.white.opacity(0.06)).frame(width: 96, height: 96)
                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                } else if let url = currentUser?.photoURL {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("Cambiar foto")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func labeledField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).foregroundColor(.white.opacity(0.8)).font(.caption)
            TextField(placeholder, text: text)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func usernameField() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Usuario").foregroundColor(.white.opacity(0.8)).font(.caption)
            HStack {
                TextField("usuario", text: $username)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                if usernameChecking {
                    ProgressView().tint(.green)
                } else if let available = usernameAvailable {
                    Image(systemName: available ? "checkmark.circle" : "xmark.circle")
                        .foregroundColor(available ? .green : .red)
                }
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Text("Solo letras, números, puntos y guiones. 3–30 caracteres.")
                .foregroundColor(.white.opacity(0.6))
                .font(.caption2)
        }
        .onChange(of: username) { _ in
            checkUsername()
        }
    }

    private func bioField() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Descripción")
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
            TextEditor(text: $bio)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func errorBanner() -> some View {
        Group {
            if let errorText = errorText {
                Text(errorText)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func content() -> some View {
        ScrollView {
            VStack(spacing: 12) {
                header()
                avatarPicker()
                labeledField(label: "Nombre", placeholder: "Tu nombre", text: $name)
                usernameField()
                labeledField(label: "Ubicación", placeholder: "Ciudad, País", text: $location)
                bioField()
                errorBanner()
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear(perform: load)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                    selectedImage = img
                }
            }
        }
    }

    var body: some View { content() }

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
                    }
                }
            }
        }
    }

    

    private func pickImage() {}

    private func checkUsername() {
        guard AuthService.shared.isValidUsername(username) else {
            usernameAvailable = false
            return
        }
        usernameChecking = true
        DatabaseService.shared.isUsernameAvailable(username) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let available):
                    usernameAvailable = available || username == currentUser?.username
                case .failure:
                    usernameAvailable = nil
                }
                usernameChecking = false
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
                        persist(uid: firebaseUser.uid, photo: newPhotoURL)
                    case .failure(let error):
                        errorText = error.localizedDescription
                        isSaving = false
                    }
                }
            }
        } else {
            persist(uid: firebaseUser.uid, photo: newPhotoURL)
        }
    }

    private func persist(uid: String, photo: URL?) {
        DatabaseService.shared.updateUserDocument(
            uid: uid,
            name: name,
            photoURL: photo,
            username: username,
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
                        photoURL: photo,
                        interests: AuthService.shared.user?.interests,
                        role: data["role"] as? String,
                        bio: data["bio"] as? String,
                        location: data["location"] as? String
                    )
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

