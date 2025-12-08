import SwiftUI

struct CommentsOverlayView: View {
    struct Comment: Identifiable {
        let id = UUID()
        let avatar: String
        let username: String
        let text: String
        let time: String
        var likes: Int
    }

    let count: Int
    let onClose: () -> Void

    @State private var inputText: String = ""
    @State private var comments: [Comment] = [
        .init(avatar: "👩", username: "@foodlover", text: "¡Se ve increíble! 😍 ¿Dónde puedo conseguirlo?", time: "2h", likes: 145),
        .init(avatar: "👨‍🍳", username: "@chefmaster", text: "La presentación es espectacular 🧑‍🍳✨", time: "5h", likes: 89),
        .init(avatar: "🧕", username: "@tastytraveler", text: "Definitivamente tengo que probarlo 😋", time: "1d", likes: 234)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea()
            sheet
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.65)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom))
        }
        .transition(.move(edge: .bottom))
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.08))
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(comments.indices, id: \.self) { i in
                        commentRow(comments[i])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            inputBar
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: -4)
        .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        HStack {
            Text("\(count) comentarios")
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

    private func commentRow(_ c: Comment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.12)).frame(width: 40, height: 40)
                Text(c.avatar).font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(c.username)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                Text(c.text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                HStack(spacing: 16) {
                    Text(c.time).foregroundColor(.white.opacity(0.6)).font(.system(size: 12))
                    HStack(spacing: 6) {
                        Image(systemName: "heart").foregroundColor(.white.opacity(0.7)).font(.system(size: 12))
                        Text("\(c.likes)").foregroundColor(.white.opacity(0.7)).font(.system(size: 12))
                    }
                    Text("Responder").foregroundColor(.white.opacity(0.7)).font(.system(size: 12))
                }
            }
            Spacer()
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Añade un comentario...", text: $inputText)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.08)))
                .foregroundColor(.white)
            Button(action: send) {
                ZStack {
                    Circle().fill(Color.green).frame(width: 38, height: 38)
                    Image(systemName: "paperplane.fill").foregroundColor(.black).font(.system(size: 14, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.95))
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        comments.append(.init(avatar: "🙂", username: "@tú", text: text, time: "ahora", likes: 0))
        inputText = ""
    }
}

