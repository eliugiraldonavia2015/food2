import Foundation

enum MapBaseStyleOption: String {
    case muted
    case light
    case dark
    case satellite
}

final class MinimalMapStyle {
    static var template: String? = nil
    static var base: MapBaseStyleOption = .muted
}
