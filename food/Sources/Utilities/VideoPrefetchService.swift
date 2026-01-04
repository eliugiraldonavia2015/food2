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
        // ⚠️ CRITICAL: AVPlayerItem can only belong to one AVPlayer at a time.
        // We must return a copy to avoid "An AVPlayerItem cannot be associated with more than one instance of AVPlayer" crash.
        return itemCache[url]?.copy() as? AVPlayerItem
    }
    
    /// Limpia caché antigua para liberar memoria RAM
    /// Se debe llamar cuando cambiamos de video
    func cleanup(currentItemUrl: String, nextItemUrl: String?) {
        // TikTok Strategy: Keep ONLY current and next. Aggressively purge everything else.
        // If memory pressure is high, iOS will handle it, but we help it.
        let keysToKeep = [currentItemUrl, nextItemUrl].compactMap { $0 }
        
        for key in itemCache.keys {
            if !keysToKeep.contains(key) {
                // Cancel loading task
                loadingTasks[key]?.cancel()
                loadingTasks.removeValue(forKey: key)
                
                // Remove item to free memory immediately
                itemCache.removeValue(forKey: key)
            }
        }
    }
}
