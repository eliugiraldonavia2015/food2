import SwiftUI
import PhotosUI

struct UploadDishView: View {
    let onClose: () -> Void
    @State private var name: String = ""
    @State private var price: String = ""
    @State private var category: String = "Plato fuerte"
    @State private var ingredients: String = ""
    @State private var availability: Bool = true
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoURL: URL? = nil
    @State private var isPublishing: Bool = false
    @State private var showSuccess: Bool = false

    private let categories = ["Plato fuerte", "Entrada", "Postre", "Bebida", "Snack"]

    var body: some View {
        VStack(spacing: 16) {
            header()
            ScrollView {
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 160)
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.green)
                                    .font(.system(size: 28, weight: .bold))
                                Text(selectedPhoto == nil ? "Selecciona una foto" : "Foto seleccionada")
                                    .foregroundColor(.white)
                                    .font(.subheadline.bold())
                            }
                        }
                    }

                    textField("Nombre del plato", text: $name)
                    textField("Precio (USD)", text: $price)
                    pickerField(title: "Categoría", selection: $category, options: categories)
                    textArea("Ingredientes", text: $ingredients)
                    toggleField("Disponible", isOn: $availability)

                    HStack(spacing: 12) {
                        primaryFilledButton(title: "Simular Upload Foto") {
                            photoURL = URL(string: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c")
                        }
                        primaryOutlinedButton(title: "Limpiar Foto") { photoURL = nil }
                    }

                    if let urlStr = photoURL?.absoluteString, let url = URL(string: urlStr) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 160)
                            .overlay(
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image): image.resizable().scaledToFill()
                                    case .empty: ProgressView().tint(.green)
                                    case .failure(_): Image(systemName: "photo").foregroundColor(.white)
                                    @unknown default: Color.gray
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            )
                    }

                    primaryFilledButton(title: isPublishing ? "Publicando…" : "Publicar Plato") {
                        guard !name.isEmpty, !price.isEmpty else { return }
                        isPublishing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            isPublishing = false
                            showSuccess = true
                        }
                    }
                    .disabled(isPublishing)
                }
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .top) { if showSuccess { successBanner("Plato publicado correctamente") } }
    }

    private func header() -> some View {
        HStack {
            Button(action: onClose) {
                Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36).overlay(Image(systemName: "arrow.backward").foregroundColor(.white))
            }
            Spacer()
            Text("Publicar Plato").foregroundColor(.white).font(.headline.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func textField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundColor(.white).font(.footnote)
            TextField("", text: text)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func textArea(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundColor(.white).font(.footnote)
            TextEditor(text: text)
                .foregroundColor(.white)
                .frame(height: 120)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func toggleField(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title).foregroundColor(.white).font(.footnote.bold())
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(.green)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func pickerField(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundColor(.white).font(.footnote)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)
            .tint(.green)
        }
    }

    private func primaryFilledButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .background(
            LinearGradient(colors: [Color.green.opacity(0.95), Color.green.opacity(0.75)], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(Capsule())
        .shadow(color: .green.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private func primaryOutlinedButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .background(Color.clear)
        .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
        .clipShape(Capsule())
    }

    private func successBanner(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text(text).foregroundColor(.white).font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.95)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

