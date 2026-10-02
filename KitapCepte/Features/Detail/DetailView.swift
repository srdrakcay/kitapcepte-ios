import SwiftUI

struct DetailView: View {
    @Environment(\.appTheme) private var theme
    /// State: üst görünüm yeniden çizilip yeni ViewModel üretse de ilk örnek korunur.
    @State private var viewModel: DetailViewModel
    let onBack: () -> Void
    let onSelectBook: (Book) -> Void

    init(viewModel: DetailViewModel, onBack: @escaping () -> Void, onSelectBook: @escaping (Book) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onBack = onBack
        self.onSelectBook = onSelectBook
    }

    var body: some View {
        let book = viewModel.book
        AppScaffold(
            top: {
                AppTopBar.detail(
                    title: Strings.Detail.title,
                    isFavorite: viewModel.isFavorite(book),
                    onBack: onBack,
                    onToggleFavorite: { Task { await viewModel.send(.toggleFavorite(book)) } }
                )
            },
            bottom: {
                AddToCartBar(
                    priceText: PriceFormatter.standard.string(from: book.price),
                    isInCart: viewModel.isInCart,
                    onAdd: { Task { await viewModel.send(.addToCart) } }
                )
            },
            content: { content(book) }
        )
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.send(.onAppear) }
    }

    private func content(_ book: Book) -> some View {
        ScrollView {
            VStack(spacing: theme.dimens.spacingL) {
                cover(book)
                VStack(alignment: .leading, spacing: theme.dimens.spacingL) {
                    info(book)
                    descriptionSection
                    AppDivider().padding(.horizontal, theme.dimens.spacingL)
                    similarSection
                }
                .padding(.vertical, theme.dimens.spacingL)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.colors.surface, in: theme.shapes.card)
                .padding(.horizontal, theme.dimens.spacingL)
            }
            .padding(.bottom, theme.dimens.spacingL)
        }
    }

    private func cover(_ book: Book) -> some View {
        Color.clear
            .aspectRatio(theme.dimens.coverAspectRatio, contentMode: .fit)
            .frame(height: theme.dimens.detailCoverHeight)
            .overlay { AppAsyncImage(url: book.coverURL(.large)) }
            .clipShape(theme.shapes.card)
            .overlay(alignment: .topLeading) {
                if book.isTopItem {
                    AppBadge(text: Strings.Home.topItem).padding(theme.dimens.spacingS)
                }
            }
            .shadow(color: theme.colors.shadow, radius: theme.dimens.shadowRadius, y: theme.dimens.shadowOffsetY)
            .padding(.top, theme.dimens.spacingS)
    }

    private func info(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: theme.dimens.spacingXS) {
            Text(book.title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if !book.authors.isEmpty {
                Text(book.authorsLine)
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .padding(.horizontal, theme.dimens.spacingL)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: theme.dimens.spacingS) {
            SectionHeader(title: Strings.Detail.descriptionTitle)
            switch viewModel.state.description {
            case .idle, .loading:
                ProgressView().tint(theme.colors.primary).frame(maxWidth: .infinity)
            case .failed:
                descriptionText(Strings.Detail.descriptionEmpty)
            case .loaded(let text):
                descriptionText(text ?? Strings.Detail.descriptionEmpty)
            }
        }
        .padding(.horizontal, theme.dimens.spacingL)
    }

    private func descriptionText(_ text: String) -> some View {
        Text(text)
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var similarSection: some View {
        VStack(alignment: .leading, spacing: theme.dimens.spacingS) {
            SectionHeader(title: Strings.Detail.similarTitle)
                .padding(.horizontal, theme.dimens.spacingL)
            switch viewModel.state.similar {
            case .idle, .loading:
                ProgressView().tint(theme.colors.primary).frame(maxWidth: .infinity)
            case .failed(let error):
                VStack(spacing: theme.dimens.spacingS) {
                    AppErrorBanner(message: error.message)
                    AppButton(title: Strings.Common.retry, kind: .secondary) {
                        Task { await viewModel.send(.retrySimilar) }
                    }
                }
                .padding(.horizontal, theme.dimens.spacingL)
            case .loaded(let books) where books.isEmpty:
                descriptionText(Strings.Detail.similarEmpty)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.horizontal, theme.dimens.spacingL)
            case .loaded(let books):
                similarList(books)
            }
        }
    }

    private func similarList(_ books: [Book]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: theme.dimens.spacingM) {
                ForEach(books) { book in
                    BookCard(
                        book: book,
                        priceText: PriceFormatter.standard.string(from: book.price),
                        isFavorite: viewModel.isFavorite(book),
                        onSelect: { onSelectBook(book) },
                        onToggleFavorite: { Task { await viewModel.send(.toggleFavorite(book)) } }
                    )
                    .frame(width: theme.dimens.similarCardWidth)
                }
            }
        }
        .contentMargins(.horizontal, theme.dimens.spacingL, for: .scrollContent)
    }
}

#if DEBUG
#Preview {
    let book = Book(id: "/works/OL262758W", title: "The Hobbit", authors: ["J.R.R. Tolkien"], coverID: 8406786,
                    firstPublishYear: 1937, price: 129.9, isTopItem: true, authorKeys: ["OL26320A"], subject: .fantasy)
    DetailView(viewModel: AppContainer.live().makeDetailViewModel(book: book), onBack: {}, onSelectBook: { _ in })
}
#endif
