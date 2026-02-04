import SwiftUI

struct DeliveryAddressSelectionView: View {
    struct AddressItem: Identifiable, Hashable {
        let id: String
        let title: String
        let detail: String
        let systemIcon: String
    }

    let addresses: [AddressItem]
    let initialSelectedId: String?
    let onConfirm: (AddressItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedId: String?
    @State private var showAddAddress = false
    @State private var addressesState: [AddressItem] = []
    
    // Animation States
    @State private var animateContent = false
    @State private var pressedCardId: String? = nil

    init(
        addresses: [AddressItem],
        initialSelectedId: String?,
        onConfirm: @escaping (AddressItem) -> Void
    ) {
        self.addresses = addresses
        self.initialSelectedId = initialSelectedId
        self.onConfirm = onConfirm
        _selectedId = State(initialValue: initialSelectedId ?? addresses.first?.id)
        _addressesState = State(initialValue: addresses)
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
                    VStack(spacing: 16) {
                        if addressesState.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(Array(addressesState.enumerated()), id: \.element.id) { index, item in
                                addressCard(item)
                                    .scaleEffect(pressedCardId == item.id ? 0.96 : 1.0)
                                    .opacity(animateContent ? 1 : 0)
                                    .offset(y: animateContent ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.05),
                                        value: animateContent
                                    )
                            }
                        }
                        
                        addNewAddressButton
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(addressesState.count) * 0.05 + 0.1),
                                value: animateContent
                            )
                            
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showAddAddress) {
            AddDeliveryAddressView { newAddress in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    addressesState.append(newAddress)
                    selectedId = newAddress.id
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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

            Text("Elige tu ubicación")
                .foregroundColor(.primary)
                .font(.system(size: 17, weight: .semibold))
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.3))
                .padding(.bottom, 8)
            
            Text("No tienes direcciones guardadas")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Agrega una dirección para recibir tus pedidos.")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .opacity(animateContent ? 1 : 0)
        .scaleEffect(animateContent ? 1 : 0.9)
    }

    private func addressCard(_ item: AddressItem) -> some View {
        let isSelected = selectedId == item.id
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedId = item.id
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            HStack(alignment: .top, spacing: 16) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.fuchsia.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: item.systemIcon)
                        .foregroundColor(isSelected ? .fuchsia : .gray)
                        .font(.system(size: 20, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.title)
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .semibold))
                        
                        if isSelected {
                            Text("Principal")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.fuchsia)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.fuchsia.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.fuchsia)
                                .font(.system(size: 22))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Text(item.detail)
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                }
            }
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.fuchsia : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: Color.black.opacity(isSelected ? 0.08 : 0.03),
                radius: isSelected ? 12 : 8,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var addNewAddressButton: some View {
        Button(action: { showAddAddress = true }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 22))
                
                Text("Agregar nueva dirección")
                    .foregroundColor(.primary)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(20)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)
            
            Button(action: confirmSelection) {
                Text("Confirmar ubicación")
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 6)
            }
            .disabled(selectedId == nil)
            .opacity(selectedId == nil ? 0.5 : 1)
            .padding(16)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private func confirmSelection() {
        guard let selectedId, let item = addressesState.first(where: { $0.id == selectedId }) else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        onConfirm(item)
        dismiss()
    }
}

// ScaleButtonStyle already defined in Shared/Components/Buttons/ScaleButtonStyle.swift


