import SwiftUI
import Photos

struct CustomMediaPickerView: View {
    // Callbacks
    var onSelect: (URL) -> Void
    var onCancel: () -> Void
    
    // Estado
    @State private var allAssets: [PHAsset] = []
    @State private var selectedAsset: PHAsset?
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    // Grid Config
    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Galería")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if selectedAsset != nil {
                    Button("Siguiente") {
                        processSelectedAsset()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(20)
                } else {
                    Text("Siguiente")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
            }
            .padding()
            .background(Color.black)
            
            // Permisos
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Acceso denegado a la galería")
                        .foregroundColor(.white)
                    Button("Abrir Configuración") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else {
                // Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(allAssets, id: \.localIdentifier) { asset in
                            AssetThumbnailView(asset: asset, isSelected: selectedAsset == asset)
                                .onTapGesture {
                                    selectedAsset = asset
                                }
                        }
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear(perform: checkPermissions)
    }
    
    private func checkPermissions() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        authorizationStatus = status
        
        if status == .authorized || status == .limited {
            loadAssets()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    self.authorizationStatus = newStatus
                    if newStatus == .authorized || newStatus == .limited {
                        self.loadAssets()
                    }
                }
            }
        }
    }
    
    private func loadAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        DispatchQueue.main.async {
            self.allAssets = assets
        }
    }
    
    private func processSelectedAsset() {
        guard let asset = selectedAsset else { return }
        
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            if let urlAsset = avAsset as? AVURLAsset {
                // Copiar a tmp para evitar problemas de permisos
                let fileName = urlAsset.url.lastPathComponent
                let copyURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try? FileManager.default.removeItem(at: copyURL) // Limpiar si existe
                try? FileManager.default.copyItem(at: urlAsset.url, to: copyURL)
                
                DispatchQueue.main.async {
                    onSelect(copyURL)
                }
            }
        }
    }
}

struct AssetThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    @State private var image: UIImage?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: (UIScreen.main.bounds.width / 4) - 1, height: (UIScreen.main.bounds.width / 4) - 1)
                    .clipped()
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
                    .frame(width: (UIScreen.main.bounds.width / 4) - 1, height: (UIScreen.main.bounds.width / 4) - 1)
            }
            
            // Duración
            Text(formatDuration(asset.duration))
                .font(.caption2.bold())
                .foregroundColor(.white)
                .padding(4)
                .shadow(radius: 2)
            
            if isSelected {
                Color.black.opacity(0.4)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                    .padding(4)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        
        let size = CGSize(width: 200, height: 200)
        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { result, _ in
            self.image = result
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
}
