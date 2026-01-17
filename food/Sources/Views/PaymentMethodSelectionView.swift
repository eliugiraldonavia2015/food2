import SwiftUI

struct PaymentMethodSelectionView: View {
    struct PaymentItem: Identifiable, Hashable {
        enum Kind: Hashable {
            case card
            case applePay
            case cash
        }

        let id: String
        let kind: Kind
        let title: String
        let subtitle: String
        let systemIcon: String
    }

    let cards: [PaymentItem]
    let otherMethods: [PaymentItem]
    let initialSelectedId: String?
    let onConfirm: (PaymentItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedId: String?
    @State private var showAddCard = false
    @State private var cardsState: [PaymentItem] = []

    init(
        cards: [PaymentItem],
        otherMethods: [PaymentItem],
        initialSelectedId: String?,
        onConfirm: @escaping (PaymentItem) -> Void
    ) {
        self.cards = cards
        self.otherMethods = otherMethods
        self.initialSelectedId = initialSelectedId
        self.onConfirm = onConfirm
        _selectedId = State(initialValue: initialSelectedId ?? cards.first?.id ?? otherMethods.first?.id)
        _cardsState = State(initialValue: cards)
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        sectionTitle("TUS TARJETAS")
                        VStack(spacing: 12) {
                            ForEach(cardsState) { item in
                                paymentCard(item, showsEdit: true)
                            }
                        }

                        addNewCardButton

                        sectionTitle("OTROS MÉTODOS")
                            .padding(.top, 8)
                        VStack(spacing: 12) {
                            ForEach(otherMethods) { item in
                                paymentCard(item, showsEdit: false)
                            }
                        }

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
        .fullScreenCover(isPresented: $showAddCard) {
            AddPaymentCardView { newCard in
                cardsState.append(newCard)
                selectedId = newCard.id
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

            Text("Métodos de Pago")
                .foregroundColor(.black)
                .font(.system(size: 20, weight: .bold))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .foregroundColor(.gray)
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func paymentCard(_ item: PaymentItem, showsEdit: Bool) -> some View {
        let isSelected = selectedId == item.id

        return Button(action: { selectedId = item.id }) {
            HStack(spacing: 12) {
                iconBadge(for: item)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }

                Spacer()

                if showsEdit {
                    Button(action: {}) {
                        Text("Editar")
                            .foregroundColor(.fuchsia)
                            .font(.system(size: 13, weight: .bold))
                    }
                }

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

    private func iconBadge(for item: PaymentItem) -> some View {
        switch item.kind {
        case .card:
            return AnyView(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.06))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: item.systemIcon)
                            .foregroundColor(.black.opacity(0.8))
                            .font(.system(size: 16, weight: .bold))
                    )
            )
        case .applePay:
            return AnyView(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.06))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: item.systemIcon)
                            .foregroundColor(.black.opacity(0.85))
                            .font(.system(size: 16, weight: .bold))
                    )
            )
        case .cash:
            return AnyView(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.fuchsia.opacity(0.10))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: item.systemIcon)
                            .foregroundColor(.fuchsia)
                            .font(.system(size: 16, weight: .bold))
                    )
            )
        }
    }

    private var addNewCardButton: some View {
        Button(action: { showAddCard = true }) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.fuchsia)
                    .font(.system(size: 18, weight: .bold))
                Text("Agregar Nueva Tarjeta")
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
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: confirmSelection) {
                Text("Confirmar Pago")
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
        guard let selectedId else { return }
        if let item = cardsState.first(where: { $0.id == selectedId }) ?? otherMethods.first(where: { $0.id == selectedId }) {
            onConfirm(item)
        }
        dismiss()
    }
}

