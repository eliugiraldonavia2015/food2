# MANUAL TÉCNICO DE ANALÍTICA (LIVE STATUS)

Este documento es la fuente de verdad sobre la implementación de analítica en la app. Describe qué se mide, cómo se implementó técnicamente y el propósito de negocio detrás de cada métrica.

**Última actualización:** 26/02/2026

---

## 1. INFRAESTRUCTURA (CORE)

### 🟢 Gestor Central (`AnalyticsManager.swift`)
*   **Qué es:** Un Singleton que orquesta todo el flujo de datos.
*   **Por qué:** Para tener un único punto de entrada y no dispersar código de Firebase por toda la app.
*   **Cómo funciona:**
    *   Tiene una cola de prioridad: `realTime` (envío inmediato) y `batch` (envío diferido).
    *   Maneja la sesión del usuario (`session_id`) para agrupar eventos.
    *   Limpia los parámetros para asegurar que Firebase los acepte (solo Strings y Números).

### 🟢 Base de Datos Offline (`AnalyticsPersistence.swift`)
*   **Qué es:** Un stack de CoreData independiente del principal.
*   **Por qué:** Si el usuario no tiene internet o queremos ahorrar batería, guardamos los eventos aquí en lugar de perderlos.
*   **Detalle Técnico:** El modelo de datos (`AnalyticsEvent`) se crea programáticamente en Swift para evitar errores de compilación con archivos `.momd`.

### 🟢 Configuración Limpia (`Info.plist`)
*   **Qué es:** Desactivación de `FirebaseAutomaticScreenReportingEnabled`.
*   **Por qué:** Firebase por defecto inventa nombres de pantalla feos (`UIHostingController`). Lo desactivamos para usar solo nuestros nombres limpios (`feed_home`, `cart_screen`).

---

## 2. IDENTIDAD Y SESIÓN

### 👤 Identificación de Usuario
*   **Evento:** `identifyUser` (No es un evento, es una propiedad de usuario).
*   **Dónde:** `AuthService.swift` (Login/Signup).
*   **Para qué:** Para saber que "Juan Pérez" hoy es el mismo que entró ayer desde otro celular. Permite análisis de retención real.

### 🔄 Ciclo de Vida
*   **Eventos:** `app_open`, `app_background`, `app_foreground`.
*   **Dónde:** `SceneDelegate.swift`.
*   **Para qué:** Medir la frecuencia de uso y sesiones por día.
*   **Cómo:** Se disparan automáticamente al detectar cambios de estado en la `Scene`.

---

## 3. PANTALLAS (SCREEN VIEWS)

Implementado mediante el modificador `.analyticsScreen(name:properties:)` en `ViewExtensions.swift`.

| Pantalla | ID Técnico | Parámetros | Propósito de Negocio |
| :--- | :--- | :--- | :--- |
| **Feed Principal** | `feed_home` | `active_tab`: "foryou" / "following" | Saber qué contenido consumen más (algoritmo vs amigos). |
| **Dashboard Restaurante** | `restaurant_dashboard` | `section`: "Pedidos", "Menú", etc. | Identificar qué herramientas usan más los dueños de locales. |
| **Carrito** | `cart_screen` | `restaurant`: Nombre del local<br>`total_value`: Monto actual | Medir la intención de compra antes del checkout. |
| **Checkout** | `checkout_flow` | `items_count`: Cantidad platos<br>`total_value`: Monto final | Analizar el embudo de conversión final. |

---

## 4. EMBUDO DE VENTAS (COMMERCE)

Estos son los eventos más críticos para el dinero ($$$).

### 🛒 Intento de Compra
*   **ID Evento:** `checkout_attempt`
*   **Trigger:** Al hacer clic en el botón "Realizar Pedido" en `CheckoutView`.
*   **Por qué:** Para detectar usuarios que llegan al final pero fallan por tarjeta rechazada o duda de último segundo.

### 💰 Compra Exitosa
*   **ID Evento:** `purchase`
*   **Trigger:** Cuando la API confirma la orden y se muestra la pantalla de éxito.
*   **Parámetros Críticos:**
    *   `transaction_id`: UUID único para evitar duplicados.
    *   `value`: Monto total cobrado.
    *   `currency`: Moneda (USD/MXN).
    *   `items`: Lista de nombres de platos.
*   **Por qué:** Es la métrica reina. Genera los reportes de ingresos en el Dashboard.

---

## 5. PENDIENTES (PRÓXIMOS PASOS)

| Categoría | Evento | Estado | Prioridad |
| :--- | :--- | :---: | :---: |
| **Engagement** | `video_view` (Visto > 3s) | ✅ | Alta |
| **Social** | `like` (Interacción) | ⏳ | Media |
| **Growth** | `sign_up` (Registro completado) | ✅ | Alta |

---

> **Nota:** Todos los eventos "Real-time" se envían inmediatamente. Los eventos de interacción masiva (como `video_view`) se implementaron en modo "Batch" para optimizar red.
