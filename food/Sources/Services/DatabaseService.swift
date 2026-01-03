import FirebaseFirestore
import FirebaseAuth
import Foundation

public final class DatabaseService {
    // MARK: - Singleton
    public static let shared = DatabaseService()
    
    // ✅ Hacemos `db` público solo para lectura (usado por AuthService)
    public let db: Firestore
    
    // MARK: - Private constants
    private let usersCollection = "users"
    private let usernamesCollection = "usernames"
    
    private init() {
        // ✅ Usa la misma base de datos central
        self.db = Firestore.firestore(database: "logincloud")
        
        // ✅ Configuración consistente del host
        let settings = db.settings
        settings.host = "firestore.googleapis.com"
        db.settings = settings
        
        setupFirestore()
    }
    
    private func setupFirestore() {
        print("[Database] ✅ Configured for database: logincloud")
    }
    
    // MARK: - Crear documento de usuario
    public func createUserDocument(
        uid: String,
        name: String?,
        email: String?,
        photoURL: URL? = nil,
        username: String? = nil,
        role: String? = nil // ✅ NUEVO: parámetro role agregado
    ) {
        var userData: [String: Any] = [
            "uid": uid,
            "email": email ?? "",
            "name": name ?? "",
            "username": username ?? "",
            "createdAt": Timestamp(date: Date()),
            "lastLogin": Timestamp(date: Date()),
            "photoURL": photoURL?.absoluteString ?? "",
            "isPremium": false,
            "onboardingCompleted": false, // ✅ INICIALIZADO CORRECTAMENTE
            "bio": "",
            "location": "",
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]
        
        // ✅ Agregar role solo si se proporciona
        if let role = role {
            userData["role"] = role
        }
        
        db.collection(usersCollection).document(uid).setData(userData) { error in
            if let error = error {
                print("[Database] ❌ Error creating user document: \(error.localizedDescription)")
            } else {
                print("[Database] ✅ User document created successfully for \(uid)")
            }
        }
    }
    
    // MARK: - Obtener email por username usando índice público
    public func getEmailForUsername(username: String, completion: @escaping (String?) -> Void) {
        db.collection(usernamesCollection)
            .document(username)
            .getDocument { snapshot, error in
                if let error = error {
                    print("[Database] ❌ Error checking username index: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let data = snapshot?.data() else {
                    completion(nil)
                    return
                }
                completion(data["email"] as? String)
            }
    }
    
    // MARK: - Verificar disponibilidad de username (CORREGIDO)
    public func isUsernameAvailable(_ username: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        db.collection(usernamesCollection)
            .document(username)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let isAvailable = (snapshot == nil) || (snapshot?.exists == false)
                completion(.success(isAvailable))
            }
    }
    
    // MARK: - Actualizar último login
    public func updateLastLogin(uid: String) {
        let updateData: [String: Any] = [
            "lastLogin": Timestamp(date: Date())
        ]
        
        db.collection(usersCollection).document(uid).updateData(updateData) { error in
            if let error = error {
                print("[Database] ⚠️ Error updating last login: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Crear índice de username
    public func createUsernameIndex(username: String, uid: String, email: String?) {
        guard !username.isEmpty else { return }
        var data: [String: Any] = ["uid": uid]
        if let email = email { data["email"] = email }
        db.collection(usernamesCollection).document(username).setData(data) { error in
            if let error = error {
                print("[Database] ⚠️ Error creating username index: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Actualizar información del usuario
    public func updateUserDocument(
        uid: String,
        name: String? = nil,
        photoURL: URL? = nil,
        username: String? = nil,
        bio: String? = nil,
        location: String? = nil
    ) {
        var updateData: [String: Any] = [:]
        
        if let name = name { updateData["name"] = name }
        if let photoURL = photoURL { updateData["photoURL"] = photoURL.absoluteString }
        if let username = username { updateData["username"] = username }
        if let bio = bio { updateData["bio"] = bio }
        if let location = location { updateData["location"] = location }
        
        updateData["lastUpdated"] = Timestamp(date: Date())
        guard !updateData.isEmpty else { return }
        
        db.collection(usersCollection).document(uid).updateData(updateData) { error in
            if let error = error {
                print("[Database] ❌ Error updating user: \(error.localizedDescription)")
            } else {
                print("[Database] ✅ User updated successfully")
            }
        }
    }
    
    // MARK: - Obtener información del usuario
    public func fetchUser(
        uid: String,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        db.collection(usersCollection).document(uid).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let document = document, document.exists else {
                completion(.failure(
                    NSError(domain: "Database", code: 404, userInfo: [NSLocalizedDescriptionKey: "User document not found"])
                ))
                return
            }
            completion(.success(document.data() ?? [:]))
        }
    }
    
    // MARK: - Observar cambios del usuario
    public func observeUser(
        uid: String,
        handler: @escaping (Result<[String: Any], Error>) -> Void
    ) -> ListenerRegistration {
        return db.collection(usersCollection).document(uid).addSnapshotListener { snapshot, error in
            if let error = error {
                handler(.failure(error))
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                handler(.failure(
                    NSError(domain: "Database", code: 404, userInfo: [NSLocalizedDescriptionKey: "User document not found"])
                ))
                return
            }
            handler(.success(snapshot.data() ?? [:]))
        }
    }
    
    // MARK: - Verificar si existe documento de usuario
    public func userDocumentExists(uid: String, completion: @escaping (Bool) -> Void) {
        db.collection(usersCollection).document(uid).getDocument { document, error in
            if let error = error {
                print("[Database] ⚠️ Error checking user document: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(document?.exists ?? false)
        }
    }
    
    // MARK: - Eliminar usuario
    public func deleteUserDocument(uid: String, completion: @escaping (Error?) -> Void) {
        db.collection(usersCollection).document(uid).delete { error in
            if let error = error {
                print("[Database] ⚠️ Error deleting user document: \(error.localizedDescription)")
            } else {
                print("[Database] 🗑️ User document deleted successfully")
            }
            completion(error)
        }
    }
    
    // MARK: - Video Management
    public func createVideoDocument(video: Video, completion: @escaping (Error?) -> Void) {
        db.collection("videos").document(video.id).setData(video.dictionary) { error in
            if let error = error {
                print("[Database] ❌ Error creating video document: \(error.localizedDescription)")
            } else {
                print("[Database] ✅ Video document created successfully: \(video.id)")
            }
            completion(error)
        }
    }
    
    // MARK: - Video Fetching (User Profile)
    
    /// Obtiene los videos de un usuario específico
    public func fetchUserVideos(userId: String, completion: @escaping (Result<[Video], Error>) -> Void) {
        db.collection("videos")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let videos = documents.compactMap { doc -> Video? in
                    try? doc.data(as: Video.self)
                }
                completion(.success(videos))
            }
    }
    
    // MARK: - Likes Management
    
    /// Da like a un video
    /// Esto crea un documento en `videos/{videoId}/likes/{userId}` y actualiza el contador localmente
    /// (Idealmente el contador total se actualiza con Cloud Functions para consistencia)
    public func likeVideo(videoId: String, userId: String, completion: @escaping (Error?) -> Void) {
        let likeRef = db.collection("videos").document(videoId).collection("likes").document(userId)
        let videoRef = db.collection("videos").document(videoId)
        
        let batch = db.batch()
        
        // 1. Crear documento de like
        batch.setData([
            "userId": userId,
            "createdAt": Timestamp(date: Date())
        ], forDocument: likeRef)
        
        // 2. Incrementar contador en video (Optimista)
        batch.updateData([
            "likes": FieldValue.increment(Int64(1))
        ], forDocument: videoRef)
        
        batch.commit { error in
            if let error = error {
                print("[Database] ❌ Error liking video: \(error.localizedDescription)")
            } else {
                print("[Database] ❤️ Video liked: \(videoId)")
            }
            completion(error)
        }
    }
    
    /// Quita like a un video
    public func unlikeVideo(videoId: String, userId: String, completion: @escaping (Error?) -> Void) {
        let likeRef = db.collection("videos").document(videoId).collection("likes").document(userId)
        let videoRef = db.collection("videos").document(videoId)
        
        let batch = db.batch()
        
        // 1. Borrar documento de like
        batch.deleteDocument(likeRef)
        
        // 2. Decrementar contador en video (Optimista)
        batch.updateData([
            "likes": FieldValue.increment(Int64(-1))
        ], forDocument: videoRef)
        
        batch.commit { error in
            if let error = error {
                print("[Database] ❌ Error unliking video: \(error.localizedDescription)")
            } else {
                print("[Database] 💔 Video unliked: \(videoId)")
            }
            completion(error)
        }
    }
    
    /// Verifica si el usuario actual ya dio like al video
    public func checkIfUserLiked(videoId: String, userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("videos").document(videoId).collection("likes").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("[Database] ⚠️ Error checking like status: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(snapshot?.exists ?? false)
        }
    }
    
    // MARK: - Comments Management
    
    /// Publica un comentario en un video
    public func postComment(videoId: String, text: String, userId: String, completion: @escaping (Error?) -> Void) {
        let commentsRef = db.collection("videos").document(videoId).collection("comments")
        let videoRef = db.collection("videos").document(videoId)
        
        let batch = db.batch()
        
        // 1. Crear documento de comentario (Auto ID)
        let newCommentRef = commentsRef.document()
        batch.setData([
            "id": newCommentRef.documentID,
            "userId": userId,
            "text": text,
            "createdAt": Timestamp(date: Date()),
            "likes": 0
        ], forDocument: newCommentRef)
        
        // 2. Incrementar contador en video
        batch.updateData([
            "comments": FieldValue.increment(Int64(1))
        ], forDocument: videoRef)
        
        batch.commit { error in
            if let error = error {
                print("[Database] ❌ Error posting comment: \(error.localizedDescription)")
            } else {
                print("[Database] 💬 Comment posted on: \(videoId)")
            }
            completion(error)
        }
    }
    
    /// Obtiene los comentarios de un video
    public func fetchComments(videoId: String, completion: @escaping (Result<[CommentsOverlayView.Comment], Error>) -> Void) {
        db.collection("videos").document(videoId).collection("comments")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Necesitamos hacer fetch de los usuarios para mostrar nombres/fotos
                // Para simplificar y hacerlo rápido, usaremos un DispatchGroup o similar
                // Por ahora, asumiremos que tenemos un método rápido o cacheado,
                // o simplemente devolvemos los datos crudos y dejamos que la vista resuelva el usuario (mejor opción)
                
                // NOTA: Para una implementación real eficiente, deberíamos guardar snapshot del autor en el comentario
                // o tener un cache de usuarios. Aquí haremos una implementación básica que podría requerir mejoras.
                
                let group = DispatchGroup()
                var comments: [CommentsOverlayView.Comment] = []
                
                for doc in docs {
                    group.enter()
                    let data = doc.data()
                    let userId = data["userId"] as? String ?? ""
                    let text = data["text"] as? String ?? ""
                    let timestamp = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let id = doc.documentID
                    
                    // Fetch user info
                    self.fetchUser(uid: userId) { result in
                        var username = "Usuario"
                        var photoUrl = ""
                        
                        if case .success(let userData) = result {
                            username = userData["username"] as? String ?? "Usuario"
                            photoUrl = userData["photoURL"] as? String ?? ""
                        }
                        
                        let comment = CommentsOverlayView.Comment(
                            id: id,
                            userId: userId,
                            username: username,
                            text: text,
                            timestamp: timestamp,
                            avatarUrl: photoUrl
                        )
                        
                        DispatchQueue.main.async {
                            comments.append(comment)
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    // Ordenar de nuevo porque los callbacks asíncronos pueden desordenar
                    comments.sort(by: { $0.timestamp > $1.timestamp })
                    completion(.success(comments))
                }
            }
    }
    
    // MARK: - Batch Fetching
    
    /// Obtiene múltiples usuarios en una sola consulta (max 10 por lote)
    public func fetchUsers(byIds ids: [String], completion: @escaping (Result<[String: [String: Any]], Error>) -> Void) {
        guard !ids.isEmpty else {
            completion(.success([:]))
            return
        }
        
        // Firestore limita las consultas 'in' a 10 elementos.
        // Si hay más de 10, hay que dividirlos en chunks.
        let chunks = ids.chunked(into: 10)
        var results: [String: [String: Any]] = [:]
        let group = DispatchGroup()
        var lastError: Error?
        
        for chunk in chunks {
            group.enter()
            db.collection(usersCollection)
                .whereField("uid", in: chunk)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("[Database] ⚠️ Error fetching users batch: \(error.localizedDescription)")
                        lastError = error
                    } else if let docs = snapshot?.documents {
                        for doc in docs {
                            results[doc.documentID] = doc.data()
                        }
                    }
                    group.leave()
                }
        }
        
        group.notify(queue: .global()) {
            if let error = lastError, results.isEmpty {
                completion(.failure(error))
            } else {
                completion(.success(results))
            }
        }
    }
    // MARK: - Onboarding Related
    public func updateUserInterests(
        uid: String,
        interests: [String],
        completion: @escaping (Error?) -> Void
    ) {
        let updateData: [String: Any] = [
            "interests": interests,
            "lastUpdated": Timestamp(date: Date())
        ]
        
        db.collection(usersCollection).document(uid).updateData(updateData) { error in
            if let error = error {
                print("[Database] ⚠️ Error updating interests: \(error.localizedDescription)")
            } else {
                print("[Database] ✅ Interests updated successfully for \(uid)")
            }
            completion(error)
        }
    }
}
