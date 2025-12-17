import Foundation

public struct MenuItem: Identifiable, Codable {
    public let id: String
    public let restaurantId: String
    public let restaurantPrefix: String
    public let menuId: String?
    public let sectionId: String
    public let name: String
    public let description: String?
    public let imageUrls: [String]
    public let price: Double
    public let currency: String
    public let sortOrder: Int
    public let isPublished: Bool
    public let isAvailable: Bool
    public let categoryCanonical: String?
    public let tags: [String]
    public let createdAt: Date
    public let updatedAt: Date
    public let updatedBy: String?
    
    public init(id: String, restaurantId: String, restaurantPrefix: String, menuId: String? = nil, sectionId: String, name: String, description: String? = nil, imageUrls: [String] = [], price: Double, currency: String = "USD", sortOrder: Int = 0, isPublished: Bool = false, isAvailable: Bool = true, categoryCanonical: String? = nil, tags: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date(), updatedBy: String? = nil) {
        self.id = id
        self.restaurantId = restaurantId
        self.restaurantPrefix = restaurantPrefix
        self.menuId = menuId
        self.sectionId = sectionId
        self.name = name
        self.description = description
        self.imageUrls = imageUrls
        self.price = price
        self.currency = currency
        self.sortOrder = sortOrder
        self.isPublished = isPublished
        self.isAvailable = isAvailable
        self.categoryCanonical = categoryCanonical
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.updatedBy = updatedBy
    }
}
