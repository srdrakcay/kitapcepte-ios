import SwiftUI

struct PaymentView: View {
    @Environment(\.appTheme) private var theme
    @State private var viewModel: PaymentViewModel
    @FocusState private var focus: CardField?
    let onBack: () -> Void
    let onFinish: () -> Void

    init(viewModel: PaymentViewModel, onBack: @escaping () -> Void, onFinish: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onBack = onBack
        self.onFinish = onFinish
    }

    var body: some View {
        AppScaffold(
            top: {
                AppTopBar(
                    title: Strings.Payment.title,
                    leading: {
                        if viewModel.receipt == nil {
                            AppIconButton(systemImage: "chevron.left", accessibilityLabel: Strings.Accessibility.back, action: onBack)
                        }
                    },
                    trailing: { EmptyView() }
                )
            },
            bottom: { EmptyView() },
            content: { content }
        )
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { viewModel.leave() }
    }

    @ViewBuilder
    private var content: some View {
        if let receipt = viewModel.receipt {
            success(receipt)
        } else if viewModel.isCartEmpty {
            EmptyStateView(title: Strings.Payment.emptyTitle, message: Strings.Payment.emptyMessage, systemImage: "cart")
        } else {
            form
        }
    }

    private var form: some View {
        let state = viewModel.state
        let errors = viewModel.errors
        let preview = viewModel.preview
        return ScrollView {
            VStack(spacing: theme.dimens.spacingL) {
                CardPreview(
                    brandName: preview.brandName, numberText: preview.numberText, holderText: preview.holderText,
                    expiryText: preview.expiryText, accessibilityText: preview.accessibilityText
                )
                AppFormCard {
                    AppTextField(
                        label: Strings.Payment.numberLabel,
                        text: Binding(get: { viewModel.displayNumber }, set: { viewModel.send(.numberChanged($0)) }),
                        systemImage: "creditcard",
                        errorMessage: errors[.number]?.message,
                        keyboard: .numberPad,
                        accessibilityLabel: Strings.Payment.numberA11y,
                        format: CardFormatter.formatNumber
                    )
                    .focused($focus, equals: .number)
                    AppTextField(
                        label: Strings.Payment.holderLabel,
                        text: Binding(get: { state.card.holderName }, set: { viewModel.send(.holderChanged($0)) }),
                        systemImage: "person",
                        errorMessage: errors[.holder]?.message,
                        capitalization: .characters,
                        format: CardFormatter.formatHolder
                    )
                    .focused($focus, equals: .holder)
                    HStack(alignment: .top, spacing: theme.dimens.spacingM) {
                        AppTextField(
                            label: Strings.Payment.expiryLabel,
                            text: Binding(get: { state.card.expiry }, set: { viewModel.send(.expiryChanged($0)) }),
                            errorMessage: errors[.expiry]?.message,
                            keyboard: .numberPad,
                            format: CardFormatter.formatExpiry
                        )
                        .focused($focus, equals: .expiry)
                        AppSecureField(
                            label: Strings.Payment.cvvLabel,
                            text: Binding(get: { state.card.cvv }, set: { viewModel.send(.cvvChanged($0)) }),
                            systemImage: nil,
                            errorMessage: errors[.cvv]?.message,
                            keyboard: .numberPad,
                            format: { CardFormatter.formatCvv($0, brand: viewModel.brand) }
                        )
                        .focused($focus, equals: .cvv)
                    }
                    AppToggleRow(
                        title: Strings.Payment.saveCard,
                        isOn: Binding(get: { state.saveCard }, set: { viewModel.send(.saveCardChanged($0)) })
                    )
                }
                if let formError = state.formError {
                    AppErrorBanner(message: formError)
                        .onTapGesture { viewModel.send(.dismissError) }
                }
                VStack(spacing: theme.dimens.spacingL) {
                    SummaryRow(
                        title: Strings.Payment.total,
                        value: PriceFormatter.standard.string(from: viewModel.total),
                        isEmphasized: true
                    )
                    AppButton(
                        title: Strings.Payment.pay(PriceFormatter.standard.string(from: viewModel.total)),
                        isLoading: viewModel.isPaying
                    ) {
                        focus = nil
                        viewModel.startPayment()
                    }
                    .disabled(!viewModel.canPay)
                }
                .padding(theme.dimens.spacingL)
                .background(theme.colors.surfaceWhite, in: theme.shapes.card)
            }
            .padding(.horizontal, theme.dimens.spacingL)
            .padding(.top, theme.dimens.spacingS)
            .padding(.bottom, theme.dimens.spacingXL)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: focus) { old, _ in
            if let old { viewModel.send(.fieldLeft(old)) }
        }
    }

    private func success(_ receipt: PaymentReceipt) -> some View {
        SuccessView(
            title: Strings.Payment.successTitle,
            message: Strings.Payment.successMessage,
            buttonTitle: Strings.Payment.backHome,
            onContinue: onFinish
        ) {
            SummaryRow(title: Strings.Payment.receiptReference, value: receipt.reference)
            SummaryRow(title: Strings.Payment.receiptAmount, value: PriceFormatter.standard.string(from: receipt.amount))
            SummaryRow(
                title: Strings.Payment.receiptCard,
                value: Strings.Payment.cardDescription(brand: receipt.brand.title, last4: receipt.last4)
            )
            SummaryRow(title: Strings.Payment.receiptDate, value: receipt.paidAt.formatted(date: .abbreviated, time: .shortened))
        }
    }
}

#if DEBUG
@MainActor
private final class PreviewCartRepository: CartRepository {
    func items() async -> [CartItem] { [CartItem(bookID: "a", title: "Dune", authors: [], coverID: nil, unitPrice: 99.5)] }
    func add(_ book: Book) async throws {}
    func setQuantity(_ quantity: Int, for bookID: String) async throws {}
    func remove(_ bookID: String) async throws {}
    func clear() async throws {}
}

@MainActor
private final class PreviewSavedCardRepository: SavedCardRepository {
    func cards() async -> [PaymentCardSummary] { [] }
    func save(_ summary: PaymentCardSummary) async throws {}
    func delete(id: UUID) async throws {}
}

#Preview {
    @Previewable @State var cart = CartStore(repository: PreviewCartRepository())
    let saved = SavedCardsStore(repository: PreviewSavedCardRepository())
    return PaymentView(
        viewModel: PaymentViewModel(
            pay: PayUseCase(validator: CardValidator(), gateway: SimulatedPaymentGateway(), cart: cart, savedCards: saved),
            cart: cart
        ),
        onBack: {}, onFinish: {}
    )
    .task { await cart.reload() }
}
#endif
