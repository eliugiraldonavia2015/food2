import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications
import SDWebImage
import AVFoundation // Importar AVFoundation
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// MARK: - AppDelegate (Firebase + reenvío manual de notificaciones)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        print("[AppDelegate] ✅ Firebase configurado")
        UIWindow.appearance().backgroundColor = UIColor(red: 49/255, green: 209/255, blue: 87/255, alpha: 1)

        SDWebImageDownloader.shared.config.maxConcurrentDownloads = 4
        SDWebImagePrefetcher.shared.maxConcurrentPrefetchCount = 2
        SDImageCache.shared.config.maxMemoryCost = 50 * 1024 * 1024
        SDImageCache.shared.config.maxMemoryCount = 120
        
        // 🔊 CONFIGURACIÓN DE AUDIO: Permitir sonido en modo silencio
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("[AppDelegate] ✅ AudioSession configurado: .playback (ignora switch de silencio)")
        } catch {
            print("[AppDelegate] ❌ Error configurando AudioSession: \(error.localizedDescription)")
        }

        // Queremos recibir APNs (silent push) para Phone Auth
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }

    // iOS 10+ con background fetch: reenviar a FirebaseAuth
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if Auth.auth().canHandleNotification(userInfo) {
            print("[AppDelegate] 📬 Notificación manejada por FirebaseAuth (fetch)")
            completionHandler(.noData)
            return
        }
        // Maneja aquí otras notificaciones de tu app si las tienes
        completionHandler(.noData)
    }

    // Variante sin fetch (por compatibilidad)
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) {
        if Auth.auth().canHandleNotification(userInfo) {
            print("[AppDelegate] 📬 Notificación manejada por FirebaseAuth")
            return
        }
        // Otras notificaciones de tu app…
    }

    // Debug (opcional) de registro APNs
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[AppDelegate] 🔑 APNs deviceToken registrado: \(deviceToken.count) bytes")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AppDelegate] ❌ Falló registro APNs: \(error.localizedDescription)")
    }
}

// MARK: - Main App (SwiftUI)
@main
struct FoodApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                // URL schemes y enlaces universales que abren la app
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                // Universal Links vía NSUserActivity
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        handleIncomingURL(url)
                    }
                }
        }
    }

    // MARK: - Manejo de URLs (Auth y Google)
    private func handleIncomingURL(_ url: URL) {
        print("[FoodApp] 🔗 URL recibida: \(url.absoluteString)")

        // Firebase Auth (teléfono/email)
        if Auth.auth().canHandle(url) {
            print("[FoodApp] ✅ URL manejada por Firebase Auth")
            return
        }

        // Google Sign-In (si lo usas)
        #if canImport(GoogleSignIn)
        if GIDSignIn.sharedInstance.handle(url) {
            print("[FoodApp] ✅ URL manejada por Google Sign-In")
            return
        }
        #endif

        print("[FoodApp] ℹ️ URL no manejada por Firebase/Google")
    }
}
