import SwiftUI

struct VerticalPager<Content: View>: UIViewRepresentable {
    let count: Int
    @Binding var index: Int
    let pageHeight: CGFloat?
    let content: (CGSize, Int) -> Content
    var onPullToRefresh: (() -> Void)? = nil
    
    init(count: Int, index: Binding<Int>, pageHeight: CGFloat? = nil, onPullToRefresh: (() -> Void)? = nil, @ViewBuilder content: @escaping (CGSize, Int) -> Content) {
        self.count = count
        self._index = index
        self.pageHeight = pageHeight
        self.onPullToRefresh = onPullToRefresh
        self.content = content
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = true // Necesario para pull-to-refresh
        scroll.isPagingEnabled = true
        scroll.decelerationRate = .fast
        scroll.delaysContentTouches = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset = .zero
        scroll.scrollIndicatorInsets = .zero
        scroll.automaticallyAdjustsScrollIndicatorInsets = false
        scroll.delegate = context.coordinator
        
        // Agregar Refresh Control nativo (Estilo iOS) o customizado
        if let _ = onPullToRefresh {
            let refreshControl = UIRefreshControl()
            refreshControl.tintColor = .white
            refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh), for: .valueChanged)
            scroll.refreshControl = refreshControl
        }
        
        context.coordinator.install(in: scroll)
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        // Asegurar que no hay insets (estilo TikTok)
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset = .zero
        scroll.scrollIndicatorInsets = .zero
        
        // Actualizar referencia al padre y builder
        context.coordinator.parent = self
        context.coordinator.update(builder: content)
        
        // Usar siempre la altura específica si está disponible
        if let pageHeight = pageHeight {
            let size = CGSize(width: scroll.bounds.width, height: pageHeight)
            context.coordinator.layout(in: scroll, size: size)
        } else {
            // Si no hay altura específica, usar altura del scroll view
            let height = scroll.bounds.height
            if height > 0 {
                context.coordinator.layout(in: scroll)
            } else {
                // Si la altura es 0, posponer el layout
                DispatchQueue.main.async {
                    context.coordinator.layout(in: scroll)
                }
                return
            }
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: VerticalPager
        
        // 🚀 OPTIMIZATION: View Recycling (Sliding Window)
        // Only keep controllers for visible items + buffer
        var visibleControllers: [Int: UIHostingController<AnyView>] = [:]
        var recycledControllers: [UIHostingController<AnyView>] = []
        
        var builder: ((CGSize, Int) -> Content)?
        var isAnimating = false
        var lastSize: CGSize = .zero
        var lastCount: Int = 0
        var startOffsetY: CGFloat = 0
        let upThreshold: CGFloat = 0.20
        let downThreshold: CGFloat = 0.15

        init(_ parent: VerticalPager) { self.parent = parent }

        func install(in scroll: UIScrollView) {
            scroll.subviews.forEach { $0.removeFromSuperview() }
        }

        func update(builder: @escaping (CGSize, Int) -> Content) {
            self.builder = builder
            
            // Bounds check
            let count = parent.count
            if count > 0 {
                if parent.index >= count { 
                    DispatchQueue.main.async { self.parent.index = count - 1 } 
                }
            } else {
                if parent.index != 0 { 
                    DispatchQueue.main.async { self.parent.index = 0 } 
                }
            }
        }

        func layout(in scroll: UIScrollView, size: CGSize? = nil) {
            let pageSize = size ?? scroll.bounds.size
            guard pageSize.height > 0, let builder = builder else { return }
            
            let count = parent.count
            
            // 1. Update Content Size
            let contentHeight = pageSize.height * CGFloat(count)
            if scroll.contentSize.height != contentHeight || scroll.contentSize.width != pageSize.width {
                scroll.contentSize = CGSize(width: pageSize.width, height: contentHeight)
            }
            
            lastSize = pageSize
            lastCount = count
            
            // 2. Determine visible range (Current +/- 1)
            let currentIndex = parent.index
            let minIndex = max(0, currentIndex - 1)
            let maxIndex = min(count - 1, currentIndex + 1)
            var neededIndices = Set<Int>()
            if count > 0 {
                for i in minIndex...maxIndex {
                    neededIndices.insert(i)
                }
            }
            
            // 3. Remove invisible controllers
            let indicesToRemove = visibleControllers.keys.filter { !neededIndices.contains($0) }
            for index in indicesToRemove {
                guard let controller = visibleControllers.removeValue(forKey: index) else { continue }
                controller.view.removeFromSuperview()
                controller.rootView = AnyView(EmptyView())
                recycledControllers.append(controller)
            }
            
            // 4. Add/Update visible controllers
            for index in neededIndices {
                if let controller = visibleControllers[index] {
                    // Update existing
                    controller.rootView = AnyView(builder(pageSize, index))
                    controller.view.frame = CGRect(
                        x: 0, 
                        y: CGFloat(index) * pageSize.height, 
                        width: pageSize.width, 
                        height: pageSize.height
                    )
                } else {
                    // Recycle or create
                    let controller: UIHostingController<AnyView>
                    if let recycled = recycledControllers.popLast() {
                        controller = recycled
                    } else {
                        controller = UIHostingController(rootView: AnyView(EmptyView()))
                        controller.view.backgroundColor = .clear
                    }
                    
                    controller.rootView = AnyView(builder(pageSize, index))
                    controller.view.frame = CGRect(
                        x: 0, 
                        y: CGFloat(index) * pageSize.height, 
                        width: pageSize.width, 
                        height: pageSize.height
                    )
                    
                    if controller.view.superview != scroll {
                        scroll.addSubview(controller.view)
                    }
                    visibleControllers[index] = controller
                }
            }
            
            // 5. Sync Offset if needed (only when not interacting)
            let targetY = CGFloat(parent.index) * pageSize.height
            if !scroll.isDragging && !scroll.isDecelerating && !isAnimating {
                if abs(scroll.contentOffset.y - targetY) > 1 {
                    scroll.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
                }
            }
        }
        
        // 🚀 Trigger layout on scroll to recycle views dynamically
        func scrollViewDidScroll(_ scrollView: UIScrollView) { }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            startOffsetY = scrollView.contentOffset.y
        }
        
        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            let pageHeight = lastSize.height
            guard pageHeight > 0 else { return }
            let y = scrollView.contentOffset.y
            let current = parent.index
            let fraction = y / pageHeight
            var progress = fraction - CGFloat(current)
            progress = max(0, min(progress, 1))
            let deltaPages = max(-1, min(1, (y - startOffsetY) / pageHeight))
            
            var next = current
            var dir = 0
            if velocity.y < 0 { dir = -1 }
            else if velocity.y > 0 { dir = 1 }
            else if deltaPages < 0 { dir = -1 }
            else if deltaPages > 0 { dir = 1 }
            
            if dir == -1 {
                next = progress <= upThreshold ? current - 1 : current
            } else if dir == 1 {
                next = progress >= downThreshold ? current + 1 : current
            } else {
                if progress >= downThreshold { next = current + 1 }
                else if progress <= upThreshold { next = current - 1 }
                else { next = current }
            }
            
            next = max(0, min(next, lastCount > 0 ? lastCount - 1 : 0))
            let target = CGPoint(x: 0, y: CGFloat(next) * pageHeight)
            targetContentOffset.pointee = target
            isAnimating = true
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let pageHeight = lastSize.height
            guard pageHeight > 0 else { return }
            var idx = Int(round(scrollView.contentOffset.y / pageHeight))
            idx = max(0, min(idx, lastCount > 0 ? lastCount - 1 : 0))
            isAnimating = false
            DispatchQueue.main.async { self.parent.index = idx }
        }
        
        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            isAnimating = false
        }
        
        @objc func handleRefresh(_ sender: UIRefreshControl) {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Ejecutar callback
            parent.onPullToRefresh?()
            
            // Terminar animación después de un delay simulado
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sender.endRefreshing()
            }
        }
    }
}
