// Sources/Application/SceneDelegate.swift
import UIKit
import FirebaseAuth
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
import FirebaseCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Inicializar la aplicación al conectar la escena
        AppLifecycle.initializeApp()
        
        // Log de inicio de sesión de app
        AnalyticsManager.shared.log(event: "app_open", priority: .realTime)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may be re-connected later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        AnalyticsManager.shared.log(event: "app_foreground", priority: .background)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        AnalyticsManager.shared.log(event: "app_background", priority: .background)
        
        // Intentar enviar datos pendientes antes de dormir
        AnalyticsManager.shared.flush()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        // 1) Firebase Auth (reCAPTCHA / email link / phone)
        if Auth.auth().canHandle(url) {
            print("[SceneDelegate] ✅ URL manejada por Firebase Auth")
            return
        }

        // 2) Google Sign-In (si lo usas)
        #if canImport(GoogleSignIn)
        if GIDSignIn.sharedInstance.handle(url) {
            print("[SceneDelegate] ✅ URL manejada por Google Sign-In")
            return
        }
        #endif

        print("[SceneDelegate] ℹ️ URL no manejada por Firebase/Google: \(url.absoluteString)")
    }
}
