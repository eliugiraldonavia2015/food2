# Endpoints y Datos Pendientes (Hardcoded Data)

Este documento detalla todas las secciones de la aplicación donde actualmente se utilizan datos "quemados" (hardcoded) y que requieren ser conectados a un backend real (Firebase/Firestore) para el rol de usuario (`role=user`).

## 1. Feed Principal (Home)

### 1.1. Feed de "Siguiendo"
*   **Archivo:** `Sources/Views/FeedView.swift` (Líneas 36-40)
*   **Estado Actual:** Duplica el contenido del feed "Para Ti".
*   **Requerimiento:** Endpoint o consulta para obtener videos solo de usuarios que el usuario actual sigue.
*   **Endpoint Sugerido:** `GET /feed/following`

### 1.2. Tarjeta de Introducción (Intro Card)
*   **Archivo:** `Sources/Views/FeedView.swift` (Líneas 18-34)
*   **Estado Actual:** Datos estáticos ("¿Listo para destapar el hambre?").
*   **Requerimiento:** Configuración remota para mostrar anuncios o mensajes de bienvenida dinámicos.
*   **Endpoint Sugerido:** `GET /config/intro-card`

## 2. Discovery (Explorar Comida)

### 2.1. Historias / Updates de Restaurantes
*   **Archivo:** `Sources/Views/FoodDiscoveryView.swift` (Líneas 127-132)
*   **Estado Actual:** Lista estática (`McDonald's`, `Starbucks`, etc.).
*   **Requerimiento:** Obtener historias activas de restaurantes (similar a Instagram Stories).
*   **Endpoint Sugerido:** `GET /stories/active`

### 2.2. Banner Promocional (Hero Promo)
*   **Archivo:** `Sources/Views/FoodDiscoveryView.swift` (Líneas 419-474)
*   **Estado Actual:** Hardcoded a "Green Burger" con imagen de Unsplash.
*   **Requerimiento:** Obtener la promoción destacada del día/hora.
*   **Endpoint Sugerido:** `GET /promotions/hero`

### 2.3. Categorías
*   **Archivo:** `Sources/Models/CategoryItem.swift` (Líneas 9-27)
*   **Estado Actual:** Array estático (`Hamburguesas`, `Pizza`, etc.).
*   **Requerimiento:** Cargar categorías desde base de datos para poder administrar las imágenes y orden.
*   **Endpoint Sugerido:** `GET /categories`

### 2.4. Recomendados ("Recomendados para ti")
*   **Archivo:** `Sources/Views/FoodDiscoveryView.swift` (Líneas 68-72)
*   **Estado Actual:** Array `popularItems` estático.
*   **Requerimiento:** Algoritmo de recomendación personalizado basado en historial o populares generales.
*   **Endpoint Sugerido:** `GET /recommendations/dishes`

### 2.5. Restaurantes Destacados
*   **Archivo:** `Sources/Views/FoodDiscoveryView.swift` (Líneas 98-102)
*   **Estado Actual:** Array `featuredRestaurants` estático.
*   **Requerimiento:** Lista de restaurantes patrocinados o con mejor calificación.
*   **Endpoint Sugerido:** `GET /restaurants/featured`

### 2.6. Tendencias ("TikTok Viral")
*   **Archivo:** `Sources/Views/FoodDiscoveryView.swift` (Líneas 120-124)
*   **Estado Actual:** Array `trendingItems` estático.
*   **Requerimiento:** Platillos que son tendencia actualmente.
*   **Endpoint Sugerido:** `GET /dishes/trending`

## 3. Menú y Restaurantes

### 3.1. Menú Completo
*   **Archivo:** `Sources/Views/FullMenuView.swift` (ViewModel)
*   **Estado Actual:** Función `loadData()` crea arrays manuales de `Dish` y `Branch`.
*   **Requerimiento:** Obtener menú completo de un restaurante específico por ID.
*   **Endpoint Sugerido:** `GET /restaurants/{id}/menu`

### 3.2. Sucursales del Restaurante
*   **Archivo:** `Sources/Views/FullMenuView.swift` (Líneas 109-115)
*   **Estado Actual:** Lista fija ("CDMX", "Condesa", etc.).
*   **Requerimiento:** Obtener sucursales reales del restaurante.
*   **Endpoint Sugerido:** `GET /restaurants/{id}/branches`

### 3.3. Perfil de Usuario/Restaurante
*   **Archivo:** `Sources/Views/UserProfileView.swift`
*   **Estado Actual:** Descripción Lorem Ipsum, lógica de "Seguir" local, placeholders de medios (`HardcodedTileView`).
*   **Requerimiento:** Obtener perfil completo, bio, conteo de seguidores real y grid de medios.
*   **Endpoint Sugerido:** `GET /users/{id}/profile`

## 4. Pedidos y Checkout

### 4.1. Carrito de Compras
*   **Archivo:** `Sources/Views/CartScreenView.swift`
*   **Estado Actual:** Estado local (`@State private var cart`), se pierde al cerrar.
*   **Requerimiento:** Sincronizar carrito con servidor o persistir localmente de forma robusta.
*   **Endpoint Sugerido:** `POST /cart/sync` o `GET /cart`

### 4.2. Direcciones de Entrega
*   **Archivo:** `Sources/Views/FoodDiscoveryView.swift` (Líneas 228-247) y `DeliveryAddressSelectionView.swift`
*   **Estado Actual:** Lista estática ("Casa", "Oficina", "Novia").
*   **Requerimiento:** CRUD de direcciones del usuario.
*   **Endpoint Sugerido:** `GET /users/me/addresses`

### 4.3. Métodos de Pago
*   **Archivo:** `Sources/Views/PaymentMethodSelectionView.swift`
*   **Estado Actual:** Tarjetas visuales mockeadas.
*   **Requerimiento:** Integración con pasarela de pagos (Stripe/OpenPay) para listar métodos guardados.
*   **Endpoint Sugerido:** `GET /users/me/payment-methods`

### 4.4. Barra de Pedido Activo
*   **Archivo:** `Sources/Views/FoodDiscoveryView.swift` (Líneas 788-824)
*   **Estado Actual:** Siempre muestra "Tu pedido está en camino" si se activa la animación.
*   **Requerimiento:** Polling o Stream del estado de la orden actual.
*   **Endpoint Sugerido:** `GET /orders/active`

### 4.5. Tracking de Orden (Mapa)
*   **Archivo:** `Sources/Views/CheckoutView.swift` (Struct `OrderTrackingView`)
*   **Estado Actual:** Coordenadas fijas, temporizador simulado, chat falso.
*   **Requerimiento:** WebSocket o suscripción a Firestore para ubicación real del repartidor.
*   **Endpoint Sugerido:** `WS /orders/{id}/track`

## 5. Social y Búsqueda

### 5.1. Búsqueda de Comida
*   **Archivo:** `Sources/Views/SearchFoodView.swift`
*   **Estado Actual:** Resultados sugeridos estáticos (`suggestedItems`).
*   **Requerimiento:** Búsqueda full-text de platillos y restaurantes.
*   **Endpoint Sugerido:** `GET /search/food?q={query}`

### 5.2. Búsqueda de Usuarios
*   **Archivo:** `Sources/Views/SearchUsersView.swift`
*   **Estado Actual:** Usuarios sugeridos estáticos (`suggestedUsers`).
*   **Requerimiento:** Búsqueda de perfiles.
*   **Endpoint Sugerido:** `GET /search/users?q={query}`

### 5.3. Mensajes Directos
*   **Archivo:** `Sources/Views/MessagesView.swift`
*   **Estado Actual:** Mock de conversaciones y lógica de "bot" que responde automáticamente.
*   **Requerimiento:** Sistema de chat real (Firestore/Realtime Database).
*   **Endpoint Sugerido:** `GET /conversations` y `GET /conversations/{id}/messages`

### 5.4. Notificaciones
*   **Archivo:** `Sources/Views/NotificationsScreen.swift`
*   **Estado Actual:** Secciones y notificaciones estáticas.
*   **Requerimiento:** Centro de notificaciones real.
*   **Endpoint Sugerido:** `GET /notifications`
