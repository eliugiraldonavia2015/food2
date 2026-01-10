import SwiftUI

public struct UploadStatusOverlay: View {
    @ObservedObject var manager = UploadManager.shared
    @State private var offset: CGFloat = 0
    @State private var isHiddenTemporarily = false
    
    public init() {}
    
    public var body: some View {
        if (manager.isProcessing || manager.isCompleted) && !isHiddenTemporarily {
            VStack {
                HStack(spacing: 12) {
                    // Icono de estado
                    ZStack {
                        if manager.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 24))
                                .transition(.scale.combined(with: .opacity))
                        } else if let _ = manager.error {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 24))
                        } else {
                            // Spinner de progreso
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                                Circle()
                                    .trim(from: 0, to: manager.progress)
                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.2), value: manager.progress)
                            }
                            .frame(width: 24, height: 24)
                        }
                    }
                    
                    // Texto de estado
                    VStack(alignment: .leading, spacing: 2) {
                        Text(manager.error != nil ? "Error al subir" : (manager.isCompleted ? "¡Publicado!" : manager.statusMessage))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        if !manager.isCompleted && manager.error == nil {
                            Text("\(Int(manager.progress * 100))%")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Botón de cerrar (solo si hay error o completado)
                    if manager.isCompleted || manager.error != nil {
                        Button(action: {
                            withAnimation {
                                manager.isProcessing = false
                                manager.isCompleted = false
                                manager.error = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                // Gesto de Swipe Up para ocultar temporalmente
                .offset(y: offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gesture.translation.height < 0 {
                                offset = gesture.translation.height
                            }
                        }
                        .onEnded { gesture in
                            if gesture.translation.height < -20 {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isHiddenTemporarily = true
                                    offset = 0
                                }
                            } else {
                                withAnimation {
                                    offset = 0
                                }
                            }
                        }
                )
            }
            .padding(.horizontal)
            .padding(.top, 8) // Espacio seguro superior
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: manager.isProcessing)
            .onChange(of: manager.isCompleted) { completed in
                if completed && isHiddenTemporarily {
                    // Si estaba oculto y terminó, mostrar de nuevo para feedback
                    withAnimation {
                        isHiddenTemporarily = false
                    }
                    // Programar notificación local (simulada)
                    scheduleLocalNotification()
                }
            }
        }
    }
    
    private func scheduleLocalNotification() {
        // En una app real usaríamos UserNotifications
        // Aquí solo aseguramos que el usuario vea el check verde
        print("🔔 Notificación: Tu video se ha subido correctamente")
    }
}
