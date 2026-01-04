import SwiftUI

struct VerticalPager<Content: View>: UIViewRepresentable {
    let count: Int
    @Binding var index: Int
    let pageHeight: CGFloat?
    let content: (CGSize, Int) -> Content
    var onPullToRefresh: (() -> Void)? = nil // Callback para refresh
    
    init(count: Int, index: Binding<Int>, pageHeight: CGFloat? = nil, onPullToRefresh: (() -> Void)? = nil, @ViewBuilder content: @escaping (CGSize, Int) -> Content) {
        self.count = count
        self._index = index
        self.pageHeight = pageHeight
        self.onPullToRefresh = onPullToRefresh
        self.content = content
    }
    
    // ... (rest of initializers if needed, but the main one covers most cases)
    
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
        
        // Actualizar contenido
        context.coordinator.update(count: count, builder: content)
        
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
        
        // Posicionar en la página correcta
        let height = pageHeight ?? scroll.bounds.height
        if height > 0 {
            let targetY = CGFloat(index) * height
            if !context.coordinator.isAnimating && abs(scroll.contentOffset.y - targetY) > 1 {
                scroll.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
            }
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: VerticalPager
        var hosts: [UIHostingController<AnyView>] = []
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

        func update(count: Int, builder: @escaping (CGSize, Int) -> Content) {
            self.builder = builder
            
            // 🚀 REUSE STRATEGY: Only recreate hosts if absolutely necessary
            if hosts.count > count {
                // If we have more hosts than needed, remove excess
                hosts.removeLast(hosts.count - count)
            } else if hosts.count < count {
                // If we need more hosts, append new ones
                let newHosts = (hosts.count..<count).map { _ in UIHostingController(rootView: AnyView(EmptyView())) }
                hosts.append(contentsOf: newHosts)
            }
            // If equal, do nothing (reuse existing)
            
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

        // Método original para compatibilidad
        func layout(in scroll: UIScrollView) {
            let size = scroll.bounds.size
            layout(in: scroll, size: size)
        }
        
        // Nuevo método con tamaño específico
        func layout(in scroll: UIScrollView, size: CGSize) {
            guard let builder = builder else { return }
            if size.height <= 0 { return }
            
            // Usar el tamaño proporcionado
            let pageSize = size
            
            for (i, host) in hosts.enumerated() {
                host.rootView = AnyView(builder(pageSize, i))
                let view = host.view!
                if view.superview == nil { scroll.addSubview(view) }
                
                // Cada página toca exactamente a la siguiente
                view.frame = CGRect(
                    x: 0, 
                    y: CGFloat(i) * pageSize.height, 
                    width: pageSize.width, 
                    height: pageSize.height
                )
            }
            
            if lastSize != pageSize || lastCount != hosts.count {
                scroll.contentSize = CGSize(
                    width: pageSize.width, 
                    height: pageSize.height * CGFloat(hosts.count)
                )
                lastSize = pageSize
                lastCount = hosts.count
            }
            
            let targetY = CGFloat(parent.index) * pageSize.height
            if !isAnimating && abs(scroll.contentOffset.y - targetY) > 1 {
                scroll.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
            }
        }

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
            
            // Terminar animación después de un delay simulado (o cuando el padre quiera, pero aquí lo cerramos rápido para UX)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sender.endRefreshing()
            }
        }
    }
}
