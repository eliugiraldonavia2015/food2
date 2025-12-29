import SwiftUI
import PhotosUI
import AVFoundation

struct UploadVideoView: View {
    let onClose: () -> Void
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = "Promoción"
    @State private var tags: String = ""
    @State private var selectedVideo: PhotosPickerItem? = nil
    @State private var thumbnailURL: URL? = nil
    
    // Estados mínimos para la vista (ya no maneja proceso)
    @State private var errorText: String? = nil
    @ObservedObject private var auth = AuthService.shared
    @State private var isRestaurant: Bool = false
    @State private var isPreparing: Bool = false // Solo para saber si se está cargando el archivo del picker

    private let categories = ["Promoción", "Detrás de cámaras", "Reseña", "Evento"]

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    // SELECCIÓN DE VIDEO
                    PhotosPicker(selection: $selectedVideo, matching: .videos) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 160)
                            
                            VStack(spacing: 8) {
                                if selectedVideo != nil {
                                    // Feedback minimalista: Solo muestra que hay video
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 32))
                                    Text("Video seleccionado")
                                        .foregroundColor(.green)
                                        .font(.caption.bold())
                                } else {
                                    Image(systemName: "video.badge.plus")
                                        .foregroundColor(.green)
                                        .font(.system(size: 28, weight: .bold))
                                    Text("Selecciona un video")
                                        .foregroundColor(.white)
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                    }
                    .onChange(of: selectedVideo) { newItem in
                        startPreparation(item: newItem)
                    }

                    textField("Título", text: $title)
                    textArea("Descripción", text: $description)
                    pickerField(title: "Categoría", selection: $category, options: categories)
                    textField("Tags (coma separada)", text: $tags)

                    HStack(spacing: 12) {
                        primaryFilledButton(title: "Generar Miniatura") {
                            thumbnailURL = URL(string: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c")
                        }
                        primaryOutlinedButton(title: "Limpiar Miniatura") { thumbnailURL = nil }
                    }

                    if let thumb = thumbnailURL {
                        if let url = URL(string: thumb.absoluteString) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 160)
                                .overlay(
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image): image.resizable().scaledToFill()
                                        case .empty: ProgressView().tint(.green)
                                        case .failure(_): Image(systemName: "photo").foregroundColor(.white)
                                        @unknown default: Color.gray
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                )
                        }
                    }

                    // BOTÓN DE PUBLICAR (Siempre activo si hay datos)
                    primaryFilledButton(title: "Publicar Video") {
                        commitUpload()
                    }
                    .disabled(selectedVideo == nil || title.isEmpty || isPreparing)
                    .opacity((selectedVideo == nil || title.isEmpty || isPreparing) ? 0.6 : 1.0)
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .top) {
            if let e = errorText {
                errorBanner(e)
            }
        }
        .onAppear {
            isRestaurant = (auth.user?.role ?? "client") == "restaurant"
        }
    }
    
    private func startPreparation(item: PhotosPickerItem?) {
        guard let item = item else { return }
        isPreparing = true
        
        Task {
            do {
                print("🎬 [UploadVideoView] Extrayendo video del picker...")
                // Extraer URL segura y persistente
                var finalURL: URL?
                
                if let pickedURL = try? await item.loadTransferable(type: URL.self) {
                    let t = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try FileManager.default.copyItem(at: pickedURL, to: t)
                    finalURL = t
                } else if let data = try? await item.loadTransferable(type: Data.self) {
                    let t = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try data.write(to: t)
                    finalURL = t
                }
                
                guard let inputURL = finalURL else {
                    print("❌ Error extrayendo video")
                    await MainActor.run { isPreparing = false }
                    return
                }
                
                // Iniciar preparación en background (Manager Global)
                // Esto no bloquea la UI, el usuario sigue escribiendo título/descripción
                await MainActor.run {
                    UploadManager.shared.prepareVideo(inputURL: inputURL)
                    self.isPreparing = false
                    
                    // Generar thumbnail visual localmente para feedback inmediato
                    self.thumbnailURL = nil // Reset
                    if let thumb = self.generateLocalThumbnail(url: inputURL) {
                        // Aquí podríamos guardar el thumb local para mostrarlo
                        // Por simplicidad en este MVP, no lo mostramos en la UI de edición
                        // salvo que implementemos lógica de thumb local.
                    }
                }
                
            } catch {
                print("❌ Error fatal preparando: \(error)")
                await MainActor.run { isPreparing = false }
            }
        }
    }
    
    private func commitUpload() {
        guard isRestaurant else { return }
        // Commit al Manager y cerrar inmediatamente
        UploadManager.shared.commitUpload(title: title, description: description)
        onClose()
    }
    
    private func generateLocalThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        return try? UIImage(cgImage: generator.copyCGImage(at: .zero, actualTime: nil))
    }

    // MARK: - UI Components
    private func header() -> some View {
        HStack {
            Button(action: onClose) {
                Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
            }
            Spacer()
            Text("Subir Video").foregroundColor(.white).font(.headline.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func textField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundColor(.white).font(.footnote)
            TextField("", text: text)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func textArea(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundColor(.white).font(.footnote)
            TextEditor(text: text)
                .foregroundColor(.white)
                .frame(height: 120)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func pickerField(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundColor(.white).font(.footnote)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)
            .tint(.green)
        }
    }

    private func primaryFilledButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .background(
            LinearGradient(colors: [Color.green.opacity(0.95), Color.green.opacity(0.75)], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(Capsule())
        .shadow(color: .green.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private func primaryOutlinedButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .background(Color.clear)
        .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
        .clipShape(Capsule())
    }
    
    private func errorBanner(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
            Text(text).foregroundColor(.white).font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.95)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
