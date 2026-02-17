import SwiftUI
import SDWebImageSwiftUI

public struct CommentsOverlayView: View {
    let count: Int
    let onClose: () -> Void
    let videoId: String? // ID real del video
    
    // State
    @State private var commentText: String = ""
    @State private var comments: [Comment] = [] // Lista local para UI
    @State private var isLoading = false
    @State private var isSending = false // Animación botón enviar
    
    // Modelo de comentario PÚBLICO
    public struct Comment: Identifiable {
        public let id: String
        public let userId: String
        public let username: String
        public let text: String
        public let timestamp: Date
        public let avatarUrl: String
        public let replies: [Comment] // Respuestas anidadas
        
        public init(id: String, userId: String, username: String, text: String, timestamp: Date, avatarUrl: String, replies: [Comment] = []) {
            self.id = id
            self.userId = userId
            self.username = username
            self.text = text
            self.timestamp = timestamp
            self.avatarUrl = avatarUrl
            self.replies = replies
        }
    }
    
    public init(count: Int, onClose: @escaping () -> Void, videoId: String?) {
        self.count = count
        self.onClose = onClose
        self.videoId = videoId
    }
    
    // MOCK DATA
    private func getMockComments() -> [Comment] {
        return [
            Comment(id: "1", userId: "u1", username: "Sofía G.", text: "¡Se ve increíble! 😍 ¿Dónde es?", timestamp: Date().addingTimeInterval(-3600), avatarUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330", replies: [
                Comment(id: "1a", userId: "u2", username: "Carlos R.", text: "Es en La Condesa, muy recomendado.", timestamp: Date().addingTimeInterval(-1800), avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e")
            ]),
            Comment(id: "2", userId: "u3", username: "Andrea M.", text: "Necesito probar esa hamburguesa YA 🍔🔥", timestamp: Date().addingTimeInterval(-7200), avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb"),
            Comment(id: "3", userId: "u4", username: "FoodieMex", text: "El mejor lugar de tacos 🌮", timestamp: Date().addingTimeInterval(-10000), avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d", replies: [
                Comment(id: "3a", userId: "u5", username: "Luisa P.", text: "¡Totalmente de acuerdo!", timestamp: Date().addingTimeInterval(-5000), avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2")
            ]),
            Comment(id: "4", userId: "u6", username: "Ricardo T.", text: "¿Tienen opciones veganas? 🌱", timestamp: Date().addingTimeInterval(-15000), avatarUrl: "https://images.unsplash.com/photo-1527980965255-d3b416303d12"),
            Comment(id: "5", userId: "u7", username: "Valeria S.", text: "Excelente servicio ⭐️⭐️⭐️⭐️⭐️", timestamp: Date().addingTimeInterval(-20000), avatarUrl: "https://images.unsplash.com/photo-1517841905240-472988babdf9", replies: [
                Comment(id: "5a", userId: "u8", username: "Restaurante", text: "¡Gracias Valeria! Te esperamos pronto.", timestamp: Date().addingTimeInterval(-1000), avatarUrl: "https://images.unsplash.com/photo-1556910103-1c02745a30bf")
            ]),
            Comment(id: "6", userId: "u9", username: "Miguel A.", text: "Precio?", timestamp: Date().addingTimeInterval(-25000), avatarUrl: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d")
        ]
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Fondo Principal del Modal (Estático)
            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()
                .cornerRadius(16, corners: [.topLeft, .topRight])
            
            // 2. Contenido Principal (Header + Lista) - Ocupa todo el espacio menos el input
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("\(count) comentarios")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
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
                    ScrollViewReader { proxy in
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
                                        .id(comment.id)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        // Espacio extra al final para que el último comentario no quede tapado por el input flotante
                        .padding(.bottom, 100) 
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            // 3. Input Bar Flotante (Independiente)
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
                            .submitLabel(.send)
                        
                        if !commentText.isEmpty {
                            Button(action: sendComment) {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .disabled(isSending)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                // Fondo negro sólido para el input bar
                .background(Color.black.opacity(0.95))
            }
            // Posicionamiento absoluto desde abajo
            .padding(.bottom, keyboardHeight) 
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .frame(height: UIScreen.main.bounds.height * 0.65)
        .ignoresSafeArea(.container, edges: .bottom) // Importante para que el fondo llegue al borde
        .ignoresSafeArea(.keyboard, edges: .bottom) // Evitar que SwiftUI empuje todo
        .onAppear {
            loadComments()
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }
    
    @State private var keyboardHeight: CGFloat = 0
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardFrame.height
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.keyboardHeight = 0
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadComments() {
        guard let vid = videoId else { 
            // Cargar mocks si no hay ID (modo diseño/prueba)
            self.comments = getMockComments()
            return 
        }
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
        // Validar texto
        guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let text = commentText
        commentText = "" // Limpiar input inmediatamente
        withAnimation { isSending = true } // Iniciar animación
        
        // Simulación o Envío Real
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                let user = AuthService.shared.user
                let tempComment = Comment(
                   id: UUID().uuidString,
                   userId: user?.uid ?? "me",
                   username: user?.username ?? "Yo",
                   text: text,
                   timestamp: Date(),
                   avatarUrl: user?.photoURL?.absoluteString ?? "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde"
                )
                comments.insert(tempComment, at: 0)
                isSending = false
                
                // Si hay video real, intentar enviar a BD en background
                if let vid = videoId, let uid = user?.uid {
                    DatabaseService.shared.postComment(videoId: vid, text: text, userId: uid) { _ in }
                }
            }
        }
    }
}

// Subvista para cada fila de comentario
struct CommentRow: View {
    let comment: CommentsOverlayView.Comment
    @State private var showReplies = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: URL(string: comment.avatarUrl))
                .resizable()
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .background(Circle().fill(Color.gray.opacity(0.3))) // Fallback background
            
            VStack(alignment: .leading, spacing: 4) {
                Text(comment.username)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(comment.text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(nil)
                
                HStack(spacing: 16) {
                    Text(timeAgo(comment.timestamp))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    Text("Responder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.top, 2)
                
                // Mostrar Respuestas
                if !comment.replies.isEmpty {
                    if showReplies {
                        ForEach(comment.replies) { reply in
                            HStack(alignment: .top, spacing: 12) {
                                WebImage(url: URL(string: reply.avatarUrl))
                                    .resizable()
                                    .indicator(.activity)
                                    .transition(.fade(duration: 0.5))
                                    .scaledToFill()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    .background(Circle().fill(Color.gray.opacity(0.3)))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reply.username)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(reply.text)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        Button(action: { withAnimation { showReplies = false } }) {
                            Text("Ocultar respuestas")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 12)
                        }
                    } else {
                        Button(action: { withAnimation { showReplies = true } }) {
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 24, height: 1)
                                Text("Ver \(comment.replies.count) respuestas")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .padding(.top, 8)
                        }
                    }
                }
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



