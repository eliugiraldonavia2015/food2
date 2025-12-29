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
    
    // Estados de proceso
    @State private var isUploading: Bool = false
    @State private var isCompressing: Bool = false
    @State private var compressionFinished: Bool = false
    @State private var compressedVideoURL: URL? = nil
    @State private var originalVideoURL: URL? = nil // Backup por si falla compresión
    
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
                    // SELECCIÓN DE VIDEO CON OVERLAY DE ESTADO
                    PhotosPicker(selection: $selectedVideo, matching: .videos) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 160)
                            
                            VStack(spacing: 8) {
                                if isCompressing {
                                    ProgressView()
                                        .tint(.green)
                                        .scaleEffect(1.5)
                                    Text("Optimizando video...")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.caption)
                                } else if compressionFinished {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 32))
                                    Text("Video listo para subir")
                                        .foregroundColor(.green)
                                        .font(.caption.bold())
                                } else {
                                    Image(systemName: "video.badge.plus")
                                        .foregroundColor(.green)
                                        .font(.system(size: 28, weight: .bold))
                                    Text(selectedVideo == nil ? "Selecciona un video" : "Video seleccionado")
                                        .foregroundColor(.white)
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                    }
                    .onChange(of: selectedVideo) { _ in
                        startBackgroundCompression()
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

                    // BOTÓN DE PUBLICAR INTELIGENTE
                    primaryFilledButton(title: buttonTitle) {
                        guard isRestaurant else { return }
                        guard selectedVideo != nil, !title.isEmpty else { return }
                        initiateUpload()
                    }
                    .disabled(isUploading || (isCompressing && compressedVideoURL == nil))
                    .opacity(isUploading ? 0.6 : 1.0)
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .top) { if showSuccess { successBanner("Video publicado correctamente") } }
        .overlay(alignment: .top) {
            if let e = errorText {
                errorBanner(e)
            }
        }
        .onAppear {
            isRestaurant = (auth.user?.role ?? "client") == "restaurant"
        }
    }
    
    // Texto dinámico del botón
    private var buttonTitle: String {
        if isUploading { return "Subiendo..." }
        if isCompressing { return "Procesando..." }
        return "Publicar Video"
    }

    private func startBackgroundCompression() {
        guard let item = selectedVideo else { return }
        
        // Reset states
        isCompressing = true
        compressionFinished = false
        compressedVideoURL = nil
        originalVideoURL = nil
        errorText = nil
        
        Task {
            do {
                print("🎬 [Background] Cargando video original...")
                var tmp: URL?
                if let pickedURL = try await item.loadTransferable(type: URL.self) {
                    let t = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mp4")
                    try FileManager.default.copyItem(at: pickedURL, to: t)
                    tmp = t
                } else if let data = try await item.loadTransferable(type: Data.self) {
                    let t = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mp4")
                    try data.write(to: t)
                    tmp = t
                }
                
                guard let inputURL = tmp else {
                    print("❌ [Background] Error cargando video")
                    await MainActor.run { isCompressing = false }
                    return
                }
                
                self.originalVideoURL = inputURL
                
                // Analizar tamaño
                let resources = try inputURL.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = resources.fileSize ?? 0
                let fileSizeMB = Double(fileSize) / 1024.0 / 1024.0
                print("📦 [Background] Tamaño original: \(String(format: "%.2f", fileSizeMB)) MB")
                
                // PASO 0: Análisis Científico de Eficiencia
                // Usamos el nuevo algoritmo adaptativo para decidir qué hacer
                let optimalLayer = await ProVideoCompressor.calculateOptimalLayer(for: inputURL)
                
                switch optimalLayer {
                case .passThrough:
                    print("⚡️ [Background] Video detectado como eficiente. Saltando re-compresión.")
                    await MainActor.run {
                        self.compressedVideoURL = inputURL
                        self.isCompressing = false
                        self.compressionFinished = true
                    }
                    return
                    
                case .custom(let config):
                    print("🔄 [Background] Iniciando compresión PRO Adaptativa...")
                    print("🎯 Target: \(config.width)x\(config.height) @ \(config.bitrate/1000) kbps")
                    
                    ProVideoCompressor.compress(inputURL: inputURL, level: optimalLayer) { result in
                        Task { @MainActor in
                            self.isCompressing = false
                            switch result {
                            case .success(let outURL):
                                // Smart Check para Nano (Opcional, ya que calculateOptimalLayer ya hizo cálculos)
                                let outSize = (try? FileManager.default.attributesOfItem(atPath: outURL.path)[.size] as? Int) ?? 0
                                let outMB = Double(outSize) / 1024.0 / 1024.0
                                
                                print("✅ [Background] Compresión lista: \(String(format: "%.2f", outMB)) MB")
                                self.compressedVideoURL = outURL
                                self.compressionFinished = true
                                
                            case .failure(let error):
                                print("⚠️ [Background] Falló compresión: \(error.localizedDescription). Usando original.")
                                self.compressedVideoURL = inputURL
                                self.compressionFinished = true
                            }
                        }
                    }
                }
            } catch {
                print("❌ [Background] Error fatal: \(error)")
                await MainActor.run { isCompressing = false }
            }
        }
    }
    
    private func initiateUpload() {
        // Si la compresión ya terminó, usamos el URL guardado
        // Si no (raro porque bloqueamos el botón), usamos el original como fallback
        guard let fileToUpload = compressedVideoURL ?? originalVideoURL else {
            errorText = "El video aún se está procesando"
            return
        }
        
        let accessKey = ProcessInfo.processInfo.environment["BUNNY_STORAGE_ACCESS_KEY"] ?? ""
        if accessKey.isEmpty {
            errorText = "Error de configuración: Falta AccessKey"
            return
        }
        
        isUploading = true
        
        // Subida directa (Zero-Wait)
        let ulid = UUID().uuidString.lowercased()
        print("🚀 [Upload] Iniciando subida inmediata. ULID: \(ulid)")
        
        BunnyUploader.upload(fileURL: fileToUpload, ulid: ulid, accessKey: accessKey) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                switch result {
                case .success(let url):
                    print("✅ [Upload] Éxito total: \(url)")
                    
                    // SUBIR THUMBNAIL (Fondo)
                    if let thumb = self.generateThumbnail(url: fileToUpload) {
                        print("🖼 [Upload] Generando y subiendo thumbnail...")
                        BunnyUploader.uploadThumbnail(image: thumb, ulid: ulid, accessKey: accessKey) { _ in
                            print("✅ [Upload] Thumbnail completado")
                        }
                    }
                    
                    self.showSuccess = true
                    // Disparar HEAD request silencioso para calentar CDN
                    var req = URLRequest(url: url)
                    req.httpMethod = "HEAD"
                    URLSession.shared.dataTask(with: req).resume()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.showSuccess = false
                        self.onClose()
                    }
                case .failure(let error):
                    self.errorText = error.localizedDescription
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { self.errorText = nil }
                }
            }
        }
    }
    
    private func generateThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Error generando thumbnail: \(error)")
            return nil
        }
    }

    // MARK: - UI Components (Helpers)
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
