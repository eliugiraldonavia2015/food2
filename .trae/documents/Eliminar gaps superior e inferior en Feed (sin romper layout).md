## Objetivo
Eliminar el gap superior bajo el status bar y el gap inferior entre la imagen y el tab bar, y bajar la columna izquierda para que quede más cerca del tab bar, manteniendo el paginado continuo y sin romper el layout.

## Cambios propuestos
- Hacer que cada página del `VerticalPager` ocupe el alto completo de la pantalla incluyendo las safe areas superior e inferior.
  - Aplicar `ignoresSafeArea(.container, edges: .vertical)` directamente al `VerticalPager` para que su `UIScrollView` se mida por toda la pantalla, no solo el área segura.
  - Archivo: `food/Sources/Views/FeedView.swift` cerca de `VerticalPager(... )` en `food/Sources/Views/FeedView.swift:160-165`.
- Mantener el fondo de cada página exactamente del tamaño del contenedor de página (sin offsets manuales) para no romper el paginado.
  - `WebImage` con `frame(width: pageGeo.size.width, height: pageGeo.size.height)` y `scaledToFill().clipped()`.
  - Archivo: `food/Sources/Views/FeedView.swift:165-172`.
- Bajar la columna de overlay para reducir el espacio con el tab bar.
  - Usar `padding(.bottom, bottomInset + 4)` en el overlay.
  - Archivo: `food/Sources/Views/FeedView.swift:325-327`.
- Conservar el paginado nativo y sin rebote.
  - Ya activo: `food/Sources/Views/VerticalPager.swift:13-14` (`alwaysBounceVertical = false`, `isPagingEnabled = true`).
- Mantener oculta la `navigationBar` del sistema para evitar solapamiento.
  - Ya activo: `food/Sources/Views/MainTabView.swift:55`.

## Verificación
- Deslizar el feed: sin gaps negros entre páginas.
- Revisar borde superior: la imagen cubre bajo el status bar.
- Revisar borde inferior: la imagen llega hasta el tab bar, sin rectángulo negro arriba del tab bar.
- Confirmar que el botón “Ordenar Ahora” y la columna quedan más cerca del tab bar y no quedan por detrás.
- Cambiar entre “Siguiendo” y “Para Ti”: el centrado y fondo se mantienen.

## Notas
- Esta solución usa el tamaño completo del `VerticalPager` para evitar offsets manuales que rompan el paginado.
- El `bottomInset` sigue controlando la separación segura respecto al tab bar; el ajuste a `+4` acerca la columna sin riesgo de solape.