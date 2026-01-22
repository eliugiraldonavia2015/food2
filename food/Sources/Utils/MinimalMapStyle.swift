import Foundation

enum MapBaseStyleOption: String {
    case muted
    case light
    case dark
    case satellite
}

final class MinimalMapStyle {
    static var template: String? = "https://a.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png"
    static var base: MapBaseStyleOption = .muted
}
