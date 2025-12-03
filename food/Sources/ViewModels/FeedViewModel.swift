import SwiftUI
import Combine
import SDWebImage
import SDWebImage

final class FeedViewModel: ObservableObject {
    @AppStorage("feed.currentIndex") private var storedIndex: Int = 0
    @Published var currentIndex: Int = 0 {
        didSet { storedIndex = currentIndex }
    }

    init() {
        currentIndex = storedIndex
    }

    func prefetch(urls: [String]) {
        let u = urls.compactMap { URL(string: $0) }
        SDWebImagePrefetcher.shared.prefetchURLs(u)
    }
    func cancelPrefetch() {
        SDWebImagePrefetcher.shared.cancelPrefetching()
    }
}