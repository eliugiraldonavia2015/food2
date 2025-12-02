// Sources/Application/AppDependencies.swift
import Foundation

/// Contenedor de dependencias para la aplicación
public final class AppDependencies {
    /// Instancia compartida para acceso global
    public static let shared = AppDependencies()
    
    /// Servicio de autenticación - USANDO SINGLETON EXISTENTE
    public let authService = AuthService.shared
    
    /// Servicio de base de datos - USANDO SINGLETON EXISTENTE
    public let databaseService = DatabaseService.shared
    
    /// Servicio de almacenamiento - USANDO SINGLETON EXISTENTE
    public let storageService = StorageService.shared
    
    private init() {
        // No se crean nuevas instancias, se usan los singletons existentes
        print("[AppDependencies] ✅ Dependencias inicializadas usando singletons existentes")
    }
    
    /// Configura los servicios de la aplicación
    public func configureServices() {
        print("[AppDependencies] ✅ Servicios configurados")
    }
}
