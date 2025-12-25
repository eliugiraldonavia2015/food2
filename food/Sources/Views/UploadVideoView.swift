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
    @State private var isUploading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorText: String? = nil
    @ObservedObject private var auth = AuthService.shared
    @State private var isRestaurant: Bool = false

    private let categories = ["Promoción", "Detrás de cámaras", "Reseña", "Evento"]

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedVideo, matching: .videos) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 160)
                            VStack(spacing: 8) {
                                Image(systemName: "video.badge.plus")
                                    .foregroundColor(.green)
                                    .font(.system(size: 28, weight: .bold))
                                Text(selectedVideo == nil ? "Selecciona un video" : "Video seleccionado")
                                    .foregroundColor(.white)
                                    .font(.subheadline.bold())
                            }
                        }
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

                    primaryFilledButton(title: isUploading ? "Publicando…" : "Publicar Video") {
                        guard isRestaurant else { return }
                        guard selectedVideo != nil, !title.isEmpty else { return }
                        isUploading = true
                        publishSelectedVideo()
                    }
                    .disabled(isUploading)
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .top) { if showSuccess { successBanner("Video publicado correctamente") } }
        .overlay(alignment: .top) {
            if let e = errorText {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                    Text(e).foregroundColor(.white).font(.system(size: 14, weight: .semibold))
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
        .onAppear {
            isRestaurant = (auth.user?.role ?? "client") == "restaurant"
        }
    }

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

    private func successBanner(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
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

    private func publishSelectedVideo() {
        print("🎬 [UploadVideoView] Iniciando proceso de publicación...")
        guard let item = selectedVideo else {
            print("❌ [UploadVideoView] No hay video seleccionado")
            isUploading = false
            return
        }
        
        Task {
            do {
                print("📂 [UploadVideoView] Cargando datos del video...")
                var tmp: URL?
                if let pickedURL = try await item.loadTransferable(type: URL.self) {
                    let t = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mp4")
                    try FileManager.default.copyItem(at: pickedURL, to: t)
                    tmp = t
                    print("✅ [UploadVideoView] Video cargado desde URL: \(t.path)")
                } else if let data = try await item.loadTransferable(type: Data.self) {
                    let t = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mp4")
                    try data.write(to: t)
                    tmp = t
                    print("✅ [UploadVideoView] Video cargado desde Data: \(t.path)")
                }
                
                guard let tmp = tmp else {
                    print("❌ [UploadVideoView] Falló la carga del archivo temporal")
                    DispatchQueue.main.async {
                        isUploading = false
                        errorText = "No se pudo procesar el archivo de video"
                    }
                    return
                }

                let accessKey = ProcessInfo.processInfo.environment["BUNNY_STORAGE_ACCESS_KEY"] ?? ""
                print("🔑 [UploadVideoView] AccessKey length: \(accessKey.count)")
                
                if accessKey.isEmpty {
                    print("❌ [UploadVideoView] AccessKey vacía")
                    DispatchQueue.main.async {
                        isUploading = false
                        errorText = "Falta configuración: BUNNY_STORAGE_ACCESS_KEY"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { errorText = nil }
                    }
                    return
                }
                
                print("🔄 [UploadVideoView] Iniciando compresión (HEVC 720p)...")
                VideoCompressor.compress(inputURL: tmp, variant: .hevc720) { result in
                    switch result {
                    case .success(let out720):
                        print("✅ [UploadVideoView] Compresión exitosa: \(out720.path)")
                        self.uploadToBunny(fileURL: out720, accessKey: accessKey)
                    case .failure(let error):
                        print("⚠️ [UploadVideoView] Falló compresión HEVC: \(error.localizedDescription). Intentando fallback H.264...")
                        VideoCompressor.compress(inputURL: tmp, variant: .h264360) { fallback in
                            switch fallback {
                            case .success(let out360):
                                print("✅ [UploadVideoView] Compresión fallback exitosa: \(out360.path)")
                                self.uploadToBunny(fileURL: out360, accessKey: accessKey)
                            case .failure(let err2):
                                print("❌ [UploadVideoView] Falló compresión fallback: \(err2.localizedDescription)")
                                DispatchQueue.main.async {
                                    isUploading = false
                                    errorText = "Error comprimiendo video: \(err2.localizedDescription)"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { errorText = nil }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("❌ [UploadVideoView] Excepción general: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isUploading = false
                    errorText = "Error interno: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { errorText = nil }
                }
            }
        }
    }
    
    private func uploadToBunny(fileURL: URL, accessKey: String) {
        let ulid = UUID().uuidString.lowercased()
        print("🚀 [UploadVideoView] Iniciando subida a Bunny. ULID: \(ulid)")
        
        BunnyUploader.upload(fileURL: fileURL, ulid: ulid, accessKey: accessKey) { r in
            DispatchQueue.main.async {
                isUploading = false
                switch r {
                case .success(let url):
                    print("✅ [UploadVideoView] Subida completada: \(url)")
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showSuccess = false; onClose() }
                    
                    // Verificación CDN en background
                    var req = URLRequest(url: url)
                    req.httpMethod = "HEAD"
                    URLSession.shared.dataTask(with: req).resume()
                    
                case .failure(let err):
                    print("❌ [UploadVideoView] Error de subida: \(err.localizedDescription)")
                    errorText = err.localizedDescription // Muestra el error detallado de BunnyUploader
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { errorText = nil } // Más tiempo para leer
                }
            }
        }
    }
}
