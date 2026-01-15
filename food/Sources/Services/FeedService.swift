import Foundation
import FirebaseFirestore
import Combine

public final class FeedService {
    public static let shared = FeedService()
    // ✅ Usar la misma configuración de base de datos que DatabaseService
    private let db: Firestore
    
    // Cache simple para evitar lecturas excesivas
    private var lastDocumentByKey: [String: DocumentSnapshot] = [:]
    private var isFetchingByKey: [String: Bool] = [:]
    private var lastBatchCountByKey: [String: Int] = [:]
    private var lastLimitByKey: [String: Int] = [:]
    
    private init() {
        // Inicializar con la base de datos correcta "logincloud"
        self.db = Firestore.firestore(database: "logincloud")
    }
    
    /// Obtiene los videos más recientes ordenados por ID (ULID)
    /// Esto garantiza orden cronológico inverso sin necesidad de índices complejos
    public func fetchRecentVideos(limit: Int = 10, completion: @escaping (Result<[Video], Error>) -> Void) {
        fetchRecentVideos(limit: limit, cursorKey: "default", completion: completion)
    }

    public func fetchRecentVideos(limit: Int = 10, cursorKey: String, completion: @escaping (Result<[Video], Error>) -> Void) {
        if isFetchingByKey[cursorKey] == true { return }
        isFetchingByKey[cursorKey] = true
        lastLimitByKey[cursorKey] = limit
        
        var query = db.collection("videos")
            .order(by: "id", descending: true) // ULID ordenable lexicográficamente
            .limit(to: limit)
            
        if let lastDoc = lastDocumentByKey[cursorKey] {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            defer { self?.isFetchingByKey[cursorKey] = false }
            
            if let error = error {
                print("❌ [FeedService] Error fetching videos: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                self?.lastBatchCountByKey[cursorKey] = 0
                completion(.success([]))
                return
            }
            
            self?.lastDocumentByKey[cursorKey] = snapshot.documents.last
            self?.lastBatchCountByKey[cursorKey] = snapshot.documents.count
            
            let videos: [Video] = snapshot.documents.compactMap { doc in
                return Video(document: doc)
            }
            
            print("✅ [FeedService] Fetched \(videos.count) videos from Firestore")
            completion(.success(videos))
        }
    }
    
    /// Reinicia la paginación (pull to refresh)
    public func resetPagination() {
        resetPagination(cursorKey: "default")
    }

    public func resetPagination(cursorKey: String) {
        lastDocumentByKey[cursorKey] = nil
        isFetchingByKey[cursorKey] = false
        lastBatchCountByKey[cursorKey] = nil
        lastLimitByKey[cursorKey] = nil
    }

    public func resetAllPagination() {
        lastDocumentByKey.removeAll()
        isFetchingByKey.removeAll()
        lastBatchCountByKey.removeAll()
        lastLimitByKey.removeAll()
    }
    
    /// Comprueba si hay más contenido disponible (útil para UI)
    public var hasMoreContent: Bool {
        hasMoreContent(cursorKey: "default")
    }

    public func hasMoreContent(cursorKey: String) -> Bool {
        guard let lastCount = lastBatchCountByKey[cursorKey] else { return true }
        guard let lastLimit = lastLimitByKey[cursorKey] else { return lastCount > 0 }
        return lastCount >= lastLimit
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
