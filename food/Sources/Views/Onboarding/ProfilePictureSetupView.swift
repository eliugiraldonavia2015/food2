// Sources/Views/Onboarding/ProfilePictureSetupView.swift
import SwiftUI
import PhotosUI
import UIKit

struct ProfilePictureSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Agrega una foto de perfil")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ayuda a que otros te reconozcan más fácilmente")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 📸 Imagen de perfil seleccionada o placeholder
            Button {
                showImagePicker = true
            } label: {
                Group {
                    if let image = viewModel.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 120))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 140, height: 140)
                .overlay(Circle().stroke(Color.orange, lineWidth: 2))
                .shadow(radius: 3)
            }
            .padding(.top, 10)
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
            
            // Botón continuar
            Button {
                viewModel.nextStep()
            } label: {
                Text("Continuar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal)
            
            // Botón para saltar
            Button("Saltar este paso") {
                viewModel.nextStep()
            }
            .font(.footnote)
            .foregroundColor(.blue)
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Foto de perfil")
        .navigationBarTitleDisplayMode(.inline)
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
