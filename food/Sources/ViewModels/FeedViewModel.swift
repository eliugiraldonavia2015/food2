import SwiftUI

final class FeedViewModel: ObservableObject {
    @AppStorage("feed.currentIndex") private var storedIndex: Int = 0
    @Published var currentIndex: Int {
        didSet { storedIndex = currentIndex }
    }

    init() {
        currentIndex = storedIndex
    }
}