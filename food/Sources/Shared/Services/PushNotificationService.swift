// Sources/Shared/Services/PushNotificationService.swift
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import UIKit

/// Servicio para manejar notificaciones push
public final class PushNotificationService {
    /// Singleton para acceso global
    public static let shared = PushNotificationService()
    
    private init() {}
    
    /// Solicita permiso para notificaciones push
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                ErrorHandler.shared.log(error)
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    /// Registra el token de notificaciones push
    public func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
