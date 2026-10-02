import Observation

@MainActor @Observable
final class HomeViewModel {
    struct State: Equatable {
        /// nil = hiçbir chip seçili değil (varsayılan konu gösterilir).
        var subject: BookSubject?
        var books: Loadable<[Book]> = .idle
        var isLoadingMore = false
        var canLoadMore = false
        var page = 1
    }

    enum Action {
        case onAppear
        case selectSubject(BookSubject)
        case retry
        case bookAppeared(Book)
    }

    private(set) var state = State()
    private let getBooks: GetBooksUseCase
    /// Eski isteklerin sonucunu çöpe atmak için her yeni yüklemede artar.
    private var generation = 0

    init(getBooks: GetBooksUseCase) {
        self.getBooks = getBooks
    }

    func send(_ action: Action) async {
        switch action {
        case .onAppear:
            if case .idle = state.books { await reload() }
        case .selectSubject(let subject):
            state.subject = (state.subject == subject) ? nil : subject
            await reload()
        case .retry:
            await reload()
        case .bookAppeared(let book):
            guard book.id == state.books.value?.last?.id else { return }
            await loadNextPage()
        }
    }

    private func reload() async {
        generation += 1
        let current = generation
        state.books = .loading
        state.isLoadingMore = false
        state.canLoadMore = false
        state.page = 1
        do {
            let page = try await getBooks(subject: state.subject, page: 1)
            guard current == generation else { return }
            state.books = .loaded(Self.unique(page.books))
            state.canLoadMore = page.hasMore
        } catch is CancellationError {
            if current == generation { state.books = .idle }
        } catch {
            guard current == generation else { return }
            state.books = .failed((error as? AppError) ?? .unknown)
        }
    }

    private func loadNextPage() async {
        guard state.canLoadMore, !state.isLoadingMore, let existing = state.books.value else { return }
        let current = generation
        let nextPage = state.page + 1
        state.isLoadingMore = true
        do {
            let page = try await getBooks(subject: state.subject, page: nextPage)
            guard current == generation else { return }
            state.books = .loaded(Self.unique(existing + page.books))
            state.page = nextPage
            state.canLoadMore = page.hasMore
        } catch {
            // Sayfa yüklenemedi: liste korunur, son kart tekrar görününce yeniden denenir.
        }
        if current == generation { state.isLoadingMore = false }
    }

    private static func unique(_ books: [Book]) -> [Book] {
        var seen = Set<String>()
        return books.filter { seen.insert($0.id).inserted }
    }
}
