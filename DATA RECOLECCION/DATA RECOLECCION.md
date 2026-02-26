# RECOLECCIÓN DE DATOS DEL PANEL DE ADMINISTRACIÓN (ADMIN SUITE)

Este documento detalla exhaustivamente toda la información, métricas, pestañas y funcionalidades presentes en el panel de administración actual del sistema FoodTook.

## 1. ESTRUCTURA Y NAVEGACIÓN GLOBAL
- **Control de Acceso:** Exclusivo para usuarios con rol `admin`.
- **Barra Lateral (Sidebar):**
  1. **Command Center** (Centro de Mando)
  2. **Growth** (Crecimiento)
  3. **Attention & Content** (Social y Contenido)
  4. **Operations** (Operaciones y Logística)
  5. **Quality & Risk** (Calidad y Riesgo)
  6. **Financial Control** (Control Financiero)
  7. **Geography Intelligence** (Inteligencia Geográfica)
  8. **Users & Restaurants** (Gestión de Usuarios y Restaurantes)
  9. **Content & Product Governance** (Gobernanza de Productos)
  10. **Dish Requests** (Solicitudes de Platos)
  11. **Restaurant Requests** (Solicitudes de Registro)

- **Filtros Globales (Disponibles en Dashboard):**
  - Período: Últimos 30 días, Hoy, Ayer, Últimos 7 días, Este mes.
  - Ubicación: Provincias (Pichincha, Guayas, etc.), Zonas (Norte, Centro, Sur).
  - Categoría: Comida Rápida, Pizzas, Asiática, etc.
  - Tipo de Negocio: Cadena, Independiente, Dark Kitchen.
  - Modo: Total, Feed, Home, Stories.

---

## 2. DETALLE DE PESTAÑAS Y MÉTRICAS (DASHBOARD)

### A. COMMAND CENTER (Vista General)
**KPIs Ejecutivos (North Star Metrics):**
- **GMV Total:** Valor Bruto de Mercancía (Ventas totales antes de deducciones).
- **Ingresos Netos:** Revenue Real (después de comisiones y promociones).
- **Pedidos Completados:** Total de transacciones exitosas.
- **Margen de Contribución:** Ganancia unitaria post-delivery.
- **Restaurantes Activos:** Locales con actividad/ventas en el periodo.
- **Market Health Score:** Índice compuesto de salud del mercado (0-100).

**Métricas Secundarias:**
- **Orders / User:** Frecuencia de pedidos por usuario activo.
- **Cost / Order (CPO):** Costo operativo promedio por pedido.
- **View-to-Order Rate:** Tasa de conversión (Vistas de menú -> Compra).
- **% Feed Orders:** Porcentaje de pedidos originados en el Feed Social.
- **LTV / CAC Ratio:** Eficiencia de crecimiento (Valor del cliente vs Costo de adquisición).

**Visualizaciones Gráficas:**
1. **Demanda y Revenue:** Gráfico de área comparando Ingresos vs. Volumen de Pedidos.
2. **Picos de Demanda:** Gráfico de barras vertical de ventas por hora del día.
3. **Revenue Mix:** Desglose mensual apilado por fuente (Comisión, Delivery, Ads, Otros).
4. **GMV vs Margen:** Gráfico combinado (Barras GMV + Línea Margen %).
5. **Time-to-Checkout:** Tendencia de segundos promedio para completar una compra.

**Listas Top (Rankings):**
- **Restaurantes Top por GMV:** Nombre, GMV ($), Pedidos (#), Rating (Estrellas).
- **Categorías Top por Demanda:** Categoría, Pedidos, GMV, % Crecimiento.

### B. GROWTH (Crecimiento)
**Métricas de Adquisición:**
- **Nuevos Usuarios:** Total de registros.
- **Tasa de Activación (7d):** % usuarios que interactúan/compran en primera semana.
- **CAC:** Costo de Adquisición de Cliente promedio.
- **Payback CAC:** Tiempo (meses) para recuperar la inversión de adquisición.

**Métricas de Engagement:**
- **DAU:** Usuarios Activos Diarios.
- **MAU:** Usuarios Activos Mensuales.
- **Stickiness:** Ratio DAU/MAU (Adherencia).
- **Viral Coefficient (K):** Promedio de nuevos usuarios referidos por existentes.

**Métricas de Retención y Valor:**
- **LTV Cohorte:** Lifetime Value estimado del cliente.
- **LTV / CAC Ratio:** Rentabilidad del cliente.
- **Orders / User:** Frecuencia de compra.
- **Repeat Rate:** Tasa de recompra (% clientes que compran >1 vez).

**Visualizaciones Gráficas:**
1. **Crecimiento de Usuarios:** Barras (Nuevos) + Línea (Activos).
2. **Retención (Cohortes):** Curva de retención mensual (%).
3. **LTV vs CAC:** Líneas comparativas históricas.
4. **Funnel de Viralidad:** Embudo de referidos (Invitaciones -> Clics -> Instalaciones -> Registros).
5. **Embudo de Compra:** Conversión por etapas (Sesión -> Menú -> Carrito -> Checkout -> Pago).
6. **Crecimiento de Oferta:** Restaurantes Nuevos vs. Activos totales.

### C. ATTENTION & CONTENT (Social)
**KPIs Sociales Primarios:**
- **Posts Creados:** Volumen de contenido generado.
- **Conversión Social→Pedido:** % pedidos atribuidos a interacción social.
- **Avg Session Time:** Tiempo promedio en Feed & Stories.
- **Swipes per Session:** Intensidad de interacción (desplazamientos).

**Métricas de Engagement Profundo:**
- **Stories per Session:** Promedio de historias consumidas.
- **Scroll Depth:** Profundidad de navegación en el feed (%).
- **View Completion Rate:** % videos vistos hasta el final.
- **View-to-Order Rate:** Conversión directa (Vista -> Compra inmediata).

**Visualizaciones Gráficas:**
1. **Engagement Social:** Líneas múltiples (Posts, Interacciones, Pedidos Social).
2. **Embudo Social:** Conversión (Impresiones -> Clics -> Menú -> Pedido).

**Tabla Top Creadores de Contenido:**
- **Datos:** Restaurante, Vistas (Views), Pedidos Atribuidos, Tasa de Conversión, Revenue Generado, % Ventas desde Stories.

### D. OPERATIONS (Operaciones)
**KPIs Operativos y Logísticos:**
- **Tiempo Entrega Promedio:** Minutos totales (Order to Door).
- **On-Time Rate:** % cumplimiento de promesa de entrega (SLA).
- **Tiempo Asignación:** Promedio para asignar repartidor.
- **Utilización Repartidor:** % tiempo activo de la flota.

**Métricas de Eficiencia:**
- **Cost per Order:** Costo unitario operativo total.
- **Orders / km²:** Densidad de demanda geográfica.
- **Couriers / km²:** Densidad de oferta logística.
- **Motivos Cancelación:** Principal causa de pérdida de pedidos.

**Visualizaciones Gráficas:**
1. **Tiempos por Etapa:** Desglose en minutos (Aceptación, Preparación, Asignación, Recogida, Entrega).
2. **Waterfall Cost per Order:** Desglose de componentes del costo (Logística, Soporte, Transacción, Promo).
3. **Motivos de Cancelación:** Gráfico de pastel (Demora, Sin Repartidor, Cliente, Restaurante).

### E. QUALITY & RISK (Calidad y Riesgo)
**Métricas de Calidad:**
- **Precisión Pedido:** % pedidos perfectos (sin errores/faltantes).
- **Tasa de Reclamos:** Contactos a soporte por cada 100 pedidos.
- **Tasa de Reembolsos:** % ingresos devueltos a clientes.
- **NPS Cliente:** Net Promoter Score (Lealtad).

**Métricas de Riesgo y Soporte:**
- **Refund Impact:** Impacto porcentual en el margen financiero.
- **Reliability Score:** Puntuación general de confiabilidad de la flota/restaurantes.
- **Fraud Flags:** Número de alertas de fraude activas.
- **Tickets Soporte:** Volumen total de tickets semanales.

**Visualizaciones Gráficas:**
1. **Incidentes de Calidad:** Barras por tipo (Producto incorrecto, Frío, Derramado, Tardanza).
2. **Soporte Operativo:** Líneas comparativas (Tickets Creados vs. Resueltos).

**Tabla Ranking de Confiabilidad (Partners):**
- **Datos:** Restaurante, Score (0-5), Tasa de Incidentes, Tasa de Reembolsos, Estado (Excellent, Good, Warning).

### F. FINANCIAL CONTROL (Finanzas)
**KPIs Financieros:**
- **Take Rate:** Nominal vs. Efectivo (Comisión real retenida).
- **Costo Promos:** Inversión total en descuentos y cupones.
- **Costo Logístico:** Gasto total en operación de entrega.
- **Margen Neto:** Rentabilidad final después de todos los costos.

**Métricas de Salud Financiera:**
- **EBITDA Snapshot:** Beneficio operativo antes de intereses/impuestos.
- **Burn Rate:** Velocidad de consumo de capital mensual.
- **Runway:** Meses de operación restantes con caja actual.
- **ARPU:** Ingreso Promedio por Usuario.

**Visualizaciones Gráficas:**
1. **Ingresos vs Costos:** Gráfico combinado (Barras Revenue/Costo + Línea Profit).
2. **Métodos de Pago:** Distribución (Tarjeta, Efectivo, Wallet, Otros).

### G. GEOGRAPHY INTELLIGENCE (Geo)
**KPIs Geográficos:**
- **Ciudades Activas:** Número de mercados operativos.
- **Market Penetration:** % de hogares alcanzados en zonas activas.
- **Top Zone Profitability:** Zona con mayor margen de contribución.
- **Expansión (Proyección):** Nuevos mercados planificados.

**Mapa Interactivo (Ecuador):**
- Visualización por zonas/provincias.
- **Métricas seleccionables en mapa:**
  - GMV Total ($)
  - Margen de Contribución (%)
  - Densidad (Órdenes/km²)
- **Leyenda:** Alto Desempeño (Verde), Promedio (Ámbar), Atención (Rojo).

---

## 3. PANTALLAS DE GESTIÓN (OPERATIVA)

### H. USERS & RESTAURANTS (Maestro de Usuarios)
**Funcionalidades:**
- **Vistas:** Alternar entre "Restaurantes" y "Usuarios".
- **Buscador:** Por nombre o email.
- **Creación:** Botón "+ Nuevo Usuario" con modal para crear:
  - **Admin:** Requiere credenciales globales + permisos.
  - **Staff:** Roles específicos (Secretario, Ventas, Servicio al cliente, Legal, Financiero, Inversor).
  - **Restaurante:** Datos comerciales (RUC, Dueño, Dirección, Docs).

**Tabla de Datos (Columnas Dinámicas):**
- **Identidad:** Avatar, Nombre, Email, RUC/ID.
- **Rol:** Admin, Staff (Rol específico), Restaurant.
- **Financials:** GMV (para Restaurantes) o LTV (para Usuarios).
- **Performance:** Margen Contrib. (Restaurantes) o Frecuencia (Usuarios).
- **Engagement:** Conversión % (Restaurantes) o Score /100 (Usuarios).
- **Risk:** Índice de Dependencia (Restaurantes) o Flag de Riesgo (Usuarios).
- **Marketing:** Gasto Ads, % Stories (Solo Restaurantes).
- **Estado:** Activo (Verde), Baneado (Rojo), Inactivo (Gris).
- **Acciones:** Ver Platos (Restaurantes), Editar, Banear/Activar.

### I. CONTENT & PRODUCT GOVERNANCE (Catálogo)
**Funcionalidades:**
- Filtro por Restaurante específico o "Todos".
- Exportación a CSV.
- Botón "Nuevo Plato".

**Tabla de Productos:**
- **Producto:** Imagen, Nombre.
- **Precio:** Valor monetario ($).
- **Categoría:** Etiqueta (Ej. Hamburguesas, Bebidas).
- **Restaurante:** Nombre del local propietario.
- **Estado:** Disponible (Active) / No disponible.
- **Acciones:** Editar, Eliminar.

### J. DISH REQUESTS (Moderación de Platos)
**Vista Agrupada (Por Restaurante):**
- Tarjetas de restaurantes con solicitudes pendientes.
- Datos: Nombre, Cantidad de platos, Ubicación (País, Provincia), Fecha última solicitud.
- Filtros: Buscador, País, Provincia.

**Vista Detallada (Platos por Restaurante):**
- Lista de platos individuales pendientes de aprobación.
- Datos: Imagen grande, Categoría, Nombre, Precio, Descripción completa, Fecha de envío.
- **Acciones:**
  - **Aprobar:** Publica el plato inmediatamente.
  - **Rechazar:** Abre modal para ingresar motivo del rechazo (feedback al restaurante).

### K. RESTAURANT REQUESTS (Onboarding de Restaurantes)
**Funcionalidades:**
- Buscador (Nombre, Dueño, Email).
- Filtros (País, Provincia).
- Exportar CSV.

**Tarjetas de Solicitud:**
- **Cabecera:** Nombre Restaurante, ID Solicitud, Etiqueta de Estado (Pendiente, 2do intento, etc.).
- **Datos Contacto:** Propietario, Email, Teléfono.
- **Ubicación:** País, Provincia.
- **Fecha:** Fecha de envío de solicitud.
- **Acciones:**
  - **Ver Docs:** Abre modal de revisión documental.
  - **Aprobar:** Activa al restaurante.
  - **Rechazar:** Rechaza la solicitud con motivo.

**Modal de Documentación:**
- Lista de documentos requeridos (RUC, Permiso, Cédula, Menú, Banco).
- Estado por documento: Verificado (Verde), Pendiente (Gris), Vacío (Alerta).
- Vista previa de archivos (PDF/Imagen).
