# MANUAL DE IMPLEMENTACIÓN TÉCNICA: RECOLECCIÓN DE DATOS Y ANALÍTICA EN IOS

Este manual detalla paso a paso cómo implementar la recolección de datos en la app iOS de FoodTook para alimentar cada métrica del Admin Dashboard. Se prioriza la eficiencia energética (batería), el uso de datos del usuario y el costo CERO o mínimo en infraestructura.

## 1. PRINCIPIOS DE DISEÑO IOS (BATTERY & DATA FIRST)

En lugar de enviar datos constantemente, la app debe comportarse como un "recolector silencioso" que acumula inteligentemente y envía solo cuando es eficiente.

*   Regla de Oro: Nunca despertar la radio del celular para enviar un solo evento de analítica (a menos que sea dinero real).
*   Estrategia: "Piggybacking". Aprovechar cuando la app ya está haciendo una llamada de red (ej. cargar el feed) para "colar" el paquete de analítica comprimido.
*   Herramienta Clave: `BackgroundTasks Framework` de Apple. Permite programar el envío de datos pesados (historial de swipes del día) para cuando el usuario esté durmiendo y el celular cargando con Wi-Fi.

---

## 2. STACK TECNOLÓGICO "LOW COST" (GRATUITO / BARATO)

Este stack maximiza el uso de capas gratuitas (Free Tier) y recursos nativos.

A. SDK de Analítica: Firebase Analytics
*   Uso en FoodTook: Eventos base, Crashlytics, Audiencias.
*   Costo: Gratuito ilimitado.
*   Por qué esta: Estándar de industria, sin mantenimiento de servidor.

B. Data Warehouse: BigQuery (GCP)
*   Uso en FoodTook: Almacén central de datos.
*   Costo: Free Tier de 10GB almacenamiento + 1TB de consultas al mes (Suficiente para MVP).
*   Por qué esta: Escala infinita, SQL estándar, solo pagas si creces mucho.

C. Almacenamiento Local iOS: Swift CoreData
*   Uso en FoodTook: Buffering local en iPhone para guardar eventos offline.
*   Costo: $0 (Recurso del dispositivo).
*   Por qué esta: Nativo, cero dependencias externas, optimizado por Apple.

D. Ingesta de Datos: Cloud Functions
*   Uso en FoodTook: Recibir JSON comprimido desde el iPhone.
*   Costo: Free Tier de 2 millones de invocaciones al mes.
*   Estrategia de Ahorro: Enviar batches grandes (ej. 1 vez cada hora o al final del día) en lugar de muchos pequeños, para no consumir invocaciones.

E. Visualización: JSON Estático en Cloud Storage
*   Uso en FoodTook: El Dashboard lee un archivo `stats.json` pre-calculado, no la base de datos.
*   Costo: Lectura de archivo estático es casi gratis comparado con consultas a base de datos.
*   Por qué esta: Elimina costos de lectura de Firestore/SQL cada vez que el admin entra al panel.

---

## 3. IMPLEMENTACIÓN DETALLADA POR PANTALLA Y MÉTRICA

Aquí se detalla la lógica de recolección para CADA métrica definida en el Admin Dashboard.

### PANTALLA 1: COMMAND CENTER (Vista General)

#### A. North Star Metrics (Críticas)
1.  **GMV Total (Valor Bruto)**
    *   **Recolección:** Backend (Stripe/Pasarela).
    *   **Envío:** Automático al confirmar pago.
    *   **iOS:** No participa en el cálculo, solo inicia la orden.

2.  **Ingresos Netos**
    *   **Recolección:** Backend (Cálculo post-pago).
    *   **Envío:** N/A.

3.  **Pedidos Completados**
    *   **Recolección:** Backend (Estado de orden = Delivered).
    *   **Envío:** N/A.

4.  **Margen de Contribución**
    *   **Recolección:** Backend (Calculado: GMV - Costos).
    *   **Envío:** N/A.

5.  **Restaurantes Activos**
    *   **Recolección:** Backend (Query: COUNT DISTINCT restaurantes con >0 pedidos).
    *   **Envío:** N/A.

6.  **Market Health Score**
    *   **Recolección:** Backend (Algoritmo compuesto de 5 variables).
    *   **Envío:** N/A.

#### B. Métricas Secundarias (Comportamiento)
7.  **Orders / User**
    *   **Recolección:** Backend (Query: Total Orders / Total Users).
    *   **Envío:** N/A.

8.  **Cost / Order (CPO)**
    *   **Recolección:** Backend (Costos logísticos + promos).
    *   **Envío:** N/A.

9.  **View-to-Order Rate**
    *   **Comportamiento iOS:** El usuario entra a ver el menú de un restaurante.
    *   **Evento:** `menu_session_summary`.
    *   **Datos:** `restaurant_id`, `duration_sec`, `added_to_cart` (bool), `items_viewed` (count).
    *   **Frecuencia Envío:** **Batch (3 al día)**. Se acumulan todas las vistas de menú en CoreData y se envían juntas.

10. **% Feed Orders (Ventas desde Social)**
    *   **Comportamiento iOS:** El usuario hace clic en "Pedir" desde un video del feed.
    *   **Evento:** `order_source_tracked`.
    *   **Datos:** `source: "feed"`, `content_id: "video_123"`.
    *   **Frecuencia Envío:** **Real-Time** (Se adjunta al payload de creación de la orden).

11. **LTV / CAC Ratio**
    *   **Recolección:** Backend (LTV calculado vs CAC input manual/API marketing).
    *   **Envío:** N/A.

### PANTALLA 2: GROWTH (Crecimiento)

#### A. Adquisición
12. **Nuevos Usuarios**
    *   **Comportamiento iOS:** Registro exitoso.
    *   **Evento:** `sign_up_success`.
    *   **Frecuencia Envío:** **Real-Time**.

13. **Tasa de Activación (7d)**
    *   **Comportamiento iOS:** Usuario nuevo hace su primera acción de valor (add to cart).
    *   **Evento:** `activation_milestone`.
    *   **Datos:** `days_since_signup`, `action_type`.
    *   **Frecuencia Envío:** **Real-Time**. Es un hito crítico.

14. **CAC**
    *   **Recolección:** Externa (Ads APIs).
    *   **Envío:** N/A.

15. **Payback CAC**
    *   **Recolección:** Backend (Cálculo financiero).
    *   **Envío:** N/A.

#### B. Engagement
16. **DAU (Usuarios Activos Diarios)**
    *   **Comportamiento iOS:** Usuario abre la app.
    *   **Evento:** `app_open`.
    *   **Datos:** `user_id`, `timestamp`.
    *   **Frecuencia Envío:** **Batch (3 al día)**. No necesitamos saber al segundo que entró, solo que entró hoy.

17. **MAU (Usuarios Activos Mensuales)**
    *   **Recolección:** Backend (Agregación de DAUs).
    *   **Envío:** N/A.

18. **Stickiness (DAU/MAU)**
    *   **Recolección:** Backend (Cálculo).
    *   **Envío:** N/A.

19. **Viral Coefficient**
    *   **Comportamiento iOS:** Usuario comparte un enlace de referido.
    *   **Evento:** `share_action`.
    *   **Datos:** `content_type` (restaurante/app), `channel` (whatsapp/instagram).
    *   **Frecuencia Envío:** **Real-Time**.

#### C. Retención
20. **LTV Cohorte**
    *   **Recolección:** Backend (Historial financiero).
    *   **Envío:** N/A.

21. **Repeat Rate**
    *   **Recolección:** Backend (Historial de órdenes).
    *   **Envío:** N/A.

### PANTALLA 3: ATTENTION & CONTENT (Social)

22. **Posts Creados**
    *   **Recolección:** Backend (Tabla `posts`).
    *   **Envío:** N/A.

23. **Conversión Social→Pedido**
    *   **Comportamiento iOS:** Clic en botón "Pedir" dentro de un video.
    *   **Evento:** `social_conversion`.
    *   **Frecuencia Envío:** **Real-Time** (Junto con la orden).

24. **Avg Session Time**
    *   **Comportamiento iOS:** Tiempo total con la app en primer plano.
    *   **Evento:** `daily_usage_summary`.
    *   **Datos:** `total_foreground_time_sec`.
    *   **Frecuencia Envío:** **Batch (1 al día)**. Se envía en la noche vía BackgroundTasks.

25. **Swipes per Session**
    *   **Comportamiento iOS:** Usuario desliza videos en el feed.
    *   **Evento:** `feed_session_summary`.
    *   **Datos:** `swipes_count`, `likes_count`, `shares_count`.
    *   **Frecuencia Envío:** **Batch (3 al día)**. Se guarda un contador local y se envía acumulado.

26. **Stories per Session**
    *   **Comportamiento iOS:** Vistas de stories.
    *   **Evento:** `story_view_summary`.
    *   **Datos:** `count`.
    *   **Frecuencia Envío:** **Batch (3 al día)**. Junto con el de Swipes.

27. **Scroll Depth**
    *   **Comportamiento iOS:** Profundidad en el feed principal.
    *   **Evento:** `feed_depth_summary`.
    *   **Datos:** `max_scroll_percentage`.
    *   **Frecuencia Envío:** **Batch (3 al día)**.

28. **View Completion Rate**
    *   **Comportamiento iOS:** Porcentaje de video visto.
    *   **Evento:** `video_engagement`.
    *   **Datos:** Array de objetos `[{id: "v1", pct: 100}, {id: "v2", pct: 50}]`.
    *   **Frecuencia Envío:** **Batch (3 al día)**. Se agrupan múltiples videos en un solo paquete.

### PANTALLA 4: OPERATIONS (Operaciones)

29. **Tiempo Entrega Promedio**
    *   **Comportamiento iOS (Rider App):** Cambio de estados del pedido.
    *   **Evento:** `order_status_change`.
    *   **Datos:** `status` (picked_up, delivered), `gps_lat`, `gps_lon`.
    *   **Frecuencia Envío:** **Real-Time**. Crítico para la operación.

30. **On-Time Rate**
    *   **Recolección:** Backend (Comparación Tiempo Real vs Promesa).
    *   **Envío:** N/A.

31. **Tiempo Asignación**
    *   **Recolección:** Backend (Tiempo desde 'Created' hasta 'RiderAccepted').
    *   **Envío:** N/A.

32. **Utilización Repartidor**
    *   **Comportamiento iOS (Rider App):** Tiempo disponible vs tiempo en orden.
    *   **Evento:** `rider_shift_summary`.
    *   **Datos:** `active_time`, `idle_time`.
    *   **Frecuencia Envío:** **Al finalizar turno (Batch)**.

### PANTALLA 5: QUALITY & RISK (Calidad)

33. **Precisión Pedido**
    *   **Recolección:** Backend (% de pedidos sin reporte de error).
    *   **Envío:** N/A.

34. **Tasa de Reclamos**
    *   **Comportamiento iOS:** Usuario envía ticket de soporte.
    *   **Evento:** `ticket_created`.
    *   **Frecuencia Envío:** **Real-Time**.

35. **Tasa de Reembolsos**
    *   **Recolección:** Backend (Transacciones de refund).
    *   **Envío:** N/A.

36. **NPS Cliente**
    *   **Comportamiento iOS:** Usuario responde encuesta post-pedido.
    *   **Evento:** `nps_response`.
    *   **Datos:** `score`, `comment`.
    *   **Frecuencia Envío:** **Real-Time**.

37. **Reliability Score**
    *   **Recolección:** Backend (Score calculado).
    *   **Envío:** N/A.

38. **Fraud Flags**
    *   **Comportamiento iOS:** Cambio sospechoso de dispositivo/IP.
    *   **Evento:** `security_alert`.
    *   **Frecuencia Envío:** **Real-Time**.

### PANTALLA 6: FINANCIAL CONTROL

39. **Todos los KPIs Financieros (Take Rate, Costos, Margen, EBITDA)**
    *   **Recolección:** Backend (Sistema Contable/Stripe).
    *   **Envío:** N/A. El iPhone no calcula finanzas.

### PANTALLA 7: GEOGRAPHY (Geo)

40. **Ciudades Activas / Penetración**
    *   **Recolección:** Backend (Direcciones de usuarios).
    *   **Envío:** N/A.

41. **Densidad de Demanda**
    *   **Comportamiento iOS:** Ubicación aproximada al abrir la app.
    *   **Evento:** `user_location_ping`.
    *   **Datos:** `city`, `sector` (No lat/long exacta por privacidad, solo zona).
    *   **Frecuencia Envío:** **Batch (1 al día)**. Solo necesitamos saber dónde está el usuario habitualmente.

---

## 4. GUÍA DE IMPLEMENTACIÓN TÉCNICA EN IPHONE (SWIFT)

### Paso 1: El Gestor de Analítica (AnalyticsManager.swift)

Crear un Singleton que centralice toda la lógica.

```swift
class AnalyticsManager {
    static let shared = AnalyticsManager()
    private var eventBuffer: [AnalyticsEvent] = []
    private let bufferLimit = 50

    // Función principal que usan los desarrolladores
    func log(_ eventName: String, params: [String: Any], priority: EventPriority) {
        let event = AnalyticsEvent(name: eventName, params: params, timestamp: Date())
        
        if priority == .critical {
            sendImmediately(event) // Para pagos, errores (P0)
        } else {
            addToBuffer(event) // Para swipes, views (P1)
        }
    }

    private func addToBuffer(_ event: AnalyticsEvent) {
        eventBuffer.append(event)
        if eventBuffer.count >= bufferLimit {
            flushBuffer() // Enviar lote comprimido
        }
    }
    
    // Se llama al cerrar la app
    func appWillResignActive() {
        if !eventBuffer.isEmpty {
            saveToDisk(eventBuffer) // Persistir en CoreData para envío futuro
        }
    }
}
```

### Paso 2: Compresión GZIP

Antes de enviar el JSON al servidor, comprimirlo reduce el tamaño en un 80-90%.

```swift
func compressAndSend(_ events: [AnalyticsEvent]) {
    let jsonData = try? JSONSerialization.data(withJSONObject: events.map { $0.dictionary })
    let compressedData = jsonData?.gzipped() // Usar librería GzipSwift
    
    var request = URLRequest(url: apiURL)
    request.httpMethod = "POST"
    request.httpBody = compressedData
    request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
    
    // Enviar...
}
```

### Paso 3: Background Tasks (Envío Nocturno)

Registrar una tarea en `Info.plist` y `AppDelegate` para enviar datos viejos sin molestar al usuario.

```swift
// En AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.foodtook.analytics_upload", using: nil) { task in
        self.handleAnalyticsUpload(task: task as! BGProcessingTask)
    }
    return true
}

func scheduleUpload() {
    let request = BGProcessingTaskRequest(identifier: "com.foodtook.analytics_upload")
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = true // Solo si está cargando (opcional pero recomendado)
    try? BGTaskScheduler.shared.submit(request)
}
```
