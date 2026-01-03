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
            self.isLoading = false
        }
    }
    
    func loadData() {
        // Si es un usuario mock, no intentamos cargar de la red
        if userId == "mock_user" {
            // Si no tenemos datos (no se pasaron en init), cargamos un fallback
            if user == nil {
                mapUser(data: [:], uid: "mock_user")
            }
            // Simulamos carga de videos vacía o mock si quisieras
            return
        }
        
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
        let photoUrl = data["photoURL"] as? String ?? "https://images.unsplash.com/photo-1544005313-94ddf0286df2"
        let coverUrl = "https://images.unsplash.com/photo-1493770348161-369560ae357d" // Placeholder por ahora
        
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
