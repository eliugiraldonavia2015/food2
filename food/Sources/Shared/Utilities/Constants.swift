//
//  Constants.swift
//  food
//
//  Created by eliu giraldo on 28/11/25.
//

// Sources/Shared/Utilities/Constants.swift
import Foundation

/// Centraliza todas las constantes de la aplicación para evitar hardcoded values
public enum AppConstants {
    /// Configuración de Firebase
    public enum Firebase {
        /// Nombre de la base de datos principal
        public static let databaseName = "logincloud"
        
        /// Host de Firestore
        public static let firestoreHost = "firestore.googleapis.com"
        
        /// Colección de usuarios
        public static let usersCollection = "users"
        
        public static let restaurantsCollection = "restaurants"
        public static let sectionCatalogCollection = "section_catalog"
        public static let menuSectionsCollection = "menu_sections"
        public static let menuItemsCollection = "menu_items"
    }
    
    /// Configuración de imágenes
    public enum Images {
        /// Tamaño máximo para imágenes de perfil (1MB)
        public static let profileImageMaxSize = 1024 * 1024
        
        /// Calidad de compresión para imágenes
        public static let imageCompressionQuality: CGFloat = 0.85
    }
    
    /// Configuración de validación
    public enum Validation {
        /// Mínimo de caracteres para contraseñas
        public static let minPasswordLength = 8
        
        /// Mínimo de intereses requeridos
        public static let minInterests = 3
        
        /// Máximo de intereses permitidos
        public static let maxInterests = 15
    }
}
