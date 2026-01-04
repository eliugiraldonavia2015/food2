import SwiftUI
import Combine
import SDWebImage

final class FeedViewModel: ObservableObject {
    private let storageKey: String
    
    // ✅ Fuente de Verdad: Videos descargados de Firestore
    @Published var videos: [FeedItem] = []
    @Published var isLoading = false
    
    @Published var currentIndex: Int {
        didSet { 
            UserDefaults.standard.set(currentIndex, forKey: storageKey) 
            checkPaginationThreshold()
        }
    }

    init(storageKey: String) {
        self.storageKey = storageKey
        self.currentIndex = UserDefaults.standard.object(forKey: storageKey) as? Int ?? 0
        
        // 🚀 Carga inicial automática
        loadRecentVideos(reset: true)
    }
    
    /// Carga videos frescos desde Firestore y los hidrata con perfiles de usuario
    func loadRecentVideos(reset: Bool = false) {
        guard !isLoading else { return }
        
        // Si no hay más contenido, no intentamos cargar más
        if !reset && !FeedService.shared.hasMoreContent { return }
        
        isLoading = true
        
        if reset {
            FeedService.shared.resetPagination()
            // No borramos 'videos' aquí para evitar parpadeo visual, 
            // se maneja en el callback si es necesario, o se puede hacer un replace.
            // Para "Pull to Refresh" idealmente reemplazamos todo.
        }
        
        FeedService.shared.fetchRecentVideos { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedVideos):
                // 1. Obtener IDs únicos de autores
                let userIds = fetchedVideos.compactMap { $0.userId }
                
                // 2. Resolver perfiles en batch (usando caché inteligente)
                UserCacheService.shared.resolveUsers(userIds: userIds) { userProfiles in
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        // 3. Mapear videos hidratados con la data del perfil
                        let newItems = fetchedVideos.map { video -> FeedItem in
                            let profile = userProfiles[video.userId] ?? [:]
                            return self.mapToFeedItem(video: video, userProfile: profile)
                        }
                        
                        // 4. Actualizar UI
                        if !newItems.isEmpty {
                            if reset {
                                self.videos = newItems
                                // Reconstruir el set de vistos
                                self.seenVideoIds = Set(newItems.compactMap { $0.videoId })
                            } else {
                                // 🛑 DEDUPLICACIÓN SCALABLE (O(1)):
                                // Usamos el Set persistente en lugar de reconstruirlo
                                let uniqueItems = newItems.filter { item in
                                    guard let vid = item.videoId else { return true }
                                    // Si ya lo vimos, lo descartamos
                                    if self.seenVideoIds.contains(vid) { return false }
                                    return true
                                }
                                
                                // Registrar los nuevos IDs en el Set
                                uniqueItems.forEach { 
                                    if let vid = $0.videoId { self.seenVideoIds.insert(vid) }
                                }
                                
                                // Filtrar solo items que tengan video URL válido (no solo thumbnails)
                                let playableItems = uniqueItems.filter { $0.videoUrl != nil && !$0.videoUrl!.isEmpty }
                                
                                self.videos.append(contentsOf: playableItems)
                            }
                            // Prefetch de las nuevas miniaturas
                            self.prefetch(urls: newItems.map { $0.backgroundUrl })
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("⚠️ Error cargando feed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkPaginationThreshold() {
        // Umbral: Cargar más cuando faltan 3 videos para el final
        let threshold = 3
        if currentIndex >= (videos.count - threshold) {
            loadRecentVideos(reset: false)
        }
    }
    
    /// Convierte el modelo crudo de DB al modelo visual, inyectando datos de usuario
    private func mapToFeedItem(video: Video, userProfile: [String: Any]) -> FeedItem {
        let username = userProfile["username"] as? String ?? "Usuario"
        let photoUrl = userProfile["photoURL"] as? String ?? "https://images.unsplash.com/photo-1544005313-94ddf0286df2" // Fallback seguro
        
        return FeedItem(
            id: UUID(),
            videoId: video.id,
            authorId: video.userId, // ✅ ID del autor real
            backgroundUrl: video.thumbnailUrl,
            username: username, // ✅ Nombre real del autor
            label: .none,
            hasStories: false,
            avatarUrl: photoUrl, // ✅ Foto real del autor
            title: video.title,
            description: video.description,
            soundTitle: "Sonido Original",
            likes: video.likes,
            comments: video.comments,
            shares: video.shares,
            videoUrl: video.videoUrl,
            posterUrl: video.thumbnailUrl
        )
    }

    func prefetch(urls: [String]) {
        let u = urls.compactMap { URL(string: $0) }
        SDWebImagePrefetcher.shared.prefetchURLs(u)
    }
    func cancelPrefetch() {
        SDWebImagePrefetcher.shared.cancelPrefetching()
    }
}

// ✅ Estructura FeedItem movida aquí para ser pública y compartida
struct FeedItem: Identifiable {
    enum Label { case sponsored, foodieReview, none }
    let id: UUID
    let videoId: String? // ID real de Firestore (opcional para compatibilidad con datos mock)
    let authorId: String? // ✅ ID del autor para navegación a perfil
    let backgroundUrl: String
    let username: String
    let label: Label
    let hasStories: Bool
    let avatarUrl: String
    let title: String
    let description: String
    let soundTitle: String
    let likes: Int
    let comments: Int
    let shares: Int
    let videoUrl: String?
    let posterUrl: String?
    
    // Init actualizado
    init(
        id: UUID = UUID(),
        videoId: String? = nil,
        authorId: String? = nil, // ✅ Nuevo parámetro
        backgroundUrl: String,
        username: String,
        label: Label,
        hasStories: Bool,
        avatarUrl: String,
        title: String,
        description: String,
        soundTitle: String,
        likes: Int,
        comments: Int,
        shares: Int,
        videoUrl: String? = nil,
        posterUrl: String? = nil
    ) {
        self.id = id
        self.videoId = videoId
        self.authorId = authorId
        self.backgroundUrl = backgroundUrl
        self.username = username
        self.label = label
        self.hasStories = hasStories
        self.avatarUrl = avatarUrl
        self.title = title
        self.description = description
        self.soundTitle = soundTitle
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.videoUrl = videoUrl
        self.posterUrl = posterUrl
    }
}