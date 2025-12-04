import SwiftUI

struct VerticalPager<Content: View>: UIViewRepresentable {
    let count: Int
    @Binding var index: Int
    let content: (CGSize, Int) -> Content

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = false
        scroll.isPagingEnabled = true
        scroll.decelerationRate = .fast
        scroll.delaysContentTouches = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.delegate = context.coordinator
        context.coordinator.install(in: scroll)
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.update(count: count, builder: content)
        context.coordinator.layout(in: scroll)
        let pageHeight = scroll.bounds.height
        if pageHeight == 0 {
            DispatchQueue.main.async { context.coordinator.layout(in: scroll) }
            return
        }
        let targetY = CGFloat(index) * pageHeight
        if !context.coordinator.isAnimating && abs(scroll.contentOffset.y - targetY) > 1 {
            scroll.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: VerticalPager
        var hosts: [UIHostingController<AnyView>] = []
        var builder: ((CGSize, Int) -> Content)?
        var isAnimating = false
        var lastSize: CGSize = .zero
        var lastCount: Int = 0
        let upThreshold: CGFloat = 0.5
        let downThreshold: CGFloat = 0.5

        init(_ parent: VerticalPager) { self.parent = parent }

        func install(in scroll: UIScrollView) {
            scroll.subviews.forEach { $0.removeFromSuperview() }
        }

        func update(count: Int, builder: @escaping (CGSize, Int) -> Content) {
            self.builder = builder
            if hosts.count != count {
                hosts = (0..<count).map { _ in UIHostingController(rootView: AnyView(EmptyView())) }
            }
            if count > 0 {
                if parent.index >= count { DispatchQueue.main.async { self.parent.index = count - 1 } }
            } else {
                if parent.index != 0 { DispatchQueue.main.async { self.parent.index = 0 } }
            }
        }

        func layout(in scroll: UIScrollView) {
            let size = scroll.bounds.size
            guard let builder = builder else { return }
            if size.height <= 0 { return }
            for (i, host) in hosts.enumerated() {
                host.rootView = AnyView(builder(size, i))
                let view = host.view!
                if view.superview == nil { scroll.addSubview(view) }
                view.frame = CGRect(x: 0, y: CGFloat(i) * size.height, width: size.width, height: size.height)
            }
            if lastSize != size || lastCount != hosts.count {
                scroll.contentSize = CGSize(width: size.width, height: size.height * CGFloat(hosts.count))
                lastSize = size
                lastCount = hosts.count
            }
            let targetY = CGFloat(parent.index) * size.height
            if !isAnimating && abs(scroll.contentOffset.y - targetY) > 1 {
                scroll.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
            }
        }

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            let h = max(scrollView.bounds.height, 1)
            let y = scrollView.contentOffset.y
            let next = Int(round(y / h))
            let target = CGPoint(x: 0, y: CGFloat(next) * h)
            targetContentOffset.pointee = target
            isAnimating = true
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let h = max(scrollView.bounds.height, 1)
            let idx = Int(round(scrollView.contentOffset.y / h))
            isAnimating = false
            DispatchQueue.main.async { self.parent.index = idx }
        }
    }
}
