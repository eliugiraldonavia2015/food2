import Foundation

public struct MenuSection: Identifiable, Codable {
    public let id: String
    public let restaurantId: String
    public let catalogId: String
    public let name: String
    public let description: String?
    public let sortOrder: Int
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(id: String, restaurantId: String, catalogId: String, name: String, description: String? = nil, sortOrder: Int = 0, isActive: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.restaurantId = restaurantId
        self.catalogId = catalogId
        self.name = name
        self.description = description
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
