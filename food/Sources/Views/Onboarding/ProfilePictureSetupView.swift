// Sources/Views/Onboarding/ProfilePictureSetupView.swift
import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth
import SDWebImageSwiftUI

struct ProfilePictureSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var selectedItem: PhotosPickerItem?
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    // URL de Google (si existe)
    private var googlePhotoURL: URL? {
        Auth.auth().currentUser?.photoURL
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Tu Perfil")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button {
                showImagePicker = true
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                        .frame(width: 160, height: 160)

                    if let image = viewModel.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    } else if let googleURL = googlePhotoURL {
                        // ✅ Mostrar foto de Google si no ha seleccionado una nueva
                        WebImage(url: googleURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(fuchsiaColor)
                            .frame(width: 64, height: 64)
                            .shadow(color: fuchsiaColor.opacity(0.25), radius: 6, x: 0, y: 3)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22, weight: .bold))
                            )
                    }
                }
            }
            .padding(.top, 8)
            .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { _, newItem in
                if let newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            // COMPRESIÓN AÑADIDA: Reducir tamaño antes de asignar
                            let compressedImage = compressImage(uiImage, maxFileSize: 1024 * 1024) // 1MB máximo
                            
                            await MainActor.run {
                                viewModel.profileImage = compressedImage
                            }
                        }
                    }
                }
            }
            HStack(spacing: 16) {
                Button {
                    showCameraPicker = true
                } label: {
                    Text("Tomar foto")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(fuchsiaColor)
                        .clipShape(Capsule())
                }
                Button {
                    showImagePicker = true
                } label: {
                    Text("Elegir de galería")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.25))
                        .overlay(Capsule().stroke(fuchsiaColor.opacity(0.25), lineWidth: 1))
                        .clipShape(Capsule())
                }
            }
            
            Button("Saltar este paso") {
                viewModel.nextStep()
            }
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.25))
            .overlay(Capsule().stroke(fuchsiaColor.opacity(0.25), lineWidth: 1))
            .clipShape(Capsule())
            .padding(.top, 12)

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Continuar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(fuchsiaColor)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: fuchsiaColor.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            
        }
        .padding()
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker { image in
                let compressedImage = compressImage(image, maxFileSize: 1024 * 1024)
                viewModel.profileImage = compressedImage
            }
        }
    }
    
    // MARK: - Función de compresión añadida
    private func compressImage(_ image: UIImage, maxFileSize: Int) -> UIImage {
        var compression: CGFloat = 0.9
        let maxCompression: CGFloat = 0.1
        let step: CGFloat = 0.1
        
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return image
        }
        
        // Reducir calidad gradualmente hasta cumplir con el tamaño máximo
        while imageData.count > maxFileSize && compression > maxCompression {
            compression -= step
            if let newData = image.jpegData(compressionQuality: compression) {
                imageData = newData
            } else {
                break
            }
        }
        
        // Si después de comprimir sigue siendo muy grande, reducir dimensiones
        if imageData.count > maxFileSize {
            let scale = sqrt(CGFloat(maxFileSize) / CGFloat(imageData.count))
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage ?? image
        }
        
        return UIImage(data: imageData) ?? image
    }
}
