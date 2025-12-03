//
//  RoleSelectionView.swift
//  food
//
//  Created by eliu giraldo on 28/11/25.
//

// Sources/Presentation/Authentication/RoleSelection/RoleSelectionView.swift
import SwiftUI

// ✅ CORRECCIÓN: Hacer pública la vista y agregar inicializador
public struct RoleSelectionView: View {
    @StateObject public var viewModel: RoleSelectionViewModel // ✅ PUBLIC VIEWMODEL
    var onCompletion: () -> Void
    
    // ✅ CORRECCIÓN: Agregar inicializador público
    public init(viewModel: RoleSelectionViewModel, onCompletion: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCompletion = onCompletion
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Selecciona tu rol")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("¿Cómo quieres usar la plataforma?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 24) {
                        RoleOptionView(
                            title: "Cliente",
                            description: "Disfruta tu comida favorita",
                            features: [
                                "Miles de restaurantes",
                                "Entregas rápidas",
                                "Ofertas exclusivas"
                            ],
                            icon: "person.crop.circle",
                            isSelected: viewModel.selectedRole == .client,
                            action: { viewModel.selectRole(.client) }
                        )
                        
                        RoleOptionView(
                            title: "Repartidor",
                            description: "Gana dinero flexiblemente",
                            features: [
                                "Horarios flexibles",
                                "Ganancias inmediatas",
                                "Seguro incluido"
                            ],
                            icon: "scooter",
                            isSelected: viewModel.selectedRole == .rider,
                            action: { viewModel.selectRole(.rider) }
                        )
                        
                        RoleOptionView(
                            title: "Restaurante",
                            description: "Aumenta tus ventas",
                            features: [
                                "Sin costo inicial",
                                "Miles de clientes",
                                "Soporte 24/7"
                            ],
                            icon: "building.2.crop.circle",
                            isSelected: viewModel.selectedRole == .restaurant,
                            action: { viewModel.selectRole(.restaurant) }
                        )
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
            
            finalizeBar
        }
        .onAppear {
            viewModel.loadUser()
        }
    }
    
    private var finalizeBar: some View {
        let isEnabled = viewModel.selectedRole != nil
        return VStack {
            Button(action: { if isEnabled { viewModel.confirmSelection(onSuccess: onCompletion) } }) {
                Text("Finalizar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(isEnabled ? Color.green : Color.green.opacity(0.4))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .green.opacity(isEnabled ? 0.25 : 0.0), radius: 10, x: 0, y: 4)
            .disabled(!isEnabled)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - RoleOptionView
private struct RoleOptionView: View {
    let title: String
    let description: String
    let features: [String]
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .padding(12)
                        .background(isSelected ? Color.orange.opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .orange : .primary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(feature)
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - PrimaryButtonStyle
private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color.orange.opacity(0.8) : Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        RoleSelectionView(
            viewModel: RoleSelectionViewModel(),
            onCompletion: {}
        )
    }
}
