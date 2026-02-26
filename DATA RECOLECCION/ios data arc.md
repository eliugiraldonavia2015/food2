# ARQUITECTURA MAESTRA DE RECOLECCIÓN DE DATOS IOS (FOODTOOK ECOSYSTEM)

Este documento define la especificación técnica inmutable para la recolección de datos en el ecosistema móvil de FoodTook. Cubre tres aplicaciones distintas:
1.  **FoodTook Client App** (Usuarios finales)
2.  **FoodTook Rider App** (Repartidores - *Próximamente*)
3.  **FoodTook Partner App** (Restaurantes - *Próximamente*)

El objetivo es alimentar el **Admin Suite** detallado en `DATA RECOLECCION.md` con precisión del 100%, maximizando la eficiencia de batería y datos.

---

## 1. PRINCIPIOS TÉCNICOS Y HERRAMIENTAS

### Filosofía: "Silent & Efficient"
La recolección de datos no debe impactar la experiencia del usuario (UX), la batería ni el plan de datos.
*   **Battery First:** Uso agresivo de `BackgroundTasks` para envíos diferidos cuando el dispositivo está cargando/Wi-Fi.
*   **Data Minimization:** Compresión GZIP antes de cualquier envío a red.
*   **Offline First:** Todo evento se guarda primero en `CoreData` (Buffer). Si no hay red, no se pierde nada.
*   **Contextual Batching (Session-Based):** NUNCA enviar eventos fragmentados de navegación. Agrupar interacciones lógicas (ej. múltiples visitas a menús en una sesión de compra) en un solo paquete coherente antes de persistir.

### Stack Tecnológico Seleccionado
| Herramienta | Uso | Justificación |
| :--- | :--- | :--- |
| **Swift CoreData** | **Buffer Local** | Nativo, persistente y rápido. Permite acumular eventos sin tocar la red hasta que sea eficiente hacerlo. |
| **Firebase Analytics** | **Eventos Estándar** | Gratuito, estándar de industria para métricas de funnel, retención y crashes. Integración nativa con BigQuery. |
| **Cloud Functions** | **Ingesta Batch** | Endpoint ligero para recibir paquetes JSON comprimidos de analítica personalizada (no soportada por eventos simples). |
| **BigQuery** | **Data Warehouse** | Almacén central donde convergen datos de Apps, Backend y Pasarelas de pago. |
| **GzipSwift** | **Compresión** | Reduce el payload de datos en ~90% antes del envío. |

### Estrategia de Envío (Frequency Policies)
1.  **REAL-TIME (P0):** Eventos críticos que afectan dinero o logística inmediata. Se envían al instante.
    *   *Ej: Pago realizado, Repartidor acepta pedido, Restaurante abre tienda.*
2.  **BATCH-WINDOW (P1):** Eventos importantes pero no urgentes. Se acumulan y se envían cada X minutos o al cumplir un tamaño de buffer (ej. 50 eventos).
    *   *Ej: Vistas de menú, Agregado al carrito.*
3.  **BACKGROUND-SYNC (P2):** Datos masivos de comportamiento. Se envían solo 1 o 2 veces al día (preferiblemente de noche/cargando).
    *   *Ej: Historial de swipes, mapas de calor, tiempos de sesión.*

---

## 2. DETALLE DE IMPLEMENTACIÓN POR PANTALLA Y MÉTRICA (ADMIN SUITE MAPPING)

A continuación, se detalla la recolección técnica para **CADA ÍTEM** definido en `DATA RECOLECCION.md`.

### A. COMMAND CENTER (Vista General)

#### KPIs Ejecutivos (North Star Metrics)
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **GMV Total** | Client App | Trigger al confirmar compra exitosa. | **REAL-TIME** | **Backend:** Registra monto bruto pre-deducciones.<br>**iOS:** Evento `checkout_completed` con `order_id` para redundancia. |
| **Ingresos Netos** | Backend | Calculado en servidor (GMV - Fees). | **N/A** | iOS no calcula esto. |
| **Pedidos Completados** | Rider App | Trigger al marcar "Entregado". | **REAL-TIME** | **Evento:** `order_delivered`.<br>**Data:** `order_id`, `gps_location`, `timestamp`. |
| **Margen de Contribución** | Backend | Calculado (Neto - Costo Logístico). | **N/A** | iOS no tiene datos de costos. |
| **Restaurantes Activos** | Partner App | Heartbeat o Venta realizada. | **REAL-TIME** | **Evento:** `store_open` o `order_accepted`.<br>**Lógica:** Si acepta >0 pedidos en periodo, cuenta como activo. |
| **Market Health Score** | Backend | Algoritmo compuesto. | **N/A** | Agregación de datos en BigQuery. |

#### Métricas Secundarias
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Orders / User** | Backend | Query SQL (Total Orders / Unique Users). | **N/A** | Dato derivado. |
| **Cost / Order (CPO)** | Backend | Sumatoria costos operativos. | **N/A** | Dato derivado. |
| **View-to-Order Rate** | Client App | Tracking de sesión en menú **(Lógica Agrupada)**. | **BATCH-WINDOW** | **Lógica Optimizada:** <br>El usuario puede navegar por N restaurantes antes de decidir.<br>1. Crear objeto `ShoppingSession` en memoria al abrir app.<br>2. Cada visita a restaurante se anexa a `session.visits[]`.<br>3. Al hacer checkout o matar la app, se guarda el evento `shopping_session_summary` con TODAS las visitas acumuladas.<br>**Evento:** `shopping_session_summary`.<br>**Data:** Array de `{rest_id, duration, items_viewed}` + `final_order_id` (si hubo). |
| **% Feed Orders** | Client App | Atribución de fuente. | **REAL-TIME** | **Lógica:** Si usuario añade al carrito desde video, guardar `source="feed"` en el objeto `Order`.<br>**Evento:** `add_to_cart` (param: `source`). |
| **LTV / CAC Ratio** | Backend | Integración con API Marketing (FB/Google). | **N/A** | iOS solo reporta `install` y `purchase`. |

#### Visualizaciones Gráficas
| Gráfico | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **1. Demanda y Revenue** | Backend (Orders Table) | Query: `SELECT date_trunc('day', created_at), SUM(total), COUNT(id) FROM orders GROUP BY 1`. |
| **2. Picos de Demanda** | Backend (Orders Table) | Query: `SELECT EXTRACT(HOUR FROM created_at), COUNT(id) FROM orders GROUP BY 1`. |
| **3. Revenue Mix** | Backend (Transactions Table) | Query: `SELECT type (commission, delivery_fee, ad_revenue), SUM(amount) FROM transactions GROUP BY 1`. |
| **4. GMV vs Margen** | Backend (Financials) | Query combinada de GMV total y Margen neto calculado diario. |
| **5. Time-to-Checkout** | Client App | **Evento:** `checkout_flow_time`.<br>**Lógica:** Timer inicia al entrar a carrito. Si usuario sale y vuelve, el timer se pausa/reanuda. Solo se envía al completar pago. |

#### Listas Top (Rankings)
| Lista | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **Restaurantes Top** | Backend (Orders + Reviews) | Agregación de GMV por `restaurant_id` y promedio de `rating`. |
| **Categorías Top** | Backend (OrderItems) | Join de `orders` con `items` y `categories`. Agregación de volumen. |

### B. GROWTH (Crecimiento)

#### Métricas de Adquisición
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Nuevos Usuarios** | Client App | Registro completado. | **REAL-TIME** | **Evento:** `sign_up`.<br>**Params:** `method` (email, apple, google). |
| **Tasa de Activación** | Client App | Primera compra del usuario. | **REAL-TIME** | **Evento:** `purchase`.<br>**Backend:** Marca flag `is_first_order` en usuario. |
| **CAC** | Backend | Integración MMP (AppsFlyer/Adjust). | **N/A** | Datos externos de campañas. |
| **Payback CAC** | Backend | Cálculo financiero. | **N/A** | - |

#### Métricas de Engagement
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **DAU / MAU** | Client App | Apertura de App. | **BATCH-WINDOW** | **Evento:** `app_open`.<br>**Firebase:** Lo calcula automático como `user_engagement`. |
| **Stickiness** | Backend | Cálculo DAU/MAU. | **N/A** | - |
| **Viral Coefficient** | Client App | Compartir enlace. | **REAL-TIME** | **Evento:** `share`.<br>**Params:** `content_type` (restaurante, plato), `target` (whatsapp). |

#### Métricas de Retención y Valor
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **LTV Cohorte** | Backend | Suma histórica de GMV por usuario. | **N/A** | - |
| **Repeat Rate** | Backend | Query SQL de reincidencia. | **N/A** | - |
| **LTV / CAC Ratio** | Backend | Cálculo financiero. | **N/A** | - |
| **Orders / User** | Backend | Query SQL. | **N/A** | - |

#### Visualizaciones Gráficas
| Gráfico | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **1. Crecimiento Usuarios** | Client App (Signups) | Histórico de eventos `sign_up` agrupados por día. |
| **2. Retención (Cohortes)** | Backend (Activity Log) | Análisis de matriz: Usuarios registrados en Mes X que volvieron en Mes X+1. |
| **3. LTV vs CAC** | Backend | Serie temporal de LTV promedio vs Costo promedio de adquisición. |
| **4. Funnel Viralidad** | Client App | Eventos secuenciales: `share_link` -> `link_click` (Web) -> `app_install` -> `sign_up`. |
| **5. Embudo Compra** | Client App | **Lógica Agrupada:** No enviar evento por cada paso. <br>1. Objeto `CheckoutSession` sigue al usuario. <br>2. Registra timestamps de: `view_menu`, `add_to_cart`, `view_checkout`. <br>3. Al pagar (o abandonar > 30min), enviar evento único `funnel_complete` con flags de pasos alcanzados. |
| **6. Crecimiento Oferta** | Partner App | Eventos: `restaurant_activated` agrupados por mes. |

### C. ATTENTION & CONTENT (Social)

#### KPIs Sociales Primarios
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Posts Creados** | Partner/Client | Subida exitosa de video. | **REAL-TIME** | **Evento:** `content_published`.<br>**Params:** `video_id`, `category`. |
| **Conv. Social -> Pedido** | Client App | Click en "Pedir" sobre video. | **REAL-TIME** | **Evento:** `social_conversion`.<br>**Params:** `video_id` -> Se une con `order_id` al pagar. |
| **Avg Session Time** | Client App | Cronómetro Foreground. | **BACKGROUND-SYNC** | **Lógica:** Iniciar timer en `DidBecomeActive`, parar en `WillResignActive`. Acumular delta.<br>**Evento:** `daily_usage_stat`. |
| **Swipes per Session** | Client App | Contador de gestos **(Batch Diario)**. | **BACKGROUND-SYNC** | **Lógica:** No enviar NADA durante uso. Incrementar contador local `Int`. Solo al final del día (Background Task) se envía el total. Ahorro masivo de red. |

#### Métricas de Engagement Profundo
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Stories per Session** | Client App | Contador de vistas stories. | **BACKGROUND-SYNC** | **Lógica:** Igual que Swipes. Contador local incrementa, envío único diario. |
| **Scroll Depth** | Client App | Índice máximo de lista visible. | **BACKGROUND-SYNC** | **Evento:** `feed_depth`.<br>**Params:** `max_item_index` / `total_items`. |
| **View Completion Rate** | Client App | % de video visto **(Agregación)**. | **BACKGROUND-SYNC** | **Lógica:** No enviar por video. <br>1. Crear mapa local `[VideoID: MaxPct]`. <br>2. Al cerrar app, calcular promedio del día o enviar mapa comprimido. |
| **View-to-Order Rate** | Client App | Conversión directa. | **REAL-TIME** | **Evento:** `video_order_conversion`. |

#### Visualizaciones Gráficas
| Gráfico | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **1. Engagement Social** | Client App (Interactions) | Serie temporal de suma diaria de `likes`, `comments`, `shares` y `orders_from_feed`. |
| **2. Embudo Social** | Client App | Pasos: `video_impression` -> `video_click_cta` -> `menu_view` -> `order_placed`. |

#### Tabla Top Creadores
| Lista | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **Top Creadores** | Backend (Aggregation) | Agrupar eventos `video_view` y `social_conversion` por `restaurant_id`. |

### D. OPERATIONS (Logística - Rider App)

#### KPIs Operativos y Logísticos
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Tiempo Entrega Promedio** | Rider App | Delta entre `picked_up` y `delivered`. | **REAL-TIME** | **Backend:** Calcula la diferencia exacta basada en timestamps del servidor. |
| **On-Time Rate** | Backend | Comparación vs Promesa. | **N/A** | - |
| **Tiempo Asignación** | Backend | Delta `order_created` -> `rider_accepted`. | **N/A** | - |
| **Utilización Repartidor** | Rider App | Estados de sesión del Rider **(Turno Completo)**. | **BATCH-WINDOW** | **Lógica:** Un Rider tiene un "Turno". <br>1. Al iniciar turno (`start_shift`), abrir sesión local. <br>2. Registrar timestamps de cambios de estado. <br>3. Al cerrar turno (`end_shift`), enviar objeto `ShiftSummary` completo. Evita micro-transacciones. |

#### Métricas de Eficiencia
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Cost per Order** | Backend | Suma de pago a rider + otros. | **N/A** | - |
| **Orders / km²** | Backend | Agregación geoespacial de entregas. | **N/A** | - |
| **Couriers / km²** | Rider App | Ubicación GPS periódica. | **REAL-TIME (Throttled)** | **Lógica Inteligente:** <br>- Si velocidad < 5km/h: Enviar cada 5 min (Ahorro batería). <br>- Si velocidad > 5km/h: Enviar cada 30 seg (Precisión tracking). |
| **Motivos Cancelación** | Client/Rider/Partner | Selección en UI de cancelación. | **REAL-TIME** | **Evento:** `order_cancelled`.<br>**Params:** `reason_code`, `comment`. |

#### Visualizaciones Gráficas
| Gráfico | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **1. Tiempos por Etapa** | Backend (Order Lifecycle) | Promedios de deltas: `created`->`accepted`, `accepted`->`ready`, `ready`->`picked_up`, `picked_up`->`delivered`. |
| **2. Waterfall Cost** | Backend (Financials) | Desglose de costos promedio por pedido (Rider Fee + Support Cost + Transac. Fee). |
| **3. Motivos Cancelación** | Backend (Order Status) | Gráfico de pastel agrupando por `cancellation_reason`. |

### E. QUALITY & RISK (Calidad)

#### Métricas de Calidad
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Precisión Pedido** | Client App | Reporte de "Items faltantes". | **REAL-TIME** | **Evento:** `support_ticket`.<br>**Params:** `issue_type="missing_item"`. |
| **Tasa de Reclamos** | Client App | Creación de ticket soporte. | **REAL-TIME** | **Evento:** `support_contact`. |
| **Tasa de Reembolsos** | Backend | Transacción reversa. | **N/A** | - |
| **NPS Cliente** | Client App | Encuesta post-delivery. | **REAL-TIME** | **UI:** Modal de estrellas (1-5).<br>**Evento:** `nps_rating`.<br>**Params:** `score`, `order_id`. |

#### Métricas de Riesgo
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Refund Impact** | Backend | Suma refunds / GMV. | **N/A** | - |
| **Reliability Score** | Backend | Algoritmo histórico. | **N/A** | - |
| **Fraud Flags** | Client App | Detección de anomalías. | **REAL-TIME** | **Lógica:** Detectar jailbreak, simulador, cambio súbito IP.<br>**Evento:** `security_flag`. |
| **Tickets Soporte** | Backend | Sistema de Ticketing (Zendesk/Interno). | **N/A** | - |

#### Visualizaciones Gráficas
| Gráfico | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **1. Incidentes Calidad** | Client App (Support) | Conteo de tickets agrupados por `issue_tag` (Frio, Tardanza, Incorrecto). |
| **2. Soporte Operativo** | Backend (Support System) | Serie temporal: Tickets Nuevos vs Tickets Cerrados. |

#### Tabla Ranking Confiabilidad
| Lista | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **Ranking Partners** | Backend | Score calculado: (Pedidos Exitosos / Total Pedidos) * 100 - Penalizaciones. |

### F. FINANCIAL CONTROL (Finanzas)

#### KPIs Financieros
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Take Rate** | Backend | Configuración comercial. | **N/A** | - |
| **Costo Promos** | Client App | Aplicación de cupón. | **REAL-TIME** | **Evento:** `coupon_applied`.<br>**Params:** `coupon_code`, `discount_amount`. |
| **Costo Logístico** | Backend | Pago calculado al rider. | **N/A** | - |
| **Margen Neto** | Backend | Cálculo final. | **N/A** | - |

#### Métricas de Salud Financiera
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **EBITDA Snapshot** | Backend | Sistema contable. | **N/A** | - |
| **Burn Rate** | Backend | Sistema contable. | **N/A** | - |
| **Runway** | Backend | Sistema contable. | **N/A** | - |
| **ARPU** | Backend | Revenue / Usuarios Activos. | **N/A** | - |

#### Visualizaciones Gráficas
| Gráfico | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **1. Ingresos vs Costos** | Backend | Barras apiladas mensuales: (Ingresos) vs (Costo Ventas + Operativo). |
| **2. Métodos de Pago** | Client App | Gráfico pastel de `payment_method_selected`. |

### G. GEOGRAPHY INTELLIGENCE (Geo)

#### KPIs Geográficos
| KPI / Métrica | App Responsable | Estrategia de Recolección | Tipo de Envío | Detalles Técnicos |
| :--- | :--- | :--- | :--- | :--- |
| **Ciudades Activas** | Backend | Direcciones de entrega únicas. | **N/A** | - |
| **Market Penetration** | Backend | Comparación vs Censo/Hogares. | **N/A** | - |
| **Top Zone Profitability** | Backend | Margen por Zona Geo. | **N/A** | - |
| **Expansión** | Admin | Input manual de planes. | **N/A** | - |

#### Mapa Interactivo
| Visualización | Fuente de Datos | Lógica de Construcción |
| :--- | :--- | :--- |
| **Mapa Calor Demanda** | Client App | **Evento:** `geo_activity`.<br>**Lógica:** Muestrear ubicación al abrir app. Agrupar por hexágonos (H3 index) para mapa de calor. |
| **Mapa Calor Margen** | Backend | Promedio de margen de pedidos agrupados por zona de entrega. |
| **Mapa Densidad Riders** | Rider App | Últimas ubicaciones conocidas de riders activos. |

### H. USERS & RESTAURANTS (Gestión - Partner App)

#### Funcionalidades & Tabla Datos
| Elemento | App Responsable | Estrategia de Recolección | Detalles Técnicos |
| :--- | :--- | :--- | :--- |
| **Vistas/Buscador** | Admin Web | Frontend Web. | Consultas API con filtros. |
| **Creación Usuarios** | Admin Web | Formulario Web. | API endpoint `POST /users`. |
| **Tabla Usuarios/Rest** | Backend | Base de datos SQL. | `SELECT * FROM users JOIN restaurants ...`. |

### I. CONTENT & PRODUCT GOVERNANCE

#### Funcionalidades & Tabla Productos
| Elemento | App Responsable | Estrategia de Recolección | Detalles Técnicos |
| :--- | :--- | :--- | :--- |
| **Filtros/Export** | Admin Web | Frontend Web. | Generación de CSV desde JSON response. |
| **Nuevo Plato** | Partner App | Formulario App. | **Evento:** `product_create`. |
| **Tabla Productos** | Backend | Base de datos SQL. | `SELECT * FROM products`. |

### J. DISH REQUESTS (Moderación)

#### Vistas Agrupada & Detallada
| Elemento | App Responsable | Estrategia de Recolección | Detalles Técnicos |
| :--- | :--- | :--- | :--- |
| **Solicitud Plato** | Partner App | Envío de formulario nuevo plato. | **REAL-TIME** | **Evento:** `dish_request_submitted`.<br>**Params:** `restaurant_id`. |
| **Aprobación/Rechazo** | Admin Web | Acción del moderador. | **N/A** | Trigger en backend notifica a Partner App. |

### K. RESTAURANT REQUESTS (Onboarding)

#### Tarjetas & Modal Documentación
| Elemento | App Responsable | Estrategia de Recolección | Detalles Técnicos |
| :--- | :--- | :--- | :--- |
| **Solicitud Registro** | Web/Landing | Formulario de interesado. | **REAL-TIME** | **Backend:** Crea registro "Lead". |
| **Docs Upload** | Partner App | Subida de documentos legales. | **REAL-TIME** | **Evento:** `onboarding_doc_upload`.<br>**Params:** `doc_type` (ruc, cedula). |
| **Verificación Docs** | Admin Web | Acción manual moderador. | **N/A** | Actualiza estado de documento en DB. |

---

## 3. FORMATO DE DATOS Y PROTOCOLO

### Estructura del Evento (JSON Interno en CoreData)
```json
{
  "e": "menu_session_end",       // Event Name (Minimizado)
  "t": 1715432000,               // Timestamp (Unix)
  "u": "user_123",               // User ID (Anónimo si no logueado)
  "p": {                         // Parameters
    "dur": 45,                   // Duration seconds
    "rest_id": "r_99",
    "items": ["i_1", "i_2"],
    "cart": true
  }
}
```

### Protocolo de Compresión
1.  **Serialización:** Array de eventos -> JSON String.
2.  **Compresión:** JSON String -> GZIP Data (Nivel de compresión: Best).
3.  **Envío:** HTTP POST a Cloud Function `ingestAnalytics`.
    *   Header: `Content-Encoding: gzip`
    *   Header: `X-App-Source: client-ios` (o `rider-ios`, `partner-ios`)

## 4. CONSIDERACIONES DE SEGURIDAD
*   **Privacidad:** Nunca recolectar datos PII (Email, Teléfono) en los logs de analítica. Usar User IDs opacos.
*   **Ubicación:** En Client App, solo recolectar GeoHash (zona aproximada) para analítica. Coordenadas exactas solo se usan para el delivery activo y no se guardan en logs históricos de analítica de usuario.
*   **Rider Tracking:** Los datos de ubicación de riders son sensibles. Se transmiten encriptados y el acceso histórico está restringido a Operaciones y Seguridad.
