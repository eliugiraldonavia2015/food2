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
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    // ✅ CORRECCIÓN: Agregar inicializador público
    public init(viewModel: RoleSelectionViewModel, onCompletion: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCompletion = onCompletion
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("¿Cómo quieres unirte?")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Selecciona el perfil que mejor te defina")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                RoleCard(
                    title: "Cliente",
                    subtitle: "Quiero pedir comida y ver videos",
                    icon: "person.crop.circle",
                    selected: viewModel.selectedRole == .client,
                    action: { viewModel.selectRole(.client) }
                )
                RoleCard(
                    title: "Repartidor",
                    subtitle: "Quiero entregar pedidos",
                    icon: "scooter",
                    selected: viewModel.selectedRole == .rider,
                    action: { viewModel.selectRole(.rider) }
                )
                RoleCard(
                    title: "Restaurante",
                    subtitle: "Quiero vender mis platos",
                    icon: "building.2.crop.circle",
                    selected: viewModel.selectedRole == .restaurant,
                    action: { viewModel.selectRole(.restaurant) }
                )
            }
            .padding(.horizontal)
            
            Spacer(minLength: 40)
            
            let isEnabled = viewModel.selectedRole != nil
            Button(action: { if isEnabled { viewModel.confirmSelection(onSuccess: onCompletion) } }) {
                Text("Finalizar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(isEnabled ? fuchsiaColor : fuchsiaColor.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: fuchsiaColor.opacity(isEnabled ? 0.3 : 0.0), radius: 10, x: 0, y: 5)
            .disabled(!isEnabled)
            .padding(.horizontal)
        }
        .padding(.top, 30)
        .onAppear { viewModel.loadUser() }
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
private struct RoleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let selected: Bool
    let action: () -> Void
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selected ? Color.white.opacity(0.2) : Color.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                ZStack {
                    if selected {
                        Capsule()
                            .fill(fuchsiaColor)
                            .frame(width: 26, height: 26)
                            .overlay(Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 13, weight: .bold)))
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(22)
            .background(
                Group {
                    if selected {
                        Capsule().fill(fuchsiaColor)
                    } else {
                        RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.25))
                    }
                }
            )
            .overlay(
                Group {
                    if selected {
                        Capsule().stroke(fuchsiaColor, lineWidth: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: selected ? 30 : 18))
            .shadow(color: selected ? fuchsiaColor.opacity(0.25) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PrimaryButtonStyle
private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color(red: 244/255, green: 37/255, blue: 123/255).opacity(0.8) : Color(red: 244/255, green: 37/255, blue: 123/255))
            .foregroundColor(.white)
            .cornerRadius(30)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
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
