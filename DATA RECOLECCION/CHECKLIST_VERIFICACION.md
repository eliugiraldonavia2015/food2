# CHECKLIST DE VERIFICACIÓN COMPLETA (MIRROR) ✅

Esta lista corresponde exactamente a los ítems implementados en `ESTADO_IMPLEMENTACION_ANALYTICS.md`. Úsala para validar la calidad de datos en Firebase DebugView.

---

## 1. INFRAESTRUCTURA (CORE)

- [ ] **Manager Inicializado:** Al abrir la app, el log muestra `[Analytics] 🟢 Manager Initialized`.
- [ ] **Sesión Única:** Verifica que todos los eventos de una misma sesión tengan el mismo `session_id`.
- [ ] **Persistencia Offline:**
    1. Pon el celular en Modo Avión.
    2. Navega por la app (genera eventos).
    3. Cierra la app.
    4. Abre la app con internet.
    5. Verifica que los eventos "viejos" aparezcan en Firebase (Flush).

---

## 2. IDENTIDAD Y SESIÓN

- [ ] **`identifyUser` (Login):**
    - Al iniciar sesión, busca la propiedad de usuario `user_id` en DebugView.
    - Debe coincidir con el UID de Firebase Auth.
- [ ] **`app_open`:** Aparece automáticamente al lanzar la app.
- [ ] **`app_background`:** Aparece al minimizar la app (ir al Home de iOS).
- [ ] **`app_foreground`:** Aparece al volver a abrir la app desde segundo plano.

---

## 3. PANTALLAS (SCREEN VIEWS)

Verifica que el evento `screen_view` tenga el parámetro `screen_name` correcto:

- [ ] **Feed Principal:**
    - `screen_name`: **`feed_home`**
    - Parámetro extra: `active_tab` ("foryou" o "following").
- [ ] **Dashboard Restaurante:**
    - `screen_name`: **`restaurant_dashboard`**
    - Parámetro extra: `section` (ej: "Pedidos", "Menú").
- [ ] **Carrito de Compras:**
    - `screen_name`: **`cart_screen`**
    - Parámetro extra: `restaurant` (Nombre del local).
    - Parámetro extra: `total_value` (Monto > 0).
- [ ] **Checkout (Revisar Pedido):**
    - `screen_name`: **`checkout_flow`**
    - Parámetro extra: `items_count` (Cantidad de platos).

---

## 4. EMBUDO DE VENTAS (COMMERCE)

- [ ] **`checkout_attempt`:**
    - Trigger: Clic en botón "Realizar Pedido".
    - Parámetros: `restaurant`, `payment_method` (ej: "Tarjeta").
- [ ] **`purchase` (CRÍTICO 💰):**
    - Trigger: Pantalla verde de "Pedido Recibido".
    - Parámetro: `value` (Monto total pagado).
    - Parámetro: `currency` (Debe ser "USD" o "MXN").
    - Parámetro: `transaction_id` (No debe estar vacío).
    - Parámetro: `items` (Lista de nombres de productos).

---

## 5. ENGAGEMENT & GROWTH

- [ ] **`video_view`:**
    - Trigger: Ver un video por más de **3 segundos**.
    - Parámetro: `video_id` (ID único del video).
    - Parámetro: `author_id` (ID del creador).
    - *Nota: Este evento puede tardar en aparecer (Batch).*
- [ ] **`sign_up`:**
    - Trigger: Completar registro nuevo.
    - Parámetro: `method` ("email" o "phone").

---

**Validación Final:**
Si todos los cuadros están marcados, el sistema de analítica es 100% confiable y coincide con la documentación técnica.
