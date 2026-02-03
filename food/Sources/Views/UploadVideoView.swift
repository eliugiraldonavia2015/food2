import SwiftUI
import AVFoundation

struct UploadVideoView: View {
    var onClose: () -> Void
    
    // MARK: - Camera State
    @StateObject private var cameraModel = CameraModel()
    
    // MARK: - UI State
    @State private var selectedMode: CameraMode = .grams
    @State private var showPostMetadata = false
    @State private var recordedVideoURL: URL? = nil
    
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
                
                // 1. Camera Preview
                CameraPreviewView(session: cameraModel.session)
                    .ignoresSafeArea()
                    .onTapGesture(count: 2) {
                        cameraModel.switchCamera()
                    }
                
                // 2. Overlays
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
                
                VStack {
                    Spacer()
                    bottomControls
                }
                
                // Navigation Link (Hidden)
                NavigationLink(isActive: $showPostMetadata) {
                    PostMetadataView(videoURL: recordedVideoURL, onClose: onClose)
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
    
    private func sideBarButton(icon: String, text: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                Text(text)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Mode Selector
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
                .padding(.horizontal, UIScreen.main.bounds.width / 2 - 50) // Center approx
            }
            .frame(height: 40)
            
            // Shutter Area
            HStack(spacing: 40) {
                // Gallery Button
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
                
                // Shutter Button
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(selectedMode == .grams ? Color.red : (selectedMode == .product ? Color.blue : Color.white))
                        .frame(width: cameraModel.isRecording ? 40 : 70, height: cameraModel.isRecording ? 40 : 70)
                        .cornerRadius(cameraModel.isRecording ? 10 : 35)
                }
                .onTapGesture {
                    if selectedMode == .grams {
                        handleRecording()
                    } else {
                        // Just simulate photo capture for Product/Live
                        simulateCapture()
                    }
                }
                
                // Placeholder/Effects Button (Optional)
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
                .opacity(0.0) // Hidden for symmetry or future use
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
            cameraModel.stopRecording()
            // Simulate processing delay then go to next screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // In a real app, we'd pass the file URL
                // recordedVideoURL = cameraModel.outputURL
                // For demo, we just navigate
                self.showPostMetadata = true
            }
        } else {
            cameraModel.startRecording()
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

// MARK: - Camera Model (Simplified for UI Demo)
class CameraModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var session = AVCaptureSession()
    @Published var isRecording = false
    @Published var alert = false
    @Published var outputURL: URL?
    
    // Devices
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var movieOutput = AVCaptureMovieFileOutput()
    private var photoOutput = AVCapturePhotoOutput()
    
    private var isFrontCamera = false
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setup()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status { self.setup() }
            }
        case .denied:
            self.alert = true
        default:
            return
        }
    }
    
    func setup() {
        do {
            session.beginConfiguration()
            
            // Camera Input
            if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                videoInput = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(videoInput!) { session.addInput(videoInput!) }
            }
            
            // Audio Input
            if let audio = AVCaptureDevice.default(for: .audio) {
                audioInput = try AVCaptureDeviceInput(device: audio)
                if session.canAddInput(audioInput!) { session.addInput(audioInput!) }
            }
            
            // Output
            if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            
            session.commitConfiguration()
            
            // Start Session in Background
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func startRecording() {
        // Temp URL
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(Date()).mov")
        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
    }
    
    func stopRecording() {
        movieOutput.stopRecording()
        isRecording = false
    }
    
    func switchCamera() {
        session.beginConfiguration()
        
        // Remove existing input
        if let input = videoInput {
            session.removeInput(input)
        }
        
        // Switch position
        isFrontCamera.toggle()
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        
        if let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            do {
                videoInput = try AVCaptureDeviceInput(device: newCamera)
                if session.canAddInput(videoInput!) {
                    session.addInput(videoInput!)
                }
            } catch {
                print("Error switching camera: \(error.localizedDescription)")
            }
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        // Simplified flash logic placeholder
        guard let device = videoInput?.device else { return }
        do {
            try device.lockForConfiguration()
            if device.hasTorch {
                device.torchMode = device.torchMode == .off ? .on : .off
            }
            device.unlockForConfiguration()
        } catch {
            print("Flash error")
        }
    }
    
    // Delegate
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording: \(error.localizedDescription)")
            return
        }
        print("Video recorded at: \(outputFileURL)")
        self.outputURL = outputFileURL
    }
}
