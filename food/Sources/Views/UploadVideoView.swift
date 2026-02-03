import SwiftUI
import AVFoundation
import Combine

struct UploadVideoView: View {
    var onClose: () -> Void
    
    // MARK: - Camera State
    @StateObject private var cameraModel = CameraModel()
    
    // MARK: - UI State
    @State private var selectedMode: CameraMode = .grams
    @State private var showPostMetadata = false
    @State private var isPaused = false // Nueva variable para controlar pausa
    @State private var isReviewing = false // Nueva variable para modo revisión
    
    // Constants
    private let modes: [CameraMode] = [.grams, .product, .live]
    
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
                    } else {
                        CameraPreviewView(session: cameraModel.session)
                            .ignoresSafeArea()
                            .onTapGesture(count: 2) {
                                cameraModel.switchCamera()
                            }
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
                                // Retake / Cancel Review
                                isReviewing = false
                                cameraModel.resetSegments()
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
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
            }
            
            Spacer()
            
            if !cameraModel.isRecording {
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
            
            Spacer()
            
            // Placeholder to balance X button
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 10)
        .padding(.horizontal)
    }
    
    // MARK: - Right Sidebar
    private var rightSideBar: some View {
        VStack(spacing: 24) {
            // Logic for Pause/Next buttons
            if cameraModel.isRecording {
                // Recording Mode: Show Pause Button
                sideBarButton(icon: "pause.circle.fill", text: "Pausar") {
                    withAnimation {
                        cameraModel.pauseRecording()
                        isPaused = true
                    }
                }
                .foregroundColor(.red) // Highlight pause
            } else if isPaused {
                // Paused Mode: Show nothing (as per user request "al estar pausada desaparezca")
                // User must tap main button to resume.
            } else {
                // Idle Mode: Standard Options
                sideBarButton(icon: "arrow.triangle.2.circlepath", text: "Girar") {
                    cameraModel.switchCamera()
                }
                sideBarButton(icon: "speedometer", text: "Velocidad")
                sideBarButton(icon: "wand.and.stars", text: "Filtros")
                sideBarButton(icon: "face.dashed", text: "Embellecer")
                sideBarButton(icon: "timer", text: "Tiempo")
                sideBarButton(icon: "bolt.slash.fill", text: "Flash") {
                    cameraModel.toggleFlash()
                }
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
            // Mode Selector (Hidden while recording/reviewing)
            if !cameraModel.isRecording && !isReviewing && !isPaused {
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
                        }
                    }
                    .padding(.horizontal, UIScreen.main.bounds.width / 2 - 50)
                }
                .frame(height: 40)
            }
            
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
                    
                    // Left Button (Gallery) - Only visible if not recording/paused
                    if !cameraModel.isRecording && !isPaused {
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
                    } else {
                        // Spacer to keep shutter centered
                        Color.clear.frame(width: 32, height: 32)
                    }
                    
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
                    
                    // Right Button (Effects or Next if stopped)
                    if !cameraModel.isRecording && !isPaused {
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
                    } else if isPaused {
                        // When Paused, show "Check" to finish manually?
                        // User said: "si mientras grabo no toco el boton de pausa sino el boton de detener grabacion debe salirme un boton del lado derecho que diga 'siguiente'"
                        // But if paused, we also need a way to finish.
                        Button(action: {
                            finishRecordingSession()
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                                .background(Circle().fill(Color.white))
                        }
                    } else {
                        Color.clear.frame(width: 32)
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
    
    private func handleRecording() {
        if cameraModel.isRecording {
            // User tapped "Stop" while recording -> Finish and Review
            finishRecordingSession()
        } else {
            // User tapped "Record" -> Start or Resume
            cameraModel.startRecording()
            isPaused = false
        }
    }
    
    private func finishRecordingSession() {
        cameraModel.pauseRecording() // Stop current segment
        isPaused = false
        
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
    @Published var session = AVCaptureSession()
    @Published var isRecording = false
    @Published var alert = false
    @Published var mergedVideoURL: URL?
    
    // Internal
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var movieOutput = AVCaptureMovieFileOutput()
    
    private var recordedSegments: [URL] = []
    private var isFrontCamera = false
    
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
            self.session.beginConfiguration()
            
            // Camera Input
            if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                do {
                    self.videoInput = try AVCaptureDeviceInput(device: camera)
                    if self.session.canAddInput(self.videoInput!) { self.session.addInput(self.videoInput!) }
                } catch { print(error) }
            }
            
            // Audio Input
            if let audio = AVCaptureDevice.default(for: .audio) {
                do {
                    self.audioInput = try AVCaptureDeviceInput(device: audio)
                    if self.session.canAddInput(self.audioInput!) { self.session.addInput(self.audioInput!) }
                } catch { print(error) }
            }
            
            // Output
            if self.session.canAddOutput(self.movieOutput) { self.session.addOutput(self.movieOutput) }
            
            self.session.commitConfiguration()
            self.startSession()
        }
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async { self.session.startRunning() }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .background).async { self.session.stopRunning() }
        }
    }
    
    func startRecording() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
        DispatchQueue.main.async { self.isRecording = true }
    }
    
    func pauseRecording() {
        movieOutput.stopRecording() // Stops current segment
        DispatchQueue.main.async { self.isRecording = false }
    }
    
    func resetSegments() {
        recordedSegments.removeAll()
        mergedVideoURL = nil
    }
    
    func switchCamera() {
        session.beginConfiguration()
        if let input = videoInput { session.removeInput(input) }
        
        isFrontCamera.toggle()
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        
        if let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            do {
                videoInput = try AVCaptureDeviceInput(device: newCamera)
                if session.canAddInput(videoInput!) { session.addInput(videoInput!) }
            } catch { print("Error switching camera") }
        }
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        guard let device = videoInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .off ? .on : .off
            device.unlockForConfiguration()
        } catch {}
    }
    
    // MARK: - Delegate
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording: \(error.localizedDescription)")
            return
        }
        print("Segment recorded: \(outputFileURL)")
        recordedSegments.append(outputFileURL)
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
                    // Fix orientation if needed (simplified)
                    videoTrack?.preferredTransform = assetVideoTrack.preferredTransform
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
