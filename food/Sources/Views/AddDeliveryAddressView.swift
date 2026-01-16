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

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        mapHeader
                        gpsButton
                            .padding(.top, -18)
                        form
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 18)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .preferredColorScheme(.light)
    }

    private var topBar: some View {
        ZStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 40, height: 40)
                }
                Spacer()
            }

            Text("Agregar Dirección")
                .foregroundColor(.black)
                .font(.system(size: 20, weight: .bold))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var mapHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.gray.opacity(0.08))
                .overlay(
                    DotGrid()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .frame(height: 210)

            VStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 36, weight: .bold))
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 8)
            }
        }
    }

    private var gpsButton: some View {
        Button(action: useGPS) {
            HStack(spacing: 10) {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.brandGreen)
                    .font(.system(size: 18, weight: .bold))
                Text(isUsingGPS ? "Obteniendo ubicación..." : "Usar ubicación GPS")
                    .foregroundColor(.black)
                    .font(.system(size: 15, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
        }
        .disabled(isUsingGPS)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            field(label: "Nombre/Alias (ej. Gimnasio)", placeholder: "Casa, Oficina, etc.", text: $alias)
            field(label: "Calle y Número", placeholder: "Av. Principal 123", text: $street)
            field(label: "Ciudad", placeholder: "Ciudad de México", text: $city)
            field(label: "Referencias adicionales (ej. Puerta roja)", placeholder: "Frente al parque, portón blanco...", text: $references)
        }
    }

    private func field(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.black)
                .font(.system(size: 14, weight: .bold))
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray.opacity(0.7))
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 14)
                }
                TextField("", text: text)
                    .foregroundColor(.black)
                    .font(.system(size: 15, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: save) {
                Text("Guardar Dirección")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
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

