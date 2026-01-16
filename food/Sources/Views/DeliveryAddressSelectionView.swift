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
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(addressesState) { item in
                            addressCard(item)
                        }
                        addNewAddressButton
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showAddAddress) {
            AddDeliveryAddressView { newAddress in
                addressesState.append(newAddress)
                selectedId = newAddress.id
            }
        }
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

            Text("Direcciones de Entrega")
                .foregroundColor(.black)
                .font(.system(size: 20, weight: .bold))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func addressCard(_ item: AddressItem) -> some View {
        let isSelected = selectedId == item.id
        return Button(action: { selectedId = item.id }) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.fuchsia.opacity(0.14))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: item.systemIcon)
                            .foregroundColor(.fuchsia)
                            .font(.system(size: 16, weight: .bold))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.title)
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Button(action: {}) {
                            Text("Editar")
                                .foregroundColor(.fuchsia)
                                .font(.system(size: 13, weight: .bold))
                        }
                    }

                    Text(item.detail)
                        .foregroundColor(.gray)
                        .font(.system(size: 12, weight: .semibold))
                        .multilineTextAlignment(.leading)

                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(isSelected ? Color.fuchsia : Color.gray.opacity(0.25), lineWidth: 2)
                                .frame(width: 20, height: 20)
                            if isSelected {
                                Circle()
                                    .fill(Color.fuchsia)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.fuchsia : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
        }
    }

    private var addNewAddressButton: some View {
        Button(action: { showAddAddress = true }) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 16, weight: .bold))
                Text("Agregar Nueva Dirección")
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .foregroundColor(Color.fuchsia.opacity(0.55))
            )
        }
        .padding(.top, 4)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: confirmSelection) {
                Text("Confirmar Dirección")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(selectedId == nil)
            .opacity(selectedId == nil ? 0.6 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }

    private func confirmSelection() {
        guard let selectedId, let item = addressesState.first(where: { $0.id == selectedId }) else { return }
        onConfirm(item)
        dismiss()
    }
}

