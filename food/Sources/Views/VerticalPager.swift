import SwiftUI

struct VerticalPager<Content: View>: UIViewRepresentable {
    let count: Int
    @Binding var index: Int
    let content: (CGSize, Int) -> Content

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = true
        scroll.isPagingEnabled = false
        scroll.delegate = context.coordinator
        context.coordinator.install(in: scroll)
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.update(count: count, builder: content)
        context.coordinator.layout(in: scroll)
        let pageHeight = scroll.bounds.height
        let targetY = CGFloat(index) * (pageHeight == 0 ? 1 : pageHeight)
        if abs(scroll.contentOffset.y - targetY) > 1 {
            scroll.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: VerticalPager
        var hosts: [UIHostingController<AnyView>] = []
        var builder: ((CGSize, Int) -> Content)?

        init(_ parent: VerticalPager) { self.parent = parent }

        func install(in scroll: UIScrollView) {
            scroll.subviews.forEach { $0.removeFromSuperview() }
        }

        func update(count: Int, builder: @escaping (CGSize, Int) -> Content) {
            self.builder = builder
            if hosts.count != count {
                hosts = (0..<count).map { _ in UIHostingController(rootView: AnyView(EmptyView())) }
            }
        }

        func layout(in scroll: UIScrollView) {
            let size = scroll.bounds.size
            guard size.height > 0, let builder = builder else { return }
            for (i, host) in hosts.enumerated() {
                host.rootView = AnyView(builder(size, i))
                let view = host.view!
                if view.superview == nil { scroll.addSubview(view) }
                view.frame = CGRect(x: 0, y: CGFloat(i) * size.height, width: size.width, height: size.height)
            }
            scroll.contentSize = CGSize(width: size.width, height: size.height * CGFloat(hosts.count))
        }

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            let h = max(scrollView.bounds.height, 1)
            let y = scrollView.contentOffset.y
            let current = Int(floor(y / h))
            let remainder = y - CGFloat(current) * h
            let fraction = remainder / h

            var next = current
            if velocity.y > 0 {
                if fraction > 0.7 { next = min(current + 1, hosts.count - 1) }
            } else if velocity.y < 0 {
                if fraction < 0.3 { next = max(current - 1, 0) }
            } else {
                next = fraction > 0.5 ? min(current + 1, hosts.count - 1) : current
            }

            let target = CGPoint(x: 0, y: CGFloat(next) * h)
            targetContentOffset.pointee = scrollView.contentOffset
            isAnimating = true
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
                scrollView.setContentOffset(target, animated: false)
            } completion: { _ in
                self.isAnimating = false
                DispatchQueue.main.async { self.parent.index = next }
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let h = max(scrollView.bounds.height, 1)
            let idx = Int(round(scrollView.contentOffset.y / h))
            DispatchQueue.main.async { self.parent.index = idx }
        }
    }
}