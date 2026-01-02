import SwiftUI
import Combine
import SDWebImage

final class FeedViewModel: ObservableObject {
    private let storageKey: String
    
    // ✅ Fuente de Verdad: Videos descargados de Firestore
    @Published var videos: [FeedItem] = []
    @Published var isLoading = false
    
    @Published var currentIndex: Int {
        didSet { UserDefaults.standard.set(currentIndex, forKey: storageKey) }
    }

    init(storageKey: String) {
        self.storageKey = storageKey
        self.currentIndex = UserDefaults.standard.object(forKey: storageKey) as? Int ?? 0
        
        // 🚀 Carga inicial automática
        loadRecentVideos()
    }
    
    /// Carga videos frescos desde Firestore
    func loadRecentVideos() {
        guard !isLoading else { return }
        isLoading = true
        
        FeedService.shared.fetchRecentVideos { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let fetchedVideos):
                    // Convertir modelos de DB (Video) a modelos de Vista (FeedItem)
                    let items = fetchedVideos.map { self?.mapToFeedItem(video: $0) }
                    
                    // Si no hay videos, mantener vacío o poner placeholder si se desea
                    if let newItems = items as? [FeedItem], !newItems.isEmpty {
                        self?.videos.append(contentsOf: newItems)
                        // Prefetch de las primeras miniaturas
                        self?.prefetch(urls: newItems.prefix(3).map { $0.backgroundUrl })
                    }
                    
                case .failure(let error):
                    print("⚠️ Error cargando feed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Convierte el modelo crudo de DB al modelo visual
    private func mapToFeedItem(video: Video) -> FeedItem {
        // Por ahora usamos placeholders para datos que aun no tenemos en DB (avatar, soundTitle)
        return FeedItem(
            id: UUID(), // Usamos UUID local para la vista, pero mantenemos referencia al real si es necesario
            videoId: video.id, // ✅ Guardamos el ID real para likes/comentarios
            backgroundUrl: video.thumbnailUrl, // Usamos thumbnail mientras carga el video
            username: "Chef Foodie", // TODO: Cargar usuario real con fetchAuthorProfile
            label: .none,
            hasStories: false,
            avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2", // Placeholder
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