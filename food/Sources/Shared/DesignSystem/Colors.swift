import SwiftUI
import UIKit

enum Colors {
    // SwiftUI
    static let fuchsia = Color(red: 255/255, green: 0/255, blue: 132/255)

    // UIKit
    static let fuchsiaUI = UIColor(red: 255/255, green: 0/255, blue: 132/255, alpha: 1.0)
}

extension Color {
    static let fuchsia = Colors.fuchsia
}

extension UIColor {
    static let fuchsia = Colors.fuchsiaUI
}
