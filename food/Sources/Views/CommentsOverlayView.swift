import SwiftUI

public struct CommentsOverlayView: View {
    let count: Int
    let onClose: () -> Void
    let videoId: String? // ID real del video
    
    // State
    @State private var commentText: String = ""
    @State private var comments: [Comment] = [] // Lista local para UI
    @State private var isLoading = false
    
    // Modelo de comentario PÚBLICO
    public struct Comment: Identifiable {
        public let id: String
        public let userId: String
        public let username: String
        public let text: String
        public let timestamp: Date
        public let avatarUrl: String
        
        public init(id: String, userId: String, username: String, text: String, timestamp: Date, avatarUrl: String) {
            self.id = id
            self.userId = userId
            self.username = username
            self.text = text
            self.timestamp = timestamp
            self.avatarUrl = avatarUrl
        }
    }
    
    public init(count: Int, onClose: @escaping () -> Void, videoId: String?) {
        self.count = count
        self.onClose = onClose
        self.videoId = videoId
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Fondo oscuro semitransparente
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("\(count) comentarios")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Lista de comentarios
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if isLoading {
                            ProgressView().padding()
                        } else if comments.isEmpty {
                            Text("Sé el primero en comentar 👇")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Input Bar
                VStack(spacing: 0) {
                    Divider().background(Color.white.opacity(0.15))
                    HStack(spacing: 12) {
                        // Avatar usuario actual (placeholder)
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 32, height: 32)
                            
                        HStack {
                            TextField("Añadir comentario...", text: $commentText)
                                .foregroundColor(.white)
                                .accentColor(.white)
                            
                            if !commentText.isEmpty {
                                Button(action: sendComment) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color.black.opacity(0.9))
            }
            .frame(height: UIScreen.main.bounds.height * 0.65)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .transition(.move(edge: .bottom))
        }
        .onAppear(perform: loadComments)
    }
    
    private func loadComments() {
        guard let vid = videoId else { return }
        isLoading = true
        
        DatabaseService.shared.fetchComments(videoId: vid) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let fetched):
                    self.comments = fetched
                case .failure(let err):
                    print("Error loading comments: \(err.localizedDescription)")
                }
            }
        }
    }
    
    private func sendComment() {
        guard let vid = videoId, !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let user = AuthService.shared.user else { return } // Validar auth
        
        let text = commentText
        commentText = "" // Limpiar input inmediatamente
        
        // Optimistic UI: Mostrar comentario localmente
        let tempComment = Comment(
            id: UUID().uuidString,
            userId: user.uid,
            username: user.username ?? "Yo",
            text: text,
            timestamp: Date(),
            avatarUrl: user.photoURL?.absoluteString ?? ""
        )
        withAnimation {
            comments.insert(tempComment, at: 0)
        }
        
        DatabaseService.shared.postComment(videoId: vid, text: text, userId: user.uid) { error in
            if let error = error {
                print("Error sending comment: \(error)")
                // TODO: Revertir optimistic UI si falla
            }
        }
    }
}

// Subvista para cada fila de comentario
struct CommentRow: View {
    let comment: CommentsOverlayView.Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle() // Avatar
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    AsyncImage(url: URL(string: comment.avatarUrl)) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: { Color.clear }
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(comment.username)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(nil)
                
                Text(timeAgo(comment.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}



