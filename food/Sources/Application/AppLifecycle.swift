//
//  AppLifecycle.swift
//  food
//
//  Created by eliu giraldo on 28/11/25.
//

// Sources/Application/AppLifecycle.swift
import FirebaseCore
import UserNotifications

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
        
        // Iniciar el sistema de analítica
        AnalyticsManager.shared.start()
        
        // Configurar dependencias
        AppDependencies.shared.configureServices()
        
        // Configurar notificaciones
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        print("[AppLifecycle] ✅ Aplicación inicializada correctamente")
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Mostrar notificación incluso si la app está abierta
        completionHandler([.banner, .sound, .badge])
    }
}
