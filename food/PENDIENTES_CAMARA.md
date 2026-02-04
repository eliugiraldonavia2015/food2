# 📸 PENDIENTES DE CÁMARA Y SUBIDA (FoodTook)

**Última actualización:** 2026-02-04
**Ubicación Principal:** `Sources/Views/UploadVideoView.swift`

Este documento detalla el estado actual de la implementación de la cámara estilo TikTok y la subida de videos, así como los pasos necesarios para finalizarla.

---

## ✅ LO QUE YA ESTÁ HECHO (Funcional)

### 1. Interfaz de Usuario (UI)
*   [x] **Diseño estilo TikTok:** Pantalla completa, controles superpuestos y limpios.
*   [x] **Controles Laterales:** Botones de "Girar", "Velocidad", "Filtros", "Embellecer", "Flash" (solo UI implementada).
*   [x] **Selector de Modos:** "Grams" (Video), "Producto" (Foto), "Live" (Streaming).
*   [x] **Botón de Grabación Inteligente:**
    *   Muestra estado de grabación (rojo animado).
    *   Muestra botón de **Pausar** al grabar.
    *   Muestra botón de **Siguiente/Check** al pausar para finalizar.
*   [x] **Estabilidad Visual:** Los controles no "saltan" ni desaparecen bruscamente al grabar; se mantienen o se ocultan suavemente.

### 2. Lógica de Cámara (`CameraModel`)
*   [x] **Inicialización Optimizada:** La sesión de cámara (`AVCaptureSession`) se carga en un hilo secundario (`DispatchQueue`) para que la pantalla abra **instantáneamente** sin congelar la app.
*   [x] **Grabación Real por Segmentos:**
    *   Usa `AVCaptureMovieFileOutput`.
    *   Permite grabar -> pausar -> grabar otro clip.
    *   Los clips se guardan como archivos temporales `.mov`.
*   [x] **Fusión de Videos:** Al finalizar, todos los segmentos grabados se unen (`mergeSegments`) en un solo archivo de video usando `AVMutableComposition`.

### 3. Flujo de Revisión y Publicación
*   [x] **Modo Revisión:** Al terminar de grabar, la cámara se oculta y se reproduce el video resultante en bucle (`AVPlayerLooper`) para que el usuario lo vea.
*   [x] **Metadatos:** Al dar "Siguiente", se navega a `PostMetadataView` para añadir título, descripción y subir a Bunny.net.
*   [x] **Permisos:** Se agregaron las claves `NSCameraUsageDescription` y `NSMicrophoneUsageDescription` al `Info.plist` para evitar crashes.

---

## 📋 PENDIENTES PARA RETOMAR (TODO List)

### 1. ⚠️ Actualización de APIs Obsoletas (iOS 16+)
Actualmente el código compila y funciona, pero usa APIs síncronas de `AVFoundation` que están marcadas como `deprecated` en iOS 16+.
*   **Archivos:** `UploadVideoView.swift`, `VideoCompressor.swift`.
*   **Tarea:** Migrar propiedades como `.duration`, `.tracks`, `.preferredTransform` a sus versiones asíncronas `try await load(...)`.
    *   *Ejemplo:* Cambiar `asset.duration` por `try await asset.load(.duration)`.

### 2. 🛠 Funcionalidad Real de Herramientas
Los botones laterales son visuales pero no tienen lógica profunda aún:
*   **Velocidad:** Implementar cambio de `Scale` en la composición de video.
*   **Filtros/Embellecer:** Requiere integración con `CoreImage` o `Metal` para procesamiento en tiempo real.
*   **Flash:** La lógica básica está, pero verificar comportamiento en todos los dispositivos.

### 3. 🔐 Seguridad de API Key
*   **Problema:** La API Key de Bunny.net (`b88d...`) está hardcodeada en `UploadManager.swift` para que funcione rápido.
*   **Solución:** Mover esta clave a una variable de entorno segura, Remote Config (Firebase) o un archivo de configuración no incluido en el repositorio (git-ignored).

### 4. 📱 Navegación (Deprecación)
*   Se usa `NavigationLink(isActive:...)` que está deprecado en iOS 16.
*   **Tarea:** Migrar a `NavigationStack` y `.navigationDestination(isPresented:...)` cuando se decida modernizar la navegación global.

### 5. 🧪 Pruebas de Estrés
*   Probar grabación de muchos segmentos cortos (ej: 20 clips de 1 segundo).
*   Verificar sincronización de audio/video en el archivo fusionado final.
*   Probar orientación del video (Vertical/Horizontal) al subir.

---

## 📂 Archivos Clave
*   `Sources/Views/UploadVideoView.swift`: Vista principal de cámara y lógica `CameraModel`.
*   `Sources/Views/PostMetadataView.swift`: Pantalla de detalles y subida.
*   `Sources/Services/UploadManager.swift`: Lógica de subida a Bunny.net.
