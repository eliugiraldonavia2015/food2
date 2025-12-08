import SwiftUI

struct ShareOverlayView: View {
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
    @State private var sent: Set<UUID> = []

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
        ZStack(alignment: .bottom) {
            sheet
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.6)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom))
        }
        .transition(.move(edge: .bottom))
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.08))
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
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: -4)
        .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        HStack {
            Text("Compartir")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            Button(action: onClose) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.08)).frame(width: 34, height: 34)
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
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
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
            content()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func personItem(_ p: Person) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.white.opacity(0.12)).frame(width: 56, height: 56)
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
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                if sent.contains(p.id) { sent.remove(p.id) } else { sent.insert(p.id) }
            }
        }
    }

    private func actionItem(_ t: ActionItem) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: t.systemIcon)
                        .foregroundColor(t.color)
                        .font(.system(size: 20, weight: .bold))
                )
            Text(t.title)
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
    }
}

