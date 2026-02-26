# MANUAL DE IMPLEMENTACIÓN: SISTEMA DE RECOLECCIÓN DE DATOS FOODTOOK

Este documento es la guía técnica definitiva para implementar la arquitectura de recolección de datos "Silent & Efficient" en la aplicación iOS de FoodTook.

**Objetivo:** Implementar un sistema de analítica que no consuma batería ni datos innecesarios, capaz de funcionar offline y alimentar el Admin Dashboard con precisión del 100%.

---

## FASE 1: PREPARACIÓN Y ARQUITECTURA (CIMIENTOS)

Antes de medir cualquier evento, debemos construir la "tubería" que transportará los datos.

### Etapa 1.1: Configuración de Herramientas Externas (Infraestructura)
1.  **Firebase Project Setup:**
    *   Asegurar que el proyecto de Firebase esté activo y vinculado a la app iOS (`GoogleService-Info.plist` actualizado).
    *   Habilitar **Google Analytics** en la consola de Firebase.
2.  **BigQuery Link (Vital):**
    *   En la consola de Firebase -> Settings -> Integrations -> BigQuery -> Link.
    *   **Configuración:** Habilitar exportación diaria y streaming (opcional según presupuesto, batch diario es suficiente para empezar).
    *   *Resultado:* Los eventos crudos de Firebase empezarán a fluir a BigQuery automáticamente.

### Etapa 1.2: CoreData Stack (El Buffer Offline)
Necesitamos un lugar local para guardar eventos cuando no hay red o cuando queremos ahorrar batería.
1.  **Crear Modelo de Datos (`Analytics.xcdatamodeld`):**
    *   **Entidad:** `AnalyticsEvent`
    *   **Atributos:**
        *   `id` (UUID, String)
        *   `name` (String) - Ej: "view_menu"
        *   `parameters` (Binary Data / JSON String) - Parámetros del evento.
        *   `timestamp` (Date) - Cuándo ocurrió.
        *   `priority` (Integer) - 1: Real-time, 2: Batch, 3: Background.
        *   `status` (String) - "pending", "sending", "sent".
2.  **Persistence Controller:**
    *   Crear `AnalyticsPersistence.swift` en `Sources/Services`.
    *   Configurar el stack de CoreData para ser ligero (usar contexto de background para escrituras).

### Etapa 1.3: El Cerebro - `AnalyticsManager`
Crear un Singleton que centralice TODA la lógica. Nadie más debe hablar con Firebase o CoreData directamente para analítica.

*   **Archivo:** `Sources/Services/AnalyticsManager.swift`
*   **Responsabilidades:**
    *   `log(event: String, params: [String: Any], priority: Priority)`
    *   Decidir si enviar ahora (Firebase directo) o guardar (CoreData).
    *   Manejar la sesión de usuario (User Properties).

---

## FASE 2: INSTRUMENTACIÓN BASE Y CICLO DE VIDA

Medir lo básico: sesiones, usuarios y estado de la app.

### Etapa 2.1: Inicialización en el Arranque
1.  **En `AppLifecycle.swift` / `AppApp.swift`:**
    *   Inicializar `AnalyticsManager.shared.start()`.
    *   Registrar tareas de background (`BGTaskScheduler`).
2.  **Identificación de Usuario:**
    *   En `AuthService.swift` (Login/Signup exitoso):
    *   Llamar a `AnalyticsManager.shared.identifyUser(userId: String, properties: [String: Any])`.
    *   *Propiedades clave:* `user_type` (client/rider/partner), `app_version`, `device_model`.

### Etapa 2.2: Tracking de Sesión y Pantallas
1.  **Modificar `ContentView.swift` o Router principal:**
    *   Implementar un observador de cambios de vista (`onAppear`).
    *   Log automático de `screen_view` con `screen_name`.
2.  **Métricas de "Vida" de la App:**
    *   Detectar cuando la app pasa a background (`sceneWillResignActive`).
    *   Calcular `session_duration` y guardar el evento.

---

## FASE 3: IMPLEMENTACIÓN POR MÓDULOS DE NEGOCIO

Aquí conectamos la lógica de negocio con el `AnalyticsManager`. Usar la taxonomía definida en `DATA RECOLECCION.md`.

### Etapa 3.1: Módulo GROWTH (Adquisición & Onboarding)
*   **Archivos a tocar:** `OnboardingView.swift`, `SignupUseCase.swift`.
*   **Eventos:**
    *   `sign_up_started` (Al ver la pantalla de registro).
    *   `sign_up_completed` (Al crear la cuenta exitosamente). Params: `method` (email/apple).
    *   `tutorial_completion` (Si hay tutorial, paso a paso).

### Etapa 3.2: Módulo DISCOVERY (Feed & Menús)
*   **Archivos a tocar:** `FeedView.swift`, `FeedVideoPlayer.swift`, `FullMenuView.swift`.
*   **Eventos (Lógica Batch - NO ENVIAR EN REAL-TIME):**
    *   `video_impression`: Al ver un video > 2 segundos.
    *   `video_complete`: Al terminar un video.
    *   `menu_view`: Al entrar al perfil de un restaurante.
    *   *Estrategia:* Guardar en CoreData. Enviar resumen cada 10 videos o al salir de la app.

### Etapa 3.3: Módulo COMMERCE (Carrito & Checkout)
*   **Archivos a tocar:** `CartScreenView.swift`, `CheckoutView.swift`, `OrdersManagementView.swift`.
*   **Eventos (Prioridad Alta - REAL-TIME):**
    *   `add_to_cart`: Params: `item_id`, `price`, `restaurant_id`.
    *   `checkout_start`: Al dar click en "Ir a pagar".
    *   `purchase_success`: **CRÍTICO**. Params: `order_id`, `amount`, `currency`, `items_count`.
    *   `purchase_fail`: Params: `error_reason`.

### Etapa 3.4: Módulo SOCIAL (Interacciones)
*   **Archivos a tocar:** `FeedView.swift`, `SocialButton.swift`.
*   **Eventos:**
    *   `like_action`: Params: `content_id`.
    *   `share_action`: Params: `content_id`, `destination`.

---

## FASE 4: INFRAESTRUCTURA DE ENVÍO Y EFICIENCIA (AVANZADO)

Implementar la lógica "Silent" para no matar la batería.

### Etapa 4.1: Background Tasks
1.  **Configurar `Info.plist`:**
    *   Agregar permiso `Permitted background task scheduler identifiers`.
    *   ID sugerido: `com.foodtook.analytics.sync`.
2.  **Implementar Handler:**
    *   En `AnalyticsManager`, crear función `syncPendingEvents()`.
    *   Lógica: Leer eventos de CoreData -> Empaquetar en JSON -> Enviar a Cloud Function -> Borrar de CoreData si éxito.

### Etapa 4.2: Compresión (GZIP)
1.  **Integrar Librería:**
    *   Usar `GzipSwift` (o nativo si disponible en iOS recientes).
2.  **Flujo de Envío:**
    *   JSON Array -> Data -> Gzip -> Request HTTP (POST).
    *   Header: `Content-Encoding: gzip`.

### Etapa 4.3: Cloud Functions (Ingesta)
1.  **Desplegar Función:**
    *   Nombre: `ingestAnalyticsBatch`.
    *   Trigger: HTTP.
    *   Lógica: Recibir Gzip -> Descomprimir -> Validar -> Insertar en BigQuery (Tabla `raw_events`).

---

## FASE 5: VALIDACIÓN Y QA (GARANTÍA DE CALIDAD)

No asumir que funciona. Verificar.

### Etapa 5.1: Debugging Local
1.  **Firebase DebugView:**
    *   Activar argumentos de lanzamiento en Xcode: `-FIRDebugEnabled`.
    *   Verificar en consola de Firebase que los eventos llegan en tiempo real (solo para desarrollo).
2.  **Logs de Consola:**
    *   `AnalyticsManager` debe imprimir logs claros: `[Analytics] 💾 Saved to CoreData: view_menu` o `[Analytics] 🚀 Sent to Firebase: purchase`.

### Etapa 5.2: Validación de Datos
1.  **Prueba de Estrés Offline:**
    *   Poner modo avión.
    *   Usar la app (ver videos, agregar al carrito).
    *   Cerrar app.
    *   Activar red.
    *   Abrir app y verificar que los eventos se envían (Flush).
2.  **Auditoría en BigQuery:**
    *   Hacer query simple: `SELECT event_name, COUNT(*) FROM events_table GROUP BY event_name`.
    *   Verificar que no haya duplicados ni parámetros nulos.

---

## RESUMEN DE ARTEFACTOS A CREAR

| Archivo | Ubicación | Propósito |
| :--- | :--- | :--- |
| `Analytics.xcdatamodeld` | `Sources/Services/Analytics/` | Esquema de base de datos local. |
| `AnalyticsPersistence.swift`| `Sources/Services/Analytics/` | Controlador de CoreData. |
| `AnalyticsManager.swift` | `Sources/Services/Analytics/` | Singleton principal (Fachada). |
| `AnalyticsEvent+Extensions.swift` | `Sources/Models/` | Helpers para transformar CoreData a JSON. |
| `ingest_analytics.js` | `(Backend/Functions)` | Función Cloud para recibir batches. |
