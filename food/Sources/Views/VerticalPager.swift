import SwiftUI

struct VerticalPager<Content: View>: UIViewRepresentable {
    let count: Int
    @Binding var index: Int
    let pageHeight: CGFloat? // Nueva: altura específica opcional para cada página
    let content: (CGSize, Int) -> Content
    
    // Inicializador compatible hacia atrás
    init(count: Int, index: Binding<Int>, @ViewBuilder content: @escaping (CGSize, Int) -> Content) {
        self.count = count
        self._index = index
        self.pageHeight = nil
        self.content = content
    }
    
    // Nuevo inicializador con altura específica
    init(count: Int, index: Binding<Int>, pageHeight: CGFloat, @ViewBuilder content: @escaping (CGSize, Int) -> Content) {
        self.count = count
        self._index = index
        self.pageHeight = pageHeight
        self.content = content
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = false
        scroll.isPagingEnabled = true
        scroll.decelerationRate = .fast
        scroll.delaysContentTouches = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset = .zero
        scroll.scrollIndicatorInsets = .zero
        scroll.automaticallyAdjustsScrollIndicatorInsets = false
        scroll.delegate = context.coordinator
        context.coordinator.install(in: scroll)
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        // Obtener la altura de página (específica o del scroll view)
        let height = pageHeight ?? scroll.bounds.height
        
        // Si la altura es 0, posponer el layout
        if height == 0 {
            DispatchQueue.main.async {
                context.coordinator.layout(in: scroll)
            }
            return
        }
        
        // Asegurar que no hay insets (estilo TikTok)
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset = .zero
        scroll.scrollIndicatorInsets = .zero
        
        // Actualizar contenido
        context.coordinator.update(count: count, builder: content)
        
        // Si tenemos altura específica, usar tamaño personalizado
        if let pageHeight = pageHeight {
            let size = CGSize(width: scroll.bounds.width, height: pageHeight)
            context.coordinator.layout(in: scroll, size: size)
        } else {
            // Comportamiento original: usar altura del scroll view
            context.coordinator.layout(in: scroll)
        }
        
        // Posicionar en la página correcta
        let targetY = CGFloat(index) * height
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

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            let pageHeight = lastSize.height
            let y = scrollView.contentOffset.y
            let next = Int(round(y / pageHeight))
            let target = CGPoint(x: 0, y: CGFloat(next) * pageHeight)
            targetContentOffset.pointee = target
            isAnimating = true
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let pageHeight = lastSize.height
            let idx = Int(round(scrollView.contentOffset.y / pageHeight))
            isAnimating = false
            DispatchQueue.main.async { self.parent.index = idx }
        }
        
        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            isAnimating = false
        }
    }
}