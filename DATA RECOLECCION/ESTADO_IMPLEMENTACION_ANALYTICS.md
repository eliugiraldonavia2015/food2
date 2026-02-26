# ESTADO DE IMPLEMENTACIÓN DE ANALÍTICA (LIVE STATUS)

Este documento refleja en tiempo real qué eventos y métricas están **ya implementados y funcionando** en la versión actual del código. Se actualiza automáticamente conforme avanza el desarrollo.

**Última actualización:** 26/02/2026

---

## 1. INFRAESTRUCTURA (CORE)
| Componente | Estado | Descripción | Ubicación |
| :--- | :---: | :--- | :--- |
| **Firebase SDK** | ✅ | Activado en `GoogleService-Info.plist`. | `AppLifecycle.swift` |
| **CoreData (Manual)** | ✅ | Modelo de datos creado programáticamente para evitar errores de compilación `.momd`. | `AnalyticsPersistence.swift` |
| **Manager** | ✅ | Singleton `AnalyticsManager` que orquesta todo. Logs mejorados para ver `screen_name`. | `AnalyticsManager.swift` |
| **Background Flush** | ✅ | Envío de datos pendientes al cerrar la app. | `SceneDelegate.swift` |
| **Clean Tracking** | ✅ | Desactivado `FirebaseAutomaticScreenReporting` en `Info.plist` para evitar duplicados. | `Info.plist` |

---

## 2. EVENTOS DE SISTEMA Y USUARIO
| Evento (Nombre Técnico) | Trigger | Parámetros | Estado |
| :--- | :--- | :--- | :---: |
| `app_open` | Al iniciar la app (Launch). | `session_id`, `timestamp` | ✅ |
| `app_foreground` | Al volver de segundo plano. | `session_id` | ✅ |
| `app_background` | Al minimizar la app. | `session_id` | ✅ |
| **User Identity** | Login / Signup exitoso. | `user_id` (Seteado como propiedad global). | ✅ |
| **Logout** | Cerrar sesión. | Limpieza de `user_id`. | ✅ |

---

## 3. PANTALLAS (SCREEN VIEWS)
| Pantalla | Nombre Evento | Parámetros Extra | Estado |
| :--- | :--- | :--- | :---: |
| **Feed Principal** | `screen_view` (feed_home) | `active_tab` (foryou/following) | ✅ |
| **Dashboard Restaurante** | `screen_view` (restaurant_dashboard) | `section` (Tablero/Pedidos/...) | ✅ |
| **Carrito de Compras** | `screen_view` (cart_screen) | `restaurant`, `total_items`, `value` | ✅ |
| **Checkout** | `screen_view` (checkout_flow) | - | ⏳ Pendiente |
| **Perfil Usuario** | `screen_view` (user_profile) | - | ⏳ Pendiente |

---

## 4. ACCIONES DE NEGOCIO (EVENTS)
| Categoría | Evento | Trigger | Estado |
| :--- | :--- | :--- | :---: |
| **Growth** | `sign_up` | Registro completado. | ⏳ Pendiente |
| **Discovery** | `video_view` | Ver video > 2 seg. | ⏳ Pendiente |
| **Commerce** | `add_to_cart` | Click en botón agregar. | ⏳ Pendiente |
| **Commerce** | `purchase` | Pago exitoso confirmado. | ⏳ Pendiente |
| **Social** | `like` | Dar like a un video. | ⏳ Pendiente |

---

> **Leyenda:**
> ✅ = Implementado y en código.
> ⏳ = En cola de desarrollo.
> ❌ = Bloqueado o descartado.
