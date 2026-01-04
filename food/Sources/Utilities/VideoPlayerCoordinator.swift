import SwiftUI
import Combine

final class VideoPlayerCoordinator: ObservableObject {
    static let shared = VideoPlayerCoordinator()
    @Published var activeVideoId: UUID?
    
    private init() {}
    
    func setActive(_ id: UUID) {
        if activeVideoId != id {
            activeVideoId = id
        }
    }
    
    func stop(_ id: UUID) {
        if activeVideoId == id {
            activeVideoId = nil
        }
    }
}
