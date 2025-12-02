// Sources/Shared/Utilities/ErrorHandler.swift
import Foundation
import os.log
import FirebaseAuth // Solo para AuthErrorCode

/// Manejador centralizado de errores para toda la aplicación
public final class ErrorHandler {
    /// Singleton para acceso global
    public static let shared = ErrorHandler()
    
    private init() {}
    
    /// Registra un error en el sistema de logging
    public func log(_ error: Error, function: String = #function, file: String = #file, line: Int = #line) {
        let errorMessage = createErrorMessage(error, function: function, file: file, line: line)
        os_log("%@", log: .default, type: .error, errorMessage)
    }
    
    /// Genera un mensaje amigable para el usuario
    public func getUserFriendlyMessage(for error: Error) -> String {
        // ✅ CORRECCIÓN: Usar cast directo en lugar de condicional
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.networkError.rawValue:
            return "Error de conexión. Verifica tu conexión a internet."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Demasiados intentos. Por favor, intenta más tarde."
        default:
            break
        }
        
        return "Ha ocurrido un error inesperado. Por favor, intenta nuevamente."
    }
    
    // MARK: - Private Helpers
    
    private func createErrorMessage(_ error: Error, function: String, file: String, line: Int) -> String {
        let fileName = (file as NSString).lastPathComponent
        return "[\(fileName):\(line)] \(function) - \(error.localizedDescription)"
    }
}
