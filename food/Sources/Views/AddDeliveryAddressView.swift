import SwiftUI
import UIKit

struct AddDeliveryAddressView: View {
    let onSave: (DeliveryAddressSelectionView.AddressItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var alias: String = ""
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var references: String = ""
    @State private var isUsingGPS = false
    
    // Animation States
    @State private var animateContent = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case alias, street, city, references
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .background(Color(uiColor: .systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .zIndex(10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        mapHeader
                            .scaleEffect(animateContent ? 1 : 0.95)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateContent)
                        
                        gpsButton
                            .offset(y: animateContent ? 0 : 20)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
                        
                        form
                            .offset(y: animateContent ? 0 : 20)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
                            
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: { dismiss() }) {
                    Circle()
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                                .font(.system(size: 16, weight: .bold))
                        )
                }
                Spacer()
            }

            Text("Nueva Dirección")
                .foregroundColor(.primary)
                .font(.system(size: 17, weight: .semibold))
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var mapHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.fuchsia.opacity(0.05))
                .overlay(
                    DotGrid()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .opacity(0.5)
                )
                .frame(height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.fuchsia.opacity(0.1), lineWidth: 1)
                )

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.fuchsia.opacity(0.2), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.fuchsia)
                        .font(.system(size: 32, weight: .bold))
                }
                
                Text("Ubicación aproximada")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var gpsButton: some View {
        Button(action: useGPS) {
            HStack(spacing: 12) {
                Image(systemName: isUsingGPS ? "location.fill" : "location.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold))
                    .symbolEffect(.bounce, value: isUsingGPS)
                
                Text(isUsingGPS ? "Obteniendo ubicación..." : "Usar ubicación actual")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.fuchsia, .fuchsia.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .fuchsia.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .disabled(isUsingGPS)
        .buttonStyle(ScaleButtonStyle())
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 24) {
            field(label: "Nombre o etiqueta", placeholder: "Ej. Casa, Oficina", text: $alias, icon: "tag.fill", fieldType: .alias)
            field(label: "Calle y número", placeholder: "Ej. Av. Reforma 222", text: $street, icon: "signpost.right.fill", fieldType: .street)
            field(label: "Ciudad", placeholder: "Ej. Ciudad de México", text: $city, icon: "building.2.fill", fieldType: .city)
            field(label: "Referencias", placeholder: "Ej. Portón negro, frente al parque...", text: $references, icon: "info.circle.fill", fieldType: .references)
        }
        .padding(24)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 5)
    }

    private func field(label: String, placeholder: String, text: Binding<String>, icon: String, fieldType: Field) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(focusedField == fieldType ? .fuchsia : .gray)
                
                Text(label)
                    .foregroundColor(.secondary)
                    .font(.system(size: 13, weight: .semibold))
                    .textCase(.uppercase)
            }
            
            TextField(placeholder, text: text)
                .focused($focusedField, equals: fieldType)
                .font(.system(size: 17, weight: .medium))
                .padding(.vertical, 12)
                .padding(.horizontal, 0)
                .overlay(Rectangle().frame(height: 1).foregroundColor(focusedField == fieldType ? .fuchsia : .gray.opacity(0.2)), alignment: .bottom)
                .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.5)
            
            Button(action: save) {
                Text("Guardar Dirección")
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canSave ? Color.green : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: canSave ? Color.green.opacity(0.3) : .clear, radius: 10, x: 0, y: 6)
                    .animation(.easeInOut, value: canSave)
            }
            .disabled(!canSave)
            .padding(16)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var canSave: Bool {
        !alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func useGPS() {
        isUsingGPS = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            alias = alias.isEmpty ? "Mi Casa" : alias
            street = street.isEmpty ? "Av. Paseo de la Reforma 222" : street
            city = city.isEmpty ? "Ciudad de México" : city
            references = references.isEmpty ? "Timbre no funciona, llamar al llegar." : references
            isUsingGPS = false
        }
    }

    private func save() {
        let title = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = [
            street.trimmingCharacters(in: .whitespacesAndNewlines),
            city.trimmingCharacters(in: .whitespacesAndNewlines),
            references.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        let item = DeliveryAddressSelectionView.AddressItem(
            id: ULID.new().lowercased(),
            title: title,
            detail: detail,
            systemIcon: "house.fill"
        )
        onSave(item)
        dismiss()
    }
}

private struct DotGrid: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let spacing: CGFloat = 14
                let dotRadius: CGFloat = 1.25
                var path = Path()
                var y: CGFloat = 10
                while y < size.height - 10 {
                    var x: CGFloat = 10
                    while x < size.width - 10 {
                        path.addEllipse(in: CGRect(x: x, y: y, width: dotRadius * 2, height: dotRadius * 2))
                        x += spacing
                    }
                    y += spacing
                }
                context.fill(path, with: .color(Color.gray.opacity(0.18)))
            }
        }
    }
}

