import SwiftUI

struct CartView: View {
    @Environment(\.appTheme) private var theme
    let viewModel: CartViewModel
    let onProfile: () -> Void
    let onCheckout: () -> Void

    var body: some View {
        VStack(spacing: theme.dimens.spacingM) {
            AppTopBar.titled(Strings.Cart.title, onProfile: onProfile)
            content
        }
        .task { await viewModel.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.content {
        case .idle, .loading:
            LoadingView()
        case .failed(let error):
            ErrorView(message: error.message) { Task { await viewModel.send(.retry) } }
        case .loaded(let items) where items.isEmpty:
            EmptyStateView(title: Strings.Cart.emptyTitle, message: Strings.Cart.emptyMessage, systemImage: "cart")
        case .loaded(let items):
            list(items)
        }
    }

    private func list(_ items: [CartItem]) -> some View {
        ScrollView {
            VStack(spacing: theme.dimens.spacingM) {
                if let error = viewModel.state.error {
                    AppErrorBanner(message: error.message)
                        .onTapGesture { Task { await viewModel.send(.dismissError) } }
                }
                ForEach(items) { item in
                    CartItemCard(
                        item: item,
                        priceText: PriceFormatter.standard.string(from: item.unitPrice),
                        quantityRange: viewModel.quantityRange,
                        isConfirmingRemoval: viewModel.state.pendingRemovalID == item.bookID,
                        onDecrement: { Task { await viewModel.send(.decrement(item.bookID)) } },
                        onIncrement: { Task { await viewModel.send(.increment(item.bookID)) } },
                        onRequestRemove: { Task { await viewModel.send(.requestRemove(item.bookID)) } },
                        onCancelRemove: { Task { await viewModel.send(.cancelRemove) } },
                        onConfirmRemove: { Task { await viewModel.send(.confirmRemove(item.bookID)) } }
                    )
                }
                OrderSummaryCard(summary: viewModel.summary)
                AppButton(
                    title: Strings.Cart.checkout(PriceFormatter.standard.string(from: viewModel.summary.total)),
                    action: onCheckout
                )
                .disabled(!viewModel.canCheckout)
            }
            .padding(.horizontal, theme.dimens.spacingL)
            .animation(.easeOut(duration: theme.dimens.animationDuration), value: items)
        }
    }
}

#if DEBUG
@MainActor
private final class PreviewCartRepository: CartRepository {
    var stored: [CartItem] = [
        CartItem(bookID: "a", title: "The Hobbit", authors: ["J.R.R. Tolkien"], coverID: 8406786, unitPrice: 129.9, quantity: 2),
        CartItem(bookID: "b", title: "Dune", authors: ["Frank Herbert"], coverID: nil, unitPrice: 99.5)
    ]
    func items() async -> [CartItem] { stored }
    func add(_ book: Book) async throws {}
    func setQuantity(_ quantity: Int, for bookID: String) async throws {}
    func remove(_ bookID: String) async throws {}
    func clear() async throws {}
}

#Preview {
    AppScaffold {
        CartView(
            viewModel: CartViewModel(cart: CartStore(repository: PreviewCartRepository())),
            onProfile: {}, onCheckout: {}
        )
    }
}
#endif
