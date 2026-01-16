import SwiftUI
import UIKit

enum Colors {
    // SwiftUI
    static let fuchsia = Color(red: 255/255, green: 0/255, blue: 132/255)
    static let brandGreen = Color(red: 49/255, green: 209/255, blue: 87/255)

    // UIKit
    static let fuchsiaUI = UIColor(red: 255/255, green: 0/255, blue: 132/255, alpha: 1.0)
    static let brandGreenUI = UIColor(red: 49/255, green: 209/255, blue: 87/255, alpha: 1.0)
}

extension Color {
    static let fuchsia = Colors.fuchsia
    static let brandGreen = Colors.brandGreen
}

extension UIColor {
    static let fuchsia = Colors.fuchsiaUI
    static let brandGreen = Colors.brandGreenUI
}
