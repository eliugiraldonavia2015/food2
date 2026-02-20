# Metodología de Desarrollo Paralelo: Mock vs Real Data

## Objetivo
Permitir el desarrollo continuo de la infraestructura real (Backend, APIs, Base de Datos) sin afectar la estabilidad de la versión de demostración para inversores.

## Estrategia de Bifurcación (Branching Strategy)
Se implementará una lógica de "Feature Flag" basada en el usuario autenticado.

### 1. Identificación del Usuario "Demo"
*   **Usuario Clave:** `eliugiraldonavia2015@gmail.com`
*   **Mecanismo:** Al iniciar sesión (`AuthService`), se verificará si el email coincide con el usuario clave.
*   **Persistencia:** El resultado se almacenará en una propiedad global de solo lectura (ej. `AuthService.shared.isMockUser`).

### 2. Comportamiento del Sistema

| Componente | Usuario Demo (Eliu) | Usuario Real / Tester |
| :--- | :--- | :--- |
| **Feed / Discovery** | Carga datos estáticos (hardcoded) desde arrays locales. | Intenta cargar desde API/Firestore. |
| **Menús** | Muestra menú de ejemplo "Green Burger". | Consulta colección `restaurants/{id}/menu`. |
| **Perfil** | Perfil estático con fotos de Unsplash. | Perfil real del usuario logueado. |
| **Carrito** | Local en memoria (se borra al salir). | Sincronizado con servidor (futuro). |

### 3. Reglas de Implementación
1.  **NO eliminar código hardcoded:** El código hardcoded actual se encapsulará, no se borrará.
2.  **Inyección de Dependencias:** Los ViewModels no deben tener `if (email == ...)` dispersos. Deben consultar una bandera centralizada.
3.  **Prioridad de Estabilidad:** Si el backend falla, el usuario Demo NO debe enterarse. Su flujo es 100% local.

## Pasos de Transición (Desmocking)
A medida que se construyen los endpoints reales:
1.  Crear el servicio real (ej. `RealFeedService`).
2.  En el punto de inyección, usar:
    ```swift
    let feedService: FeedServiceProtocol = AuthService.shared.isMockUser 
        ? MockFeedService() 
        : RealFeedService()
    ```
3.  Verificar que el usuario Demo sigue viendo lo mismo, mientras que otros usuarios ven los datos reales (o errores de conexión si aún no está listo).
