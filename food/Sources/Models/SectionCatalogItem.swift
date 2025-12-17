import Foundation

public struct SectionCatalogItem: Identifiable, Codable {
    public let id: String
    public let name: String
    public let slug: String
    public let icon: String?
    public let sortOrder: Int
    public let isActive: Bool
    
    public init(id: String, name: String, slug: String, icon: String? = nil, sortOrder: Int = 0, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.slug = slug
        self.icon = icon
        self.sortOrder = sortOrder
        self.isActive = isActive
    }
}
