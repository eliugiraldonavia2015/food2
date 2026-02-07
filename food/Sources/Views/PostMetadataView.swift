import SwiftUI
import PhotosUI
import AVFoundation

struct PostMetadataView: View {
    let videoURL: URL?
    let onClose: () -> Void
    
    // MARK: - State
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = "Promoción"
    @State private var tags: String = ""
    @State private var thumbnailURL: URL? = nil
    
    // Upload Manager State
    @ObservedObject private var uploadManager = UploadManager.shared
    
    // UI Logic
    @State private var isPreparing: Bool = false
    @State private var showSuccessAnimation = false
    @FocusState private var focusedField: Field?
    
    private let categories = ["Promoción", "Detrás de cámaras", "Reseña", "Evento", "Receta"]
    
    enum Field: Hashable {
        case title, description, tags
    }
    
    // Colors
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let surfaceColor = Color(uiColor: .secondarySystemGroupedBackground)
    private let backgroundColor = Color(uiColor: .systemGroupedBackground)

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundColor.ignoresSafeArea()
                
                if uploadManager.isProcessing {
                    uploadingOverlay
                        .transition(.opacity)
                        .zIndex(10)
                } else if showSuccessAnimation {
                    successView
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(11)
                } else {
                    mainFormContent
                        .transition(.move(edge: .bottom))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar", action: onClose)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Nueva Publicación")
                        .font(.headline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        hideKeyboard()
                        uploadManager.commitUpload(title: title, description: description)
                    } label: {
                        Text("Publicar")
                            .fontWeight(.bold)
                            .foregroundColor(canPublish ? brandPink : .gray.opacity(0.5))
                    }
                    .disabled(!canPublish)
                }
            }
        }
        .onChange(of: uploadManager.isCompleted) { completed in
            if completed {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showSuccessAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    onClose()
                    // Reset manager state for next time
                    uploadManager.isCompleted = false
                    uploadManager.progress = 0
                    showSuccessAnimation = false
                }
            }
        }
        .onAppear {
            if let url = videoURL {
                startPreparation(url: url)
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainFormContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Video Preview Section
                videoPreviewSection
                
                // Details Section
                VStack(spacing: 0) {
                    customTextField(
                        icon: "text.alignleft",
                        placeholder: "Escribe un título llamativo...",
                        text: $title,
                        field: .title
                    )
                    
                    Divider().padding(.leading, 44)
                    
                    customTextField(
                        icon: "text.quote",
                        placeholder: "Descripción y detalles...",
                        text: $description,
                        field: .description,
                        isMultiLine: true
                    )
                }
                .background(surfaceColor)
                .cornerRadius(12)
                
                // Category & Tags Section
                VStack(spacing: 0) {
                    // Category Selector
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        Text("Categoría")
                            .foregroundColor(.primary)
                        Spacer()
                        Picker("Categoría", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(brandPink)
                    }
                    .padding()
                    
                    Divider().padding(.leading, 44)
                    
                    customTextField(
                        icon: "number",
                        placeholder: "Tags (ej: #comida, #tacos)",
                        text: $tags,
                        field: .tags
                    )
                }
                .background(surfaceColor)
                .cornerRadius(12)
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }
    
    // MARK: - Components
    
    private var videoPreviewSection: some View {
        ZStack {
            if let thumb = thumbnailURL, let validUrl = URL(string: thumb.absoluteString) {
                 AsyncImage(url: validUrl) { phase in
                     switch phase {
                     case .success(let image):
                         GeometryReader { geo in
                             image
                                 .resizable()
                                 .scaledToFill() // Ensures it fills the frame without distortion
                                 .frame(width: geo.size.width, height: geo.size.height)
                                 .clipped()
                         }
                     default:
                         Rectangle().fill(Color.black)
                     }
                 }
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay(ProgressView().tint(.white))
            }
        }
        .frame(height: 350) // Increased height for better vertical preview
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onDisappear {
            // Ensure any potential audio from preview generation is stopped
            // Note: Currently we only show image, but good practice
        }
    }
    
    private func customTextField(icon: String, placeholder: String, text: Binding<String>, field: Field, isMultiLine: Bool = false) -> some View {
        HStack(alignment: isMultiLine ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
                .padding(.top, isMultiLine ? 4 : 0)
            
            if isMultiLine {
                TextField(placeholder, text: text, axis: .vertical)
                    .focused($focusedField, equals: field)
                    .lineLimit(3...6)
            } else {
                TextField(placeholder, text: text)
                    .focused($focusedField, equals: field)
            }
        }
        .padding()
    }
    
    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle().stroke(lineWidth: 6).opacity(0.3).foregroundColor(.gray)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(uploadManager.progress))
                        .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .foregroundColor(brandPink)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear(duration: 0.2), value: uploadManager.progress)
                    Text("\(Int(uploadManager.progress * 100))%").font(.title2.bold()).foregroundColor(.white)
                }
                .frame(width: 100, height: 100)
                Text(uploadManager.statusMessage).font(.headline).foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
        }
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundColor(.green)
            Text("¡Publicado!").font(.title2.bold())
        }
        .padding(40)
        .background(surfaceColor)
        .cornerRadius(24)
    }
    
    // MARK: - Logic Helpers
    
    private var canPublish: Bool {
        return videoURL != nil && !title.isEmpty && !uploadManager.isProcessing && !isPreparing
    }
    
    private func hideKeyboard() {
        focusedField = nil
    }
    
    private func startPreparation(url: URL) {
        isPreparing = true
        Task {
            await MainActor.run {
                UploadManager.shared.prepareVideo(inputURL: url)
                self.isPreparing = false
                
                self.thumbnailURL = nil
                if let thumb = self.generateLocalThumbnail(url: url) {
                    let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("temp_thumb.jpg")
                    try? thumb.jpegData(compressionQuality: 0.7)?.write(to: tempUrl)
                    self.thumbnailURL = tempUrl
                }
            }
        }
    }
    
    private func generateLocalThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        return try? UIImage(cgImage: generator.copyCGImage(at: .zero, actualTime: nil))
    }
}
