import SwiftUI

struct ShareOverlayView: View {
    enum Theme {
        case dark
        case light
    }
    
    struct Person: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
    }
    struct ActionItem: Identifiable {
        let id = UUID()
        let title: String
        let systemIcon: String
        let color: Color
    }

    let onClose: () -> Void
    let showsMoreOptions: Bool
    let theme: Theme
    @State private var sent: Set<UUID> = []
    private let bottomExtraSpacing: CGFloat = 14
    
    init(
        onClose: @escaping () -> Void,
        showsMoreOptions: Bool = true,
        theme: Theme = .dark
    ) {
        self.onClose = onClose
        self.showsMoreOptions = showsMoreOptions
        self.theme = theme
    }

    private let people: [Person] = [
        .init(name: "María", emoji: "👩"),
        .init(name: "Juan", emoji: "👨"),
        .init(name: "Laura", emoji: "👩"),
        .init(name: "Pedro", emoji: "👨"),
        .init(name: "Ana", emoji: "👩"),
        .init(name: "Carlos", emoji: "👨")
    ]

    private let shareTargets: [ActionItem] = [
        .init(title: "Instagram", systemIcon: "bubble.right", color: .pink),
        .init(title: "Telegram", systemIcon: "paperplane.fill", color: .cyan),
        .init(title: "Facebook", systemIcon: "message.fill", color: .blue),
        .init(title: "Correo", systemIcon: "envelope.fill", color: .white),
        .init(title: "X", systemIcon: "xmark.square", color: .white),
        .init(title: "Más", systemIcon: "ellipsis", color: .white)
    ]

    private let moreOptions: [ActionItem] = [
        .init(title: "Denunciar", systemIcon: "exclamationmark.triangle", color: .white),
        .init(title: "No me interesa", systemIcon: "eye.slash", color: .white),
        .init(title: "Descargar", systemIcon: "arrow.down.circle", color: .white),
        .init(title: "Promocionar", systemIcon: "chart.line.uptrend.xyaxis", color: .white),
        .init(title: "Velocidad", systemIcon: "speedometer", color: .white),
        .init(title: "Receta", systemIcon: "book", color: .white),
        .init(title: "Ingredientes", systemIcon: "fork.knife", color: .white)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Dimming Background with tap-to-dismiss
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(DesignConstants.Animation.sheetPresentation) {
                            onClose()
                        }
                    }
                    .transition(.opacity)
                    .zIndex(0)
                
                sheet(bottomInset: geo.safeAreaInsets.bottom)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(DesignConstants.Animation.sheetTransition)
                    .zIndex(1)
            }
        }
        .ignoresSafeArea()
    }

    private func sheet(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            header
            Divider().background(dividerColor)
            section(title: "Enviar a") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(people) { p in
                            personItem(p)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
            section(title: "Compartir en") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(shareTargets) { t in
                            actionItem(t)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
            if showsMoreOptions {
                section(title: "Más opciones") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(moreOptions) { t in
                                actionItem(t)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, bottomInset + bottomExtraSpacing)
        .background(sheetBackgroundColor)
        .clipShape(FullMenuRoundedCorners(radius: DesignConstants.Layout.cornerRadius, corners: [.topLeft, .topRight]))
        .shadow(
            color: DesignConstants.Layout.sheetShadowColor, 
            radius: DesignConstants.Layout.sheetShadowRadius, 
            x: 0, 
            y: DesignConstants.Layout.sheetShadowY
        )
        .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        HStack {
            Text("Compartir")
                .foregroundColor(primaryTextColor)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            Button(action: {
                withAnimation(DesignConstants.Animation.sheetPresentation) {
                    onClose()
                }
            }) {
                ZStack {
                    Circle().fill(closeButtonBackgroundColor).frame(width: 34, height: 34)
                    Image(systemName: "xmark")
                        .foregroundColor(primaryTextColor)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .foregroundColor(primaryTextColor)
                .font(.system(size: 16, weight: .semibold))
            content()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func personItem(_ p: Person) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(personCircleBackgroundColor).frame(width: 56, height: 56)
                Text(p.emoji).font(.system(size: 26))
                if sent.contains(p.id) {
                    Circle().fill(Color.green).frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            Text(p.name)
                .foregroundColor(primaryTextColor)
                .font(.system(size: 12))
        }
        .onTapGesture {
            withAnimation(DesignConstants.Animation.stagedContent) {
                if sent.contains(p.id) { sent.remove(p.id) } else { sent.insert(p.id) }
            }
        }
    }

    private func actionItem(_ t: ActionItem) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 14)
                .fill(actionBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(actionBorderColor, lineWidth: 1)
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: t.systemIcon)
                        .foregroundColor(iconColor(for: t))
                        .font(.system(size: 20, weight: .bold))
                )
            Text(t.title)
                .foregroundColor(primaryTextColor)
                .font(.system(size: 12))
        }
    }
    
    private var sheetBackgroundColor: Color {
        switch theme {
        case .dark: return .black
        case .light: return .white
        }
    }
    
    private var primaryTextColor: Color {
        switch theme {
        case .dark: return .white
        case .light: return .black
        }
    }
    
    private var dividerColor: Color {
        switch theme {
        case .dark: return Color.white.opacity(0.08)
        case .light: return Color.black.opacity(0.08)
        }
    }
    
    private var closeButtonBackgroundColor: Color {
        switch theme {
        case .dark: return Color.white.opacity(0.08)
        case .light: return Color.black.opacity(0.06)
        }
    }
    
    private var personCircleBackgroundColor: Color {
        switch theme {
        case .dark: return Color.white.opacity(0.12)
        case .light: return Color.black.opacity(0.06)
        }
    }
    
    private var actionBackgroundColor: Color {
        switch theme {
        case .dark: return Color.white.opacity(0.06)
        case .light: return Color.black.opacity(0.04)
        }
    }
    
    private var actionBorderColor: Color {
        switch theme {
        case .dark: return Color.white.opacity(0.14)
        case .light: return Color.black.opacity(0.10)
        }
    }
    
    private func iconColor(for item: ActionItem) -> Color {
        if theme == .light, item.color == .white {
            return .black.opacity(0.85)
        }
        return item.color
    }
}

