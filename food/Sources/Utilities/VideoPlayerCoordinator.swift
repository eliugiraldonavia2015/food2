import SwiftUI
import Combine

final class VideoPlayerCoordinator: ObservableObject {
    static let shared = VideoPlayerCoordinator()
    @Published var activeVideoId: UUID?
    
    // Add a pause command to stop all playback (e.g., when switching tabs)
    func pauseAll() {
        activeVideoId = nil
    }
    
    private init() {}
    
    func setActive(_ id: UUID) {
        // Enforce strict one-player rule
        if activeVideoId != id {
            // Log for debugging if needed: print("Switching audio focus from \(String(describing: activeVideoId)) to \(id)")
            activeVideoId = id
        }
    }
    
    func stop(_ id: UUID) {
        if activeVideoId == id {
            activeVideoId = nil
        }
    }
}
