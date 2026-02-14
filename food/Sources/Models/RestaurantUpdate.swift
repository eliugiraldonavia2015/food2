import Foundation

struct RestaurantUpdate: Identifiable {
    let id = UUID()
    let name: String
    let logo: String
    let hasUpdate: Bool
}
