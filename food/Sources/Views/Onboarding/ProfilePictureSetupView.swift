// Sources/Views/Onboarding/ProfilePictureSetupView.swift
import SwiftUI
import PhotosUI
import UIKit

struct ProfilePictureSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(fuchsiaColor)
                }
                Spacer()
                Text("FoodTook")
                    .font(.headline)
                    .foregroundColor(fuchsiaColor)
                Spacer()
            }
            .padding(.horizontal)
            
            Text("Dale un rostro a tu antojo")
                .font(.title)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                
            Text("Una foto ayuda a que la comunidad de FoodTook te reconozca mejor.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showImagePicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 160, height: 160)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .overlay(Circle().stroke(fuchsiaColor, lineWidth: 3))
                    Group {
                        if let image = viewModel.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 64))
                                .foregroundColor(.gray)
                        }
                    }
                    VStack { Spacer() }
                }
                .overlay(
                    ZStack {
                        Circle()
                            .fill(fuchsiaColor)
                            .frame(width: 36, height: 36)
                            .shadow(color: fuchsiaColor.opacity(0.3), radius: 6, x: 0, y: 4)
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .offset(x: 56, y: 56)
                )
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
            
            Button("Saltar este paso") {
                viewModel.nextStep()
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
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
