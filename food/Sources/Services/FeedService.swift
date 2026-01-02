import Foundation
import FirebaseFirestore
import Combine

public final class FeedService {
    public static let shared = FeedService()
    private let db = Firestore.firestore()
    
    // Cache simple para evitar lecturas excesivas
    private var lastDocument: DocumentSnapshot?
    private var isFetching = false
    
    private init() {}
    
    /// Obtiene los videos más recientes ordenados por ID (ULID)
    /// Esto garantiza orden cronológico inverso sin necesidad de índices complejos
    public func fetchRecentVideos(limit: Int = 10, completion: @escaping (Result<[Video], Error>) -> Void) {
        guard !isFetching else { return }
        isFetching = true
        
        var query = db.collection("videos")
            .order(by: "id", descending: true) // ULID ordenable lexicográficamente
            .limit(to: limit)
            
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            defer { self?.isFetching = false }
            
            if let error = error {
                print("❌ [FeedService] Error fetching videos: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.success([]))
                return
            }
            
            self?.lastDocument = snapshot.documents.last
            
            let videos: [Video] = snapshot.documents.compactMap { doc in
                return Video(document: doc)
            }
            
            print("✅ [FeedService] Fetched \(videos.count) videos from Firestore")
            completion(.success(videos))
        }
    }
    
    /// Reinicia la paginación (pull to refresh)
    public func resetPagination() {
        lastDocument = nil
    }
    
    /// Obtiene información básica del autor para mostrar en el feed
    public func fetchAuthorProfile(userId: String, completion: @escaping (AuthorProfile?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            
            let profile = AuthorProfile(
                userId: userId,
                username: data["username"] as? String ?? "User",
                photoUrl: data["photoURL"] as? String ?? "",
                isVerified: false // TODO: Agregar campo verified en user
            )
            completion(profile)
        }
    }
}

// Modelo simplificado para la UI del Feed
public struct AuthorProfile {
    public let userId: String
    public let username: String
    public let photoUrl: String
    public let isVerified: Bool
}
