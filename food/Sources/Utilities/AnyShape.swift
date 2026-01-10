import SwiftUI

public struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    public init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}
