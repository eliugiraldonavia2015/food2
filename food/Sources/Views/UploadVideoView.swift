import SwiftUI
import AVFoundation
import Combine

/*
 ====================================================================================================
 🚧 ESTADO ACTUAL: IMPLEMENTACIÓN DE CÁMARA Y SUBIDA (PENDIENTE) 🚧
 ====================================================================================================
 
 FECHA ÚLTIMA MODIFICACIÓN: 2026-02-06 (Update)
 
 LO QUE SE HIZO:
 1. UI estilo TikTok implementada:
    - Vista previa de cámara full screen.
    - Controles laterales (Girar, Velocidad, Filtros, etc. - Solo UI por ahora).
    - Selector de modos inferior (Grams, Producto, Live).
    - Botón de grabación con animación y estados (Grabar, Pausar, Reanudar, Finalizar).
 
 2. Lógica de Grabación (CameraModel):
    - Uso de `AVCaptureMovieFileOutput` para grabación real.
    - Soporte para MÚLTIPLES SEGMENTOS: Se puede grabar, pausar, grabar otro clip, y al final se unen.
    - Fusión de segmentos (`mergeSegments`) usando `AVMutableComposition` para crear un solo archivo .mov.
    - Optimización "Lazy Loading": La sesión de cámara se inicia en background para evitar bloquear la UI al abrir.
 
 3. Flujo de Usuario:
    - MainTabView (+) -> UploadVideoView (Cámara).
    - Grabar -> Pausar -> Check (Siguiente).
    - Vista de Revisión (Loop automático del video unido).
    - "Siguiente" -> PostMetadataView (Título, Descripción, Upload real a Bunny).
 
 4. Correcciones Críticas:
    - Se agregaron permisos en Info.plist (Cámara, Micrófono).
    - Se corrigieron crashes por unwrapping de sesión nil.
    - Se solucionó el layout visual al grabar (controles no desaparecen bruscamente).
 
 ====================================================================================================
 📋 LISTA DE PENDIENTES PARA RETOMAR (TODO):
 ====================================================================================================
 
 1. ⚠️ ACTUALIZACIÓN DE APIs DEPRECATED (iOS 16+):
    - `AVAsset.duration`, `tracks`, `preferredTransform` son síncronas y están depreciadas.
    - Se deben migrar a `try await asset.load(.duration)`, `loadTracks(...)`, etc.
    - Esto genera warnings actualmente pero funciona.
 
 2. ⚠️ NAVIGATION LINK:
    - `NavigationLink(isActive:...)` está depreciado. Migrar a `navigationDestination` o mantener si se soporta iOS 15.
 
 3. 🛠 FUNCIONALIDAD DE HERRAMIENTAS:
    - Los botones "Velocidad", "Filtros", "Embellecer", "Tiempo" son solo visuales.
    - Falta implementar la lógica real de filtros (posiblemente usando CIFilter / Metal).
 
 4. 🔐 SEGURIDAD:
    - La API Key de Bunny.net está hardcodeada en `UploadManager.swift` ("b88d...").
    - MOVER a una configuración segura (Remote Config, Info.plist ofuscado, o backend proxy).
 
 5. 🧪 PRUEBAS:
    - Verificar la fusión de audio/video en dispositivos reales (orientación correcta).
    - Probar gestión de memoria al grabar clips muy largos.
 
 ====================================================================================================
 */

struct UploadVideoView: View {
    var onClose: () -> Void
    
    // MARK: - Camera State
    @StateObject private var cameraModel = CameraModel()
    
    // MARK: - UI State
    @State private var selectedMode: CameraMode = .grams
    @State private var showPostMetadata = false
    @State private var isReviewing = false // Nueva variable para modo revisión
    @State private var showDiscardAlert = false // Alerta para descartar grabación
    @State private var timerOption: TimerOption = .off
    @State private var currentCountdown: Int? = nil
    
    // Constants
    private let modes: [CameraMode] = [.grams, .product, .live]
    
    enum TimerOption: Int, CaseIterable {
        case off = 0
        case s3 = 3
        case s7 = 7
        case s15 = 15
    }
    
    enum CameraMode: String, CaseIterable {
        case grams = "Grams"
        case product = "Producto"
        case live = "Live"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 1. Video Content (Camera or Loop Review)
                ZStack {
                    if isReviewing, let url = cameraModel.mergedVideoURL {
                        LoopingPlayerView(videoURL: url)
                            .ignoresSafeArea()
                    } else if let session = cameraModel.session {
                        CameraPreviewView(session: session)
                            .ignoresSafeArea()
                            .onTapGesture(count: 2) {
                                cameraModel.switchCamera()
                            }
                    } else {
                        // Loading State
                        Color.black.ignoresSafeArea()
                    }
                }
                
                // 2. Overlays
                if !isReviewing {
                    VStack {
                        topControls
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        rightSideBar
                            .padding(.trailing, 16)
                            .padding(.top, 100)
                    }
                } else {
                    // Controls for Review Mode
                    VStack {
                        HStack {
                            Button(action: {
                                // Resume Recording (keep segments)
                                isReviewing = false
                                cameraModel.mergedVideoURL = nil // Clear preview, keep segments
                                cameraModel.startSession() // Re-start camera session
                            }) {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                VStack {
                    Spacer()
                    bottomControls
                }
                
                // Navigation Link (Hidden)
                NavigationLink(isActive: $showPostMetadata) {
                    PostMetadataView(videoURL: cameraModel.mergedVideoURL, onClose: onClose)
                } label: { EmptyView() }
                
                // Countdown Overlay
                if let count = currentCountdown {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        Text("\(count)")
                            .font(.system(size: 150, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                            .transition(.scale.combined(with: .opacity))
                            .id(count) // Forces transition animation
                    }
                    .zIndex(200)
                }
                
                // Custom Discard Alert Overlay
                if showDiscardAlert {
                    ZStack {
                        // Dimmed Background
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                withAnimation(.spring()) { showDiscardAlert = false }
                            }
                        
                        // Dialog Card
                        VStack(spacing: 24) {
                            VStack(spacing: 12) {
                                Text("¿Empezar de nuevo?")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Si cancelas ahora, se eliminarán los clips grabados y volverás al inicio.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(.spring()) { showDiscardAlert = false }
                                }) {
                                    Text("Seguir grabando")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        showDiscardAlert = false
                                        cameraModel.resetSegments()
                                    }
                                }) {
                                    Text("Descartar")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.red)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        )
                        .frame(width: 320)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                    .zIndex(100)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            cameraModel.checkPermissions()
        }
    }
    
    // MARK: - Top Controls
    private var topControls: some View {
        HStack(alignment: .top) {
            Button(action: {
                if cameraModel.recordingDuration > 0 {
                    showDiscardAlert = true
                } else {
                    onClose()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
            }
            
            Spacer()
            
            // Timer Indicator
            VStack(spacing: 4) {
                Text(formatDuration(cameraModel.recordingDuration))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                
                if !cameraModel.isRecording && cameraModel.recordingDuration == 0 {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "music.note")
                                .font(.system(size: 14))
                            Text("Añadir sonido")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            // Placeholder to balance X button
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 10)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Right Sidebar
    private var rightSideBar: some View {
        VStack(spacing: 20) {
            // Flip Camera
            sideBarButton(icon: "arrow.triangle.2.circlepath", text: "Girar") {
                cameraModel.switchCamera()
            }
            
            // Timer Button
            sideBarButton(
                icon: timerOption == .off ? "timer" : "timer.circle.fill",
                text: timerOption == .off ? "Tiempo" : "\(timerOption.rawValue)s"
            ) {
                let all = TimerOption.allCases
                if let index = all.firstIndex(of: timerOption) {
                    timerOption = all[(index + 1) % all.count]
                }
            }
            
            // Flash Button
            sideBarButton(icon: cameraModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill", text: "Flash") {
                cameraModel.toggleFlash()
            }
        }
    }
    
    private func sideBarButton(icon: String, text: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 28)) // Larger icons
                    .shadow(radius: 2)
                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: 10, weight: .medium))
                        .shadow(radius: 2)
                }
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Mode Selector
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(modes, id: \.self) { mode in
                            Button(action: {
                                withAnimation { selectedMode = mode }
                            }) {
                                Text(mode.rawValue)
                                    .font(.system(size: 15, weight: selectedMode == mode ? .bold : .semibold))
                                    .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                                    .background(
                                        selectedMode == mode ? Color.black.opacity(0.3) : Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                            .id(mode)
                        }
                    }
                    .padding(.horizontal, UIScreen.main.bounds.width / 2 - 40)
                }
                .onChange(of: selectedMode) { _, newMode in
                    withAnimation { proxy.scrollTo(newMode, anchor: .center) }
                }
                .onAppear {
                    proxy.scrollTo(selectedMode, anchor: .center)
                }
            }
            .frame(height: 40)
            .disabled(cameraModel.isRecording || isReviewing)
            
            // Shutter Area
            HStack(spacing: 40) {
                if isReviewing {
                    // Review Mode: "Siguiente" Button
                    Spacer()
                    Button(action: {
                        showPostMetadata = true
                    }) {
                        Text("Siguiente")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .padding(.trailing, 20)
                } else {
                    // Recording/Idle Mode
                    
                    // Left Button (Gallery)
                    Button(action: {}) {
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                            Text("Cargar")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .opacity(cameraModel.isRecording ? 0 : 1) // Ocultar solo si está grabando activamente
                    
                    // Shutter Button
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        // Inner Circle (Animates)
                        Circle()
                            .fill(selectedMode == .grams ? Color.red : (selectedMode == .product ? Color.blue : Color.white))
                            .frame(width: cameraModel.isRecording ? 40 : 70, height: cameraModel.isRecording ? 40 : 70)
                            .cornerRadius(cameraModel.isRecording ? 10 : 35)
                    }
                    .onTapGesture {
                        if selectedMode == .grams {
                            handleRecording()
                        } else {
                            simulateCapture()
                        }
                    }
                    
                    // Right Button: Effects (Idle) / Next (Paused with segments)
                    if !cameraModel.isRecording && cameraModel.recordingDuration > 0 {
                        // NEXT BUTTON (Checkmark) - Only appears if we have recorded something and are paused
                        Button(action: {
                            finishRecordingSession()
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                    .background(Circle().fill(Color.white))
                            }
                        }
                    } else if !cameraModel.isRecording {
                        // EFFECTS BUTTON (Idle / No segments)
                        Button(action: {}) {
                           VStack(spacing: 2) {
                               Image(systemName: "face.smiling")
                                   .font(.system(size: 32))
                                   .foregroundColor(.white)
                               Text("Efectos")
                                   .font(.system(size: 10, weight: .medium))
                                   .foregroundColor(.white)
                           }
                       }
                    } else {
                        // Recording: Show nothing or placeholder to keep layout balanced
                        Color.clear.frame(width: 40, height: 40)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Logic
    
    private func calculateModeOffset() -> CGFloat {
        guard let index = modes.firstIndex(of: selectedMode) else { return 0 }
        let itemWidth: CGFloat = 80
        let centerIndex = CGFloat(modes.count - 1) / 2.0
        return (centerIndex - CGFloat(index)) * itemWidth
    }
    
    private func handleRecording() {
        if cameraModel.isRecording {
            // User tapped "Record" button while recording -> PAUSE
            cameraModel.pauseRecording()
        } else {
            // Start Logic
            if timerOption != .off && cameraModel.recordingDuration == 0 {
                // Start Countdown only for the first segment (or always? usually always if timer is on)
                // TikTok timer usually applies to the START of a segment.
                startCountdown()
            } else {
                cameraModel.startRecording()
            }
        }
    }
    
    private func startCountdown() {
        currentCountdown = timerOption.rawValue
        
        func tick() {
            guard let count = currentCountdown, count > 0 else {
                // Finish
                withAnimation { currentCountdown = nil }
                cameraModel.startRecording()
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.spring()) {
                    currentCountdown = count - 1
                }
                tick()
            }
        }
        
        // Initial tick trigger
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.spring()) {
                if let c = currentCountdown { currentCountdown = c - 1 }
            }
            tick()
        }
    }
    
    private func finishRecordingSession() {
        if cameraModel.isRecording {
            cameraModel.pauseRecording()
        }
        
        // Merge and Review
        cameraModel.mergeSegments { url in
            DispatchQueue.main.async {
                if url != nil {
                    self.isReviewing = true
                    self.cameraModel.stopSession() // Stop camera to save energy
                }
            }
        }
    }
    
    private func simulateCapture() {
        // Flash animation
        withAnimation { cameraModel.isRecording = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation { cameraModel.isRecording = false }
            self.showPostMetadata = true
            self.cameraModel.stopSession() // Stop session when moving to metadata
        }
    }
}

// MARK: - Looping Player View
struct LoopingPlayerView: UIViewRepresentable {
    let videoURL: URL
    
    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(frame: .zero, url: videoURL)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    class PlayerUIView: UIView {
        private let playerLayer = AVPlayerLayer()
        private var playerLooper: AVPlayerLooper?
        
        init(frame: CGRect, url: URL) {
            super.init(frame: frame)
            
            let playerItem = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer(playerItem: playerItem)
            playerLayer.player = queuePlayer
            playerLayer.videoGravity = .resizeAspectFill
            
            playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            
            layer.addSublayer(playerLayer)
            queuePlayer.play()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}

// MARK: - Camera Model (Real Recording Implementation)
class CameraModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var session: AVCaptureSession? // Optional now
    @Published var isRecording = false
    @Published var alert = false
    @Published var mergedVideoURL: URL?
    @Published var recordingDuration: TimeInterval = 0
    @Published var isFlashOn = false
    
    // Internal
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var movieOutput: AVCaptureMovieFileOutput?
    
    private var recordedSegments: [URL] = []
    private var isFrontCamera = false
    
    // Timer Logic
    private var accumulatedTime: TimeInterval = 0
    private var recordingStartTime: Date?
    private var timer: Timer?
    
    override init() {
        super.init()
        // No heavy lifting here
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setup()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status { self.setup() }
            }
        case .denied: self.alert = true
        default: return
        }
    }
    
    func setup() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Lazy init session and output
            let session = AVCaptureSession()
            let movieOutput = AVCaptureMovieFileOutput()
            
            session.beginConfiguration()
            
            // Camera Input
            if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                do {
                    let input = try AVCaptureDeviceInput(device: camera)
                    if session.canAddInput(input) { session.addInput(input) }
                    self.videoInput = input
                    
                    // Force orientation on connection if possible
                    // Note: Video orientation is usually set on Output connection, not Input
                } catch { print(error) }
            }
            
            // Audio Input
            if let audio = AVCaptureDevice.default(for: .audio) {
                do {
                    let input = try AVCaptureDeviceInput(device: audio)
                    if session.canAddInput(input) { session.addInput(input) }
                    self.audioInput = input
                } catch { print(error) }
            }
            
            // Output
            if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
            self.movieOutput = movieOutput
            
            session.commitConfiguration()
            session.startRunning()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.session = session
            }
        }
    }
    
    func startSession() {
        if let session = session, !session.isRunning {
            DispatchQueue.global(qos: .background).async { session.startRunning() }
        }
    }
    
    func stopSession() {
        if let session = session, session.isRunning {
            DispatchQueue.global(qos: .background).async { session.stopRunning() }
        }
    }
    
    func startRecording() {
        guard let movieOutput = movieOutput else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
        
        // Start Timer
        recordingStartTime = Date()
        startTimer()
        
        DispatchQueue.main.async { self.isRecording = true }
    }
    
    func pauseRecording() {
        movieOutput?.stopRecording() // Stops current segment
        
        // Stop Timer
        stopTimer()
        
        DispatchQueue.main.async { self.isRecording = false }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            let currentSegmentDuration = Date().timeIntervalSince(startTime)
            DispatchQueue.main.async {
                self.recordingDuration = self.accumulatedTime + currentSegmentDuration
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func resetSegments() {
        recordedSegments.removeAll()
        mergedVideoURL = nil
        accumulatedTime = 0
        recordingDuration = 0
    }
    
    func switchCamera() {
        guard let session = session else { return }
        
        session.beginConfiguration()
        if let input = videoInput { session.removeInput(input) }
        
        isFrontCamera.toggle()
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        
        if let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            do {
                let input = try AVCaptureDeviceInput(device: newCamera)
                if session.canAddInput(input) { 
                    session.addInput(input)
                    self.videoInput = input
                }
            } catch { print("Error switching camera") }
        }
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        guard let device = videoInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            DispatchQueue.main.async {
                self.isFlashOn = device.torchMode == .on
            }
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error)")
        }
    }
    
    // MARK: - Delegate
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording: \(error.localizedDescription)")
            return
        }
        print("Segment recorded: \(outputFileURL)")
        recordedSegments.append(outputFileURL)
        
        // Update precise time
        if let startTime = recordingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            accumulatedTime += duration
            DispatchQueue.main.async {
                self.recordingDuration = self.accumulatedTime
            }
        }
        recordingStartTime = nil
    }
    
    // MARK: - Merge Logic
    func mergeSegments(completion: @escaping (URL?) -> Void) {
        guard !recordedSegments.isEmpty else {
            completion(nil)
            return
        }
        
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var currentTime = CMTime.zero
        
        for url in recordedSegments {
            let asset = AVAsset(url: url)
            do {
                let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                
                if let assetVideoTrack = asset.tracks(withMediaType: .video).first {
                    try videoTrack?.insertTimeRange(timeRange, of: assetVideoTrack, at: currentTime)
                    // Fix orientation if needed (ensure portrait)
                    let t = assetVideoTrack.preferredTransform
                    // Check if it's portrait (90 or -90 degrees)
                    if (t.a == 0 && t.d == 0 && (t.b == 1.0 || t.b == -1.0) && (t.c == -1.0 || t.c == 1.0)) {
                         videoTrack?.preferredTransform = t
                    } else {
                         // Default to portrait if undefined or landscape
                         videoTrack?.preferredTransform = t
                    }
                }
                
                if let assetAudioTrack = asset.tracks(withMediaType: .audio).first {
                    try audioTrack?.insertTimeRange(timeRange, of: assetAudioTrack, at: currentTime)
                }
                
                currentTime = CMTimeAdd(currentTime, asset.duration)
            } catch {
                print("Error merging segment: \(error)")
            }
        }
        
        // Export
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("merged_\(UUID().uuidString).mov")
        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        
        exporter.exportAsynchronously {
            if exporter.status == .completed {
                print("Merge success: \(outputURL)")
                DispatchQueue.main.async {
                    self.mergedVideoURL = outputURL
                    completion(outputURL)
                }
            } else {
                print("Merge failed: \(String(describing: exporter.error))")
                completion(nil)
            }
        }
    }
}
