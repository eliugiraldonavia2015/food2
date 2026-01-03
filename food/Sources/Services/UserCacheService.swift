import Foundation
import Combine

public final class UserCacheService {
    public static let shared = UserCacheService()
    
    // Almacenamiento en memoria (RAM)
    // [UserId: UserProfileData]
    private var cache: [String: [String: Any]] = [:]
    private let queue = DispatchQueue(label: "com.food.usercache", attributes: .concurrent)
    
    private init() {}
    
    /// Resuelve una lista de IDs de usuario, devolviendo sus perfiles.
    /// Usa la caché si existe, o consulta a Firestore si falta.
    public func resolveUsers(userIds: [String], completion: @escaping ([String: [String: Any]]) -> Void) {
        let uniqueIds = Array(Set(userIds)) // Eliminar duplicados
        var result: [String: [String: Any]] = [:]
        var missingIds: [String] = []
        
        // 1. Verificar caché (Thread-safe read)
        queue.sync {
            for id in uniqueIds {
                if let profile = cache[id] {
                    result[id] = profile
                } else {
                    missingIds.append(id)
                }
            }
        }
        
        // Si no falta ninguno, devolvemos inmediato
        if missingIds.isEmpty {
            completion(result)
            return
        }
        
        // 2. Fetch de los faltantes
        print("🔍 [UserCache] Resolviendo \(missingIds.count) usuarios faltantes...")
        DatabaseService.shared.fetchUsers(byIds: missingIds) { [weak self] fetchResult in
            guard let self = self else { return }
            
            switch fetchResult {
            case .success(let fetchedProfiles):
                // 3. Guardar en caché (Thread-safe write)
                self.queue.async(flags: .barrier) {
                    for (id, data) in fetchedProfiles {
                        self.cache[id] = data
                    }
                }
                
                // 4. Combinar y devolver
                var finalResult = result
                for (id, data) in fetchedProfiles {
                    finalResult[id] = data
                }
                
                print("✅ [UserCache] Hidratación completada. Total: \(finalResult.count)")
                completion(finalResult)
                
            case .failure(let error):
                print("⚠️ [UserCache] Error fetching batch: \(error). Devolviendo parciales.")
                completion(result)
            }
        }
    }
    
    /// Obtiene un usuario individual (helper)
    public func getUser(_ uid: String) -> [String: Any]? {
        return queue.sync { cache[uid] }
    }
}
