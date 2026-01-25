import UIKit

// MARK: - Global Orientation Lock
// This file enforces portrait mode across the entire application by overriding
// supportedInterfaceOrientations for key view controllers.

extension UINavigationController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}

extension UITabBarController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}

// Forcing AVPlayerViewController to be portrait only if it tries to rotate
import AVKit

extension AVPlayerViewController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
}

// Forcing UIImagePickerController to be portrait only (mostly for Camera/Gallery)
extension UIImagePickerController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
}
