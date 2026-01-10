import SwiftUI
import UIKit

enum Colors {
    static let fuchsia = Color(red: 244/255, green: 37/255, blue: 123/255)
    static let fuchsiaUI = UIColor(red: 244/255, green: 37/255, blue: 123/255, alpha: 1.0)
}

extension Color {
    static let fuchsia = Colors.fuchsia
}

extension UIColor {
    static let fuchsia = Colors.fuchsiaUI
}
