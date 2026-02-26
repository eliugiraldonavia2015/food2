import CoreData
import Foundation

/// Controller para manejar el stack de CoreData específico para Analytics.
/// Separado del stack principal de la app para evitar bloqueos.
class AnalyticsPersistence {
    static let shared = AnalyticsPersistence()

    let container: NSPersistentContainer

    init() {
        // Intentamos cargar el modelo desde el bundle
        guard let modelURL = Bundle.main.url(forResource: "Analytics", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            // Si falla al cargar el modelo compilado (.momd), intentamos cargar el .xcdatamodeld directo si estamos en desarrollo
            // O fallback a crear un container con el nombre (que buscará automáticamente)
            container = NSPersistentContainer(name: "Analytics")
            setupContainer()
            return
        }

        container = NSPersistentContainer(name: "Analytics", managedObjectModel: model)
        setupContainer()
    }

    private func setupContainer() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("[AnalyticsPersistence] ❌ Error loading CoreData stores: \(error)")
                return
            }
            
            // Configuración para performance en background
            self.container.viewContext.automaticallyMergesChangesFromParent = true
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
    }

    /// Contexto para operaciones en background (escritura de eventos)
    var backgroundContext: NSManagedObjectContext {
        return container.newBackgroundContext()
    }
    
    /// Contexto principal (lectura si fuera necesaria)
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
}
