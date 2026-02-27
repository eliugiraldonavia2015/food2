# GUÍA DE VISUALIZACIÓN DE DATOS 📊

Ahora que la app está enviando datos, aquí te explico a dónde van y cómo verlos.

---

## 1. ¿A DÓNDE SE ENVÍAN LOS DATOS?
Todos los eventos (`screen_view`, `purchase`, `sign_up`) viajan desde el iPhone del usuario hasta los servidores de Google a través del **SDK de Firebase Analytics**.

**El flujo es:**
`iPhone` ➡️ `AnalyticsManager (App)` ➡️ `Firebase SDK` ➡️ `Google Servers` ➡️ `Firebase Console`

---

## 2. ¿CÓMO PUEDO VERLOS?

Tienes 3 formas de ver la información, dependiendo de qué tan rápido la necesites:

### A. DebugView (TIEMPO REAL - DESARROLLO)
Ideal para probar si tu código funciona AHORA MISMO.
1.  Abre la consola de Firebase: [console.firebase.google.com](https://console.firebase.google.com)
2.  Ve a tu proyecto `food-2`.
3.  En el menú izquierdo, busca **Analytics** > **DebugView**.
4.  Ejecuta tu app en el simulador o dispositivo.
5.  Verás una línea de tiempo cayendo con iconos (🛒, 👤, 📱).
    *   Si haces clic en un evento, verás los parámetros que enviamos (ej: `restaurant_name: "Burger King"`).

> **Nota:** Para que funcione en Xcode, debes editar el esquema (`Product > Scheme > Edit Scheme`) y agregar el argumento `-FIRAnalyticsDebugEnabled` en "Arguments Passed on Launch".

### B. Dashboard General (RESUMEN - PRODUCCIÓN)
Ideal para ver tendencias (¿Subieron las ventas hoy?).
1.  En Firebase Console, ve a **Analytics** > **Dashboard**.
2.  Aquí verás gráficos bonitos automáticos:
    *   Usuarios activos por día.
    *   Ingresos totales (Revenue).
    *   Retención de usuarios.
    *   Eventos más populares.
> **Ojo:** Estos datos suelen tardar entre 1 y 24 horas en aparecer.

### C. BigQuery (ANÁLISIS PROFUNDO - SQL)
Ideal para preguntas complejas como: *"¿Cuántos usuarios que vieron el video de tacos compraron tacos en la siguiente hora?"*
1.  Si vinculas Firebase con BigQuery (recomendado), tendrás acceso a la base de datos cruda.
2.  El formato es una tabla gigante donde cada fila es un evento.

---

## 3. ¿QUÉ FORMATO TIENEN LOS DATOS?
Técnicamente, Firebase recibe un JSON. Nosotros nos encargamos de limpiarlo en `AnalyticsManager.swift` antes de enviarlo.

**Ejemplo de lo que recibe Firebase (y ves en BigQuery):**

```json
{
  "event_name": "purchase",
  "event_timestamp": 1708963200000,
  "user_id": "Ov2GLCBMA9...",
  "geo": {
    "country": "Mexico",
    "city": "Mexico City"
  },
  "device": {
    "category": "mobile",
    "os_version": "iOS 17.2"
  },
  "event_params": [
    { "key": "value", "value": { "double_value": 450.50 } },
    { "key": "currency", "value": { "string_value": "MXN" } },
    { "key": "items", "value": { "string_value": "['Tacos al Pastor', 'Coca Cola']" } }
  ]
}
```

---

## 4. RESUMEN DE EVENTOS CLAVE A BUSCAR

| Si quieres ver... | Busca este evento | Parámetro Clave |
| :--- | :--- | :--- |
| **Ventas Totales** | `purchase` | `value` (Suma total) |
| **Intención de Compra** | `checkout_attempt` | `restaurant` (Cuál vende más) |
| **Videos Vistos** | `video_view` | `video_id` (Cuál es viral) |
| **Usuarios Nuevos** | `sign_up` | `method` (Email vs Phone) |
| **Pantallas Populares** | `screen_view` | `screen_name` |

---

**Siguiente paso recomendado:**
Activa el modo Debug en Xcode (`-FIRAnalyticsDebugEnabled`) y navega por la app mientras observas la pantalla de **DebugView** en Firebase. Es "mágico" ver cómo aparecen tus eventos en vivo.
