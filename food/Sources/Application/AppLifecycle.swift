//
//  AppLifecycle.swift
//  food
//
//  Created by eliu giraldo on 28/11/25.
//

// Sources/Application/AppLifecycle.swift
import FirebaseCore

/// Maneja el ciclo de vida de la aplicación
public final class AppLifecycle {
    /// Configura Firebase y otros servicios esenciales
    public static func configureFirebase() {
        // Verificar si Firebase ya está configurado
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("[AppLifecycle] ✅ Firebase configurado correctamente")
        } else {
            print("[AppLifecycle] ⚠️ Firebase ya estaba configurado")
        }
    }
    
    /// Inicializa toda la aplicación
    public static func initializeApp() {
        configureFirebase()
        
        // Configurar dependencias
        AppDependencies.shared.configureServices()
        
        print("[AppLifecycle] ✅ Aplicación inicializada correctamente")
    }
}
