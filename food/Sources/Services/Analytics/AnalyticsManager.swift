import Foundation
import FirebaseAnalytics
import CoreData

// Enum para prioridad de envío
enum AnalyticsPriority: Int16 {
    case realTime = 0    // Enviar YA (ej. Purchase)
    case batch = 1       // Acumular y enviar luego (ej. View Menu)
    case background = 2  // Solo enviar con WiFi/Cargando (ej. Swipes)
}

class AnalyticsManager: ObservableObject {
    
    // Singleton
    static let shared = AnalyticsManager()
    
    // CoreData Stack específico
    private let persistence = AnalyticsPersistence.shared
    
    // Estado de la sesión
    private var currentSessionId: String?
    private var userId: String?
    
    // Configuración
    private let batchSizeTrigger = 20
    private var isBatchingEnabled = true
    
    private init() {
        // Generar Session ID al inicio
        self.currentSessionId = UUID().uuidString
        print("[Analytics] 🟢 Manager Initialized. Session: \(currentSessionId ?? "N/A")")
    }
    
    // MARK: - Public API
    
    /// Inicia el servicio de analítica
    func start() {
        // Configurar User Properties base si existen
        if let userId = UserDefaults.standard.string(forKey: "analytics_user_id") {
            self.identifyUser(userId: userId)
        }
        
        // Intentar enviar eventos pendientes antiguos
        flushPendingEvents()
    }
    
    /// Identifica al usuario actual en Firebase
    func identifyUser(userId: String, properties: [String: Any]? = nil) {
        self.userId = userId
        Analytics.setUserID(userId)
        
        // Guardar para futuras sesiones
        UserDefaults.standard.set(userId, forKey: "analytics_user_id")
        
        if let props = properties {
            for (key, value) in props {
                if let strValue = value as? String {
                    Analytics.setUserProperty(strValue, forName: key)
                }
            }
        }
        
        print("[Analytics] 👤 User Identified: \(userId)")
    }
    
    /// Limpia la identidad del usuario (Logout)
    func resetUser() {
        self.userId = nil
        Analytics.setUserID(nil)
        UserDefaults.standard.removeObject(forKey: "analytics_user_id")
        // Regenerar Session ID para no mezclar datos
        self.currentSessionId = UUID().uuidString
    }
    
    /// Registra un evento de analítica
    /// - Parameters:
    ///   - name: Nombre del evento (snake_case recomendado)
    ///   - params: Diccionario de parámetros
    ///   - priority: Prioridad de envío
    func log(event: String, params: [String: Any]? = nil, priority: AnalyticsPriority = .realTime) {
        
        var finalParams = params ?? [:]
        
        // Injectar parámetros globales
        finalParams["session_id"] = currentSessionId
        finalParams["timestamp_local"] = Date().timeIntervalSince1970
        
        // Validar parámetros para Firebase (Strings y Numbers solamente)
        let firebaseParams = cleanParamsForFirebase(finalParams)
        
        switch priority {
        case .realTime:
            // Enviar directo a Firebase
            Analytics.logEvent(event, parameters: firebaseParams)
            print("[Analytics] 🚀 Sent Real-Time: \(event)")
            
        case .batch, .background:
            // Guardar en CoreData para envío posterior
            saveEventLocally(name: event, params: finalParams, priority: priority)
            print("[Analytics] 💾 Buffered: \(event)")
            
            // Check si debemos hacer flush por tamaño
            checkBufferLimit()
        }
    }
    
    /// Fuerza el envío de todos los eventos pendientes
    func flush() {
        flushPendingEvents()
    }
    
    // MARK: - Private Logic
    
    private func saveEventLocally(name: String, params: [String: Any], priority: AnalyticsPriority) {
        let context = persistence.backgroundContext
        
        context.perform {
            let eventEntity = AnalyticsEvent(context: context) // Asegurarse de que la clase AnalyticsEvent se genera
            eventEntity.id = UUID().uuidString
            eventEntity.name = name
            eventEntity.timestamp = Date()
            eventEntity.priority = priority.rawValue
            eventEntity.status = "pending"
            
            // Serializar params a JSON Data
            if let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []) {
                eventEntity.parameters = jsonData
            }
            
            do {
                try context.save()
            } catch {
                print("[Analytics] ❌ Error saving event to CoreData: \(error)")
            }
        }
    }
    
    private func checkBufferLimit() {
        // Contar eventos pendientes
        let context = persistence.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AnalyticsEvent")
        fetchRequest.predicate = NSPredicate(format: "status == %@", "pending")
        
        do {
            let count = try context.count(for: fetchRequest)
            if count >= batchSizeTrigger {
                print("[Analytics] 📦 Buffer full (\(count)). Flushing...")
                flushPendingEvents()
            }
        } catch {
            print("Error checking buffer: \(error)")
        }
    }
    
    private func flushPendingEvents() {
        let context = persistence.backgroundContext
        
        context.perform {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AnalyticsEvent")
            fetchRequest.predicate = NSPredicate(format: "status == %@", "pending")
            // Limitar el batch para no saturar
            fetchRequest.fetchLimit = 50
            
            do {
                let pendingEvents = try context.fetch(fetchRequest)
                if pendingEvents.isEmpty { return }
                
                print("[Analytics] 📤 Flushing \(pendingEvents.count) events...")
                
                for eventObj in pendingEvents {
                    guard let name = eventObj.value(forKey: "name") as? String else { continue }
                    
                    var params: [String: Any] = [:]
                    if let data = eventObj.value(forKey: "parameters") as? Data {
                        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            params = json
                        }
                    }
                    
                    // Enviar a Firebase (Simulado como batch, Firebase SDK maneja su propio batching interno)
                    // NOTA: Para implementación real "Silent", aquí se enviaría a Cloud Function
                    // Por ahora, usamos Firebase SDK como proxy
                    let cleanParams = self.cleanParamsForFirebase(params)
                    Analytics.logEvent(name, parameters: cleanParams)
                    
                    // Marcar como enviado o borrar
                    context.delete(eventObj)
                }
                
                try context.save()
                print("[Analytics] ✅ Flush completed.")
                
            } catch {
                print("[Analytics] ❌ Error flushing events: \(error)")
            }
        }
    }
    
    private func cleanParamsForFirebase(_ params: [String: Any]) -> [String: Any] {
        // Firebase solo acepta String y Number (Int/Double/Bool)
        var clean: [String: Any] = [:]
        for (key, value) in params {
            if value is String || value is Int || value is Double || value is Bool {
                clean[key] = value
            } else {
                // Convertir otros tipos a String
                clean[key] = String(describing: value)
            }
        }
        return clean
    }
}
