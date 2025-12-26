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
                
                // Verificar tamaño del archivo
                let resources = try tmp.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = resources.fileSize ?? 0
                let fileSizeMB = Double(fileSize) / 1024.0 / 1024.0
                print("📦 [UploadVideoView] Tamaño original: \(String(format: "%.2f", fileSizeMB)) MB")
                
                // --- ESTRATEGIA PRO DE 4 NIVELES + SMART CHECK ---
                let quality: ProQualityLevel
                
                if fileSizeMB < 10.0 {
                    // Nivel 1: Nano (Intentar HEVC 1Mbps)
                    print("🧪 [UploadVideoView] Nivel 1: Nano (<10MB). Probando Smart Compression...")
                    quality = .nano
                } else if fileSizeMB < 30.0 {
                    // Nivel 2: qHD 540p (Mini) - Calidad nítida base
                    print("📱 [UploadVideoView] Nivel 2: qHD 540p (Balance)")
                    quality = .qhd_540p
                } else if fileSizeMB < 60.0 {
                    // Nivel 3: HD 720p (Estándar) - HEVC Estándar
                    print("⚡️ [UploadVideoView] Nivel 3: HD 720p (Estándar)")
                    quality = .hd_720p
                } else {
                    // Nivel 4: HD 720p HQ (Alta) - HEVC Premium
                    print("💎 [UploadVideoView] Nivel 4: HD 720p HQ (Premium)")
                    quality = .hd_720p_hq
                }
                
                print("🔄 [UploadVideoView] Iniciando compresión PRO con nivel: \(quality)")
                
                ProVideoCompressor.compress(inputURL: tmp, level: quality) { result in
                    switch result {
                    case .success(let outURL):
                        // Calcular ahorro y aplicar Smart Check para Nano
                        let outSize = (try? FileManager.default.attributesOfItem(atPath: outURL.path)[.size] as? Int) ?? 0
                        let outMB = Double(outSize) / 1024.0 / 1024.0
                        let saving = fileSizeMB > 0 ? (1.0 - (outMB / fileSizeMB)) * 100 : 0
                        print("✅ [UploadVideoView] Resultado PRO: \(String(format: "%.2f", outMB)) MB (Ahorro: \(String(format: "%.0f", saving))%)")
                        
                        // Smart Check: Si el resultado es mayor que el original (y era nivel Nano), usar original
                        if quality == .nano && outMB >= fileSizeMB {
                            print("↩️ [UploadVideoView] Smart Check: Compresión no eficiente. Usando original.")
                            self.uploadToBunny(fileURL: tmp, accessKey: accessKey)
                        } else {
                            self.uploadToBunny(fileURL: outURL, accessKey: accessKey)
                        }
                        
                    case .failure(let error):
                        print("⚠️ [UploadVideoView] Falló compresión PRO: \(error.localizedDescription). Intentando pass-through de seguridad...")
                        self.uploadToBunny(fileURL: tmp, accessKey: accessKey)
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
