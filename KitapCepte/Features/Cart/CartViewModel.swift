import Observation

@MainActor @Observable
final class CartViewModel {
    struct State: Equatable {
        /// Yalnızca ilk yükleme durumu; sepetin güncel içeriği `CartStore`'dan okunur (diğer ekranlardaki değişiklikler de yansır).
        var load: Loadable<[CartItem]> = .idle
        /// Satır içi "kaldırılsın mı?" onayı bekleyen kitap.
        var pendingRemovalID: String?
        /// Son adet/silme işleminin hatası (banner).
        var error: AppError?
    }

    enum Action {
        case onAppear
        case retry
        case increment(String)
        case decrement(String)
        case requestRemove(String)
        case cancelRemove
        case confirmRemove(String)
        case dismissError
    }

    private(set) var state = State()
    private let cart: CartStore

    init(cart: CartStore) {
        self.cart = cart
    }

    /// Ekranın gösterdiği liste: ilk yükleme bitince `CartStore.items` ile canlı.
    var content: Loadable<[CartItem]> {
        if case .loaded = state.load { return .loaded(cart.items) }
        return state.load
    }

    var summary: CartSummary { CartPricing.summary(for: cart.items) }
    var canCheckout: Bool { !cart.items.isEmpty }
    var quantityRange: ClosedRange<Int> { CartLimits.minQuantity...CartLimits.maxQuantity }

    func send(_ action: Action) async {
        switch action {
        case .onAppear:
            guard case .idle = state.load else { return }
            await load()
        case .retry:
            state.error = nil
            await load()
        case .increment(let bookID):
            await changeQuantity(of: bookID, by: 1)
        case .decrement(let bookID):
            await changeQuantity(of: bookID, by: -1)
        case .requestRemove(let bookID):
            state.pendingRemovalID = bookID
        case .cancelRemove:
            state.pendingRemovalID = nil
        case .confirmRemove(let bookID):
            await perform { try await cart.remove(bookID) }
            state.pendingRemovalID = nil
        case .dismissError:
            state.error = nil
        }
    }

    private func load() async {
        state.load = .loading
        await cart.reload()
        state.load = .loaded(cart.items)
    }

    /// Adet `CartLimits` dışına çıkarsa işlem yapılmaz (1'in altına inmez).
    private func changeQuantity(of bookID: String, by delta: Int) async {
        let target = cart.quantity(for: bookID) + delta
        guard cart.contains(bookID), (CartLimits.minQuantity...CartLimits.maxQuantity).contains(target) else { return }
        await perform { try await cart.setQuantity(target, for: bookID) }
    }

    private func perform(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            state.error = nil
        } catch {
            state.error = (error as? AppError) ?? .unknown
        }
    }
}
