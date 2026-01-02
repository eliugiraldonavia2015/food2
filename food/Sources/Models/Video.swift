import Foundation
import FirebaseFirestore

public struct Video: Identifiable, Codable {
    public let id: String // ULID del video (nombre del archivo en Bunny)
    public let userId: String // ID del autor
    public let title: String
    public let description: String
    public let videoUrl: String // URL completa del video en Bunny
    public let thumbnailUrl: String // URL completa del thumbnail
    public let createdAt: Date
    public let duration: Double
    
    // Contadores (se actualizarán con Cloud Functions en el futuro)
    public let likes: Int
    public let comments: Int
    public let shares: Int
    
    // Metadatos técnicos para trazabilidad
    public let width: Int?
    public let height: Int?
    public let fileId: String? // ID interno si se necesita diferenciar versión
    
    public init(
        id: String,
        userId: String,
        title: String,
        description: String,
        videoUrl: String,
        thumbnailUrl: String,
        duration: Double,
        width: Int? = nil,
        height: Int? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.videoUrl = videoUrl
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = Date()
        self.duration = duration
        self.likes = 0
        self.comments = 0
        self.shares = 0
        self.width = width
        self.height = height
        self.fileId = id // Por defecto usamos el mismo ID
    }
    
    // Inicializador para decodificar desde Firestore
    public init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let videoUrl = data["videoUrl"] as? String,
              let thumbnailUrl = data["thumbnailUrl"] as? String else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.title = data["title"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.videoUrl = videoUrl
        self.thumbnailUrl = thumbnailUrl
        self.duration = data["duration"] as? Double ?? 0.0
        
        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
        
        self.likes = data["likes"] as? Int ?? 0
        self.comments = data["comments"] as? Int ?? 0
        self.shares = data["shares"] as? Int ?? 0
        self.width = data["width"] as? Int
        self.height = data["height"] as? Int
        self.fileId = data["fileId"] as? String
    }
    
    // Convertir a diccionario para Firestore
    public var dictionary: [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "title": title,
            "description": description,
            "videoUrl": videoUrl,
            "thumbnailUrl": thumbnailUrl,
            "createdAt": Timestamp(date: createdAt),
            "duration": duration,
            "likes": likes,
            "comments": comments,
            "shares": shares,
            "width": width ?? 0,
            "height": height ?? 0,
            "fileId": fileId ?? id
        ]
    }
}
