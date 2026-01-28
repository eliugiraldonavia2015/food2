import Foundation
import Combine

class PublicProfileViewModel: ObservableObject {
    @Published var user: UserProfileData?
    @Published var videos: [Video] = []
    @Published var isLoading = false
    
    // Modelo simplificado para la vista
    struct UserProfileData {
        let id: String
        let username: String
        let name: String
        let bio: String
        let photoUrl: String
        let coverUrl: String
        let followers: Int
        let location: String
    }
    
    private let userId: String
    
    init(userId: String, initialData: UserProfileData? = nil) {
        self.userId = userId
        if let data = initialData {
            self.user = data
        }
    }
    
    func loadData() {
        isLoading = true
        let group = DispatchGroup()
        
        // 1. Cargar Perfil (usando caché si es posible)
        group.enter()
        if let cached = UserCacheService.shared.getUser(userId) {
            self.mapUser(data: cached, uid: userId)
            group.leave()
        } else {
            DatabaseService.shared.fetchUser(uid: userId) { [weak self] result in
                if case .success(let data) = result {
                    self?.mapUser(data: data, uid: self?.userId ?? "")
                }
                group.leave()
            }
        }
        
        // 2. Cargar Videos
        group.enter()
        DatabaseService.shared.fetchUserVideos(userId: userId) { [weak self] result in
            if case .success(let videos) = result {
                DispatchQueue.main.async {
                    self?.videos = videos
                }
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func mapUser(data: [String: Any], uid: String) {
        let username = data["username"] as? String ?? "Usuario"
        let name = data["name"] as? String ?? ""
        let bio = data["bio"] as? String ?? "Amante de la comida 🌮"
        
        // 🛑 FIX CRÍTICO: Recuperar URL de Auth como fuente de verdad si Database falla
        let authPhoto = AuthService.shared.user?.photoURL?.absoluteString
        
        let existingPhoto = self.user?.photoUrl
        let fetchedPhoto = data["photoURL"] as? String
        
        // Jerarquía de verdad: 
        // 1. Base de datos (si existe y no es vacía)
        // 2. Auth Service (Google/Apple login data fresca)
        // 3. Cache existente en memoria
        // 4. Placeholder
        let photoUrl = (fetchedPhoto?.isEmpty == false ? fetchedPhoto : nil)
            ?? (authPhoto?.isEmpty == false ? authPhoto : nil)
            ?? existingPhoto 
            ?? "" // Dejar vacío para que la Vista maneje el placeholder final
            
        // 🛑 FIX: Priorizar datos existentes (Feed) sobre valores nulos/vacíos
        let existingCover = self.user?.coverUrl
        let fetchedCover = data["coverURL"] as? String
        let coverUrl = (fetchedCover?.isEmpty == false ? fetchedCover : nil)
            ?? existingCover
            ?? "" // Dejar vacío para que la Vista maneje el hardcode
        
        DispatchQueue.main.async {
            self.user = UserProfileData(
                id: uid,
                username: username,
                name: name,
                bio: bio,
                photoUrl: photoUrl,
                coverUrl: coverUrl,
                followers: 1200, // TODO: Implementar followers reales
                location: data["location"] as? String ?? "Ciudad de México"
            )
        }
    }
}
