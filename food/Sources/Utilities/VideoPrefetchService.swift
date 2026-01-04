import AVKit
import Combine

final class VideoPrefetchService: ObservableObject {
    static let shared = VideoPrefetchService()
    
    // Almacena items listos para reproducir. 
    // Key: URL del video (String)
    private var itemCache: [String: AVPlayerItem] = [:]
    private var loadingTasks: [String: Task<Void, Never>] = [:]
    
    private init() {}
    
    /// Prepara el siguiente video para que esté listo cuando el usuario deslice
    func prefetch(url: String) {
        // Si ya lo tenemos o estamos cargando, ignorar
        guard itemCache[url] == nil, loadingTasks[url] == nil, let videoURL = URL(string: url) else { return }
        
        // Iniciar carga en background
        let task = Task {
            let asset = AVURLAsset(url: videoURL)
            // Cargar claves esenciales para que el player no se bloquee al iniciar
            let keys = ["playable", "duration", "tracks"]
            try? await asset.loadValues(forKeys: keys)
            
            // Crear el item (esto inicia el buffer de red automáticamente)
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 4.0 // 🚀 Mágia: Intentar bufferizar solo ~4 segundos
            
            await MainActor.run {
                // Guardar en caché
                self.itemCache[url] = item
                self.loadingTasks[url] = nil
            }
        }
        loadingTasks[url] = task
    }
    
    /// Recupera un item precargado si existe, o devuelve nil
    func getItem(for url: String) -> AVPlayerItem? {
        return itemCache[url]
    }
    
    /// Limpia caché antigua para liberar memoria RAM
    /// Se debe llamar cuando cambiamos de video
    func cleanup(currentItemUrl: String, nextItemUrl: String?) {
        // Mantener solo el actual y el siguiente. Borrar todo lo demás.
        let keysToKeep = [currentItemUrl, nextItemUrl].compactMap { $0 }
        
        for key in itemCache.keys {
            if !keysToKeep.contains(key) {
                itemCache.removeValue(forKey: key)
                loadingTasks[key]?.cancel()
                loadingTasks.removeValue(forKey: key)
            }
        }
    }
}
