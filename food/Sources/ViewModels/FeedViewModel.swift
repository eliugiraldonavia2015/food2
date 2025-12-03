import SwiftUI
import Combine
import SDWebImage

final class FeedViewModel: ObservableObject {
    private let storageKey: String
    @Published var currentIndex: Int {
        didSet { UserDefaults.standard.set(currentIndex, forKey: storageKey) }
    }

    init(storageKey: String) {
        self.storageKey = storageKey
        self.currentIndex = UserDefaults.standard.object(forKey: storageKey) as? Int ?? 0
    }

    func prefetch(urls: [String]) {
        let u = urls.compactMap { URL(string: $0) }
        SDWebImagePrefetcher.shared.prefetchURLs(u)
    }
    func cancelPrefetch() {
        SDWebImagePrefetcher.shared.cancelPrefetching()
    }
}