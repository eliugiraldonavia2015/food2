import SwiftUI

struct SaveFoldersOverlayView: View {
    struct Folder: Identifiable { let id = UUID(); let name: String; let icon: String; var color: Color }
    let onClose: () -> Void
    @State private var folders: [Folder] = [
        .init(name: "Favoritos", icon: "star.fill", color: .yellow),
        .init(name: "Postres", icon: "birthday.cake", color: .pink),
        .init(name: "Para probar", icon: "sparkles", color: .green),
        .init(name: "Recetas", icon: "book.fill", color: .blue)
    ]
    @State private var selected: UUID? = nil
    @State private var newName: String = ""
    @State private var showCreate: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            sheet
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.5)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom))
        }
        .transition(.move(edge: .bottom))
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.08))
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(folders) { f in
                        folderItem(f)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 6)
            }
            HStack(spacing: 12) {
                Button(action: { showCreate = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                        Text("Nueva carpeta")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: -4)
        .ignoresSafeArea(edges: .bottom)
        .overlay { if showCreate { createSheet } }
    }

    private var header: some View {
        HStack {
            Text("Guardar en")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            Button(action: onClose) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.08)).frame(width: 34, height: 34)
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func folderItem(_ f: Folder) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = f.id }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: f.icon)
                            .foregroundColor(f.color)
                            .font(.system(size: 20, weight: .bold))
                    )
                Text(f.name)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if selected == f.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18, weight: .bold))
                        .transition(.scale)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        }
    }

    private var createSheet: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Nueva carpeta")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                TextField("Nombre", text: $newName)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                    .foregroundColor(.white)
                HStack(spacing: 12) {
                    Button(action: { withAnimation(.easeOut(duration: 0.2)) { showCreate = false } }) {
                        Text("Cancelar").foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                    }
                    Button(action: {
                        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        folders.append(.init(name: name, icon: "folder.fill", color: .white))
                        newName = ""
                        withAnimation(.easeOut(duration: 0.2)) { showCreate = false }
                    }) {
                        Text("Crear").foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 1))
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.black))
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .transition(.opacity)
    }
}

