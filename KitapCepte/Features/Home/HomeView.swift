import SwiftUI

struct HomeView: View {
    @Environment(\.appTheme) private var theme
    @Environment(FavoritesStore.self) private var favorites
    @Environment(GuestGate.self) private var gate
    let viewModel: HomeViewModel
    let onProfile: () -> Void
    let onSelectBook: (Book) -> Void

    var body: some View {
        let state = viewModel.state
        VStack(spacing: theme.dimens.spacingM) {
            AppTopBar.home(onProfile: onProfile)
            AppChipRow(
                items: BookSubject.allCases,
                selection: state.subject,
                title: \.title,
                onSelect: { subject in Task { await viewModel.send(.selectSubject(subject)) } }
            )
            content(state)
        }
        .task { await viewModel.send(.onAppear) }
    }

    @ViewBuilder
    private func content(_ state: HomeViewModel.State) -> some View {
        switch state.books {
        case .idle, .loading:
            LoadingView()
        case .failed(let error):
            ErrorView(message: error.message) { Task { await viewModel.send(.retry) } }
        case .loaded(let books) where books.isEmpty:
            EmptyStateView(message: Strings.Home.empty)
        case .loaded(let books):
            grid(books, isLoadingMore: state.isLoadingMore)
        }
    }

    private func grid(_ books: [Book], isLoadingMore: Bool) -> some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: theme.dimens.spacingM), count: 2),
                spacing: theme.dimens.spacingM
            ) {
                ForEach(books) { book in
                    BookCard(
                        book: book,
                        priceText: PriceFormatter.standard.string(from: book.price),
                        isFavorite: favorites.isFavorite(book.id),
                        onSelect: { onSelectBook(book) },
                        onToggleFavorite: { gate.require { Task { await favorites.toggle(book) } } }
                    )
                    .onAppear { Task { await viewModel.send(.bookAppeared(book)) } }
                }
            }
            .padding(.horizontal, theme.dimens.spacingL)
            if isLoadingMore {
                ProgressView().tint(theme.colors.textOnPrimary).padding(theme.dimens.spacingL)
            }
        }
    }
}
