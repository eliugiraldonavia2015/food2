import CoreData
import Foundation

/// Controller para manejar el stack de CoreData específico para Analytics.
/// Separado del stack principal de la app para evitar bloqueos.
class AnalyticsPersistence {
    static let shared = AnalyticsPersistence()

    let container: NSPersistentContainer

    init() {
        // 1. Construir el modelo programáticamente (sin depender de .momd compilado)
        let model = NSManagedObjectModel()
        
        // Entidad AnalyticsEvent
        let entity = NSEntityDescription()
        entity.name = "AnalyticsEvent"
        entity.managedObjectClassName = NSStringFromClass(AnalyticsEvent.self) // Clase real
        
        // Atributos
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = true
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = true
        
        let paramsAttr = NSAttributeDescription()
        paramsAttr.name = "parameters"
        paramsAttr.attributeType = .binaryDataAttributeType
        paramsAttr.isOptional = true
        
        let priorityAttr = NSAttributeDescription()
        priorityAttr.name = "priority"
        priorityAttr.attributeType = .integer16AttributeType
        priorityAttr.defaultValue = 0
        priorityAttr.isOptional = false // int16 no optional en CoreData
        
        let statusAttr = NSAttributeDescription()
        statusAttr.name = "status"
        statusAttr.attributeType = .stringAttributeType
        statusAttr.isOptional = true
        
        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType
        timestampAttr.isOptional = true
        
        entity.properties = [idAttr, nameAttr, paramsAttr, priorityAttr, statusAttr, timestampAttr]
        model.entities = [entity]
        
        // 2. Inicializar contenedor con este modelo en memoria
        container = NSPersistentContainer(name: "Analytics", managedObjectModel: model)
        
        // 3. Configurar stores
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
