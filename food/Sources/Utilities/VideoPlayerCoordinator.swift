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
        // Debounce slightly to avoid rapid switching causing issues? 
        // For now, direct assignment is cleaner for responsiveness.
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
