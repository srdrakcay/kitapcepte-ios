import Foundation
import SwiftData
import Testing
@testable import KitapCepte

struct CartPricingTests {
    @Test func emptyCartCostsNothingIncludingShipping() {
        #expect(CartPricing.summary(for: []) == CartSummary(subtotal: 0, tax: 0, shipping: 0))
    }

    @Test func subtotalSumsUnitPriceTimesQuantity() {
        let items = [CartItem.sample(id: "a", price: 40, quantity: 2), .sample(id: "b", price: 10.5, quantity: 1)]
        #expect(CartPricing.summary(for: items).subtotal == 90.5)
    }

    @Test func taxIsConfiguredRateOfSubtotal() {
        let summary = CartPricing.summary(for: [.sample(price: 100, quantity: 1)])
        #expect(TaxPolicy.rate == 0.20)
        #expect(summary.tax == 20)
    }

    @Test func taxIsRoundedToKurus() {
        // 129,90 x 0,20 = 25,98 ; 33,33 x 0,20 = 6,666 -> 6,67
        #expect(CartPricing.summary(for: [.sample(price: 129.9)]).tax == 25.98)
        #expect(CartPricing.summary(for: [.sample(price: 33.33)]).tax == 6.67)
    }

    @Test func shippingChargedBelowThresholdAndFreeAtOrAbove() {
        #expect(CartPricing.summary(for: [.sample(price: 249.99)]).shipping == ShippingPolicy.fee)
        #expect(CartPricing.summary(for: [.sample(price: 250)]).shipping == 0)
        #expect(CartPricing.summary(for: [.sample(price: 125, quantity: 3)]).shipping == 0)
    }

    @Test func totalIsSubtotalPlusTaxPlusShipping() {
        let summary = CartPricing.summary(for: [.sample(price: 100)])
        #expect(summary.subtotal == 100)
        #expect(summary.tax == 20)
        #expect(summary.shipping == 29.90)
        #expect(summary.total == 149.90)
    }

    @Test func quantityIsClampedToLimits() {
        #expect(CartLimits.clamp(0) == CartLimits.minQuantity)
        #expect(CartLimits.clamp(-5) == CartLimits.minQuantity)
        #expect(CartLimits.clamp(5) == 5)
        #expect(CartLimits.clamp(1000) == CartLimits.maxQuantity)
    }
}

@MainActor
struct SwiftDataCartManagementTests {
    private struct Harness {
        let container: ModelContainer
        let sut: SwiftDataCartRepository
        let user: UserBox
    }

    private final class UserBox { var id: UUID?; init(_ id: UUID?) { self.id = id } }

    private func makeHarness(user: UUID? = UUID()) throws -> Harness {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CartItemEntity.self, configurations: config)
        let box = UserBox(user)
        return Harness(container: container, sut: SwiftDataCartRepository(context: container.mainContext, userIDProvider: { box.id }), user: box)
    }

    @Test func setQuantityUpdatesExistingItem() async throws {
        let h = try makeHarness()
        try await h.sut.add(.sample(id: "a"))
        try await h.sut.setQuantity(4, for: "a")
        #expect(await h.sut.items().map(\.quantity) == [4])
    }

    @Test func setQuantityClampsToMinAndMax() async throws {
        let h = try makeHarness()
        try await h.sut.add(.sample(id: "a"))
        try await h.sut.setQuantity(0, for: "a")
        #expect(await h.sut.items().first?.quantity == CartLimits.minQuantity)
        try await h.sut.setQuantity(10_000, for: "a")
        #expect(await h.sut.items().first?.quantity == CartLimits.maxQuantity)
    }

    @Test func setQuantityOnMissingItemIsNoOp() async throws {
        let h = try makeHarness()
        try await h.sut.setQuantity(3, for: "ghost")
        #expect(await h.sut.items().isEmpty)
    }

    @Test func addAfterSetQuantityStaysIdempotent() async throws {
        let h = try makeHarness()
        try await h.sut.add(.sample(id: "a"))
        try await h.sut.setQuantity(3, for: "a")
        try await h.sut.add(.sample(id: "a"))
        #expect(await h.sut.items().map(\.quantity) == [3])
    }

    @Test func removeDeletesOnlyThatItem() async throws {
        let h = try makeHarness()
        try await h.sut.add(.sample(id: "a"))
        try await h.sut.add(.sample(id: "b"))
        try await h.sut.remove("a")
        #expect(await h.sut.items().map(\.bookID) == ["b"])
    }

    @Test func clearRemovesOnlyCurrentUsersItems() async throws {
        let h = try makeHarness()
        let first = h.user.id
        try await h.sut.add(.sample(id: "a"))
        h.user.id = UUID()
        try await h.sut.add(.sample(id: "b"))
        try await h.sut.clear()
        #expect(await h.sut.items().isEmpty)
        h.user.id = first
        #expect(await h.sut.items().map(\.bookID) == ["a"])
    }

    @Test func mutationsAreScopedPerUser() async throws {
        let h = try makeHarness()
        let first = h.user.id
        try await h.sut.add(.sample(id: "a"))
        h.user.id = UUID()
        try await h.sut.setQuantity(9, for: "a")
        try await h.sut.remove("a")
        h.user.id = first
        #expect(await h.sut.items().map(\.quantity) == [1])
    }

    @Test func mutationsWithoutUserFail() async throws {
        let h = try makeHarness(user: nil)
        await #expect(throws: AppError.unknown) { try await h.sut.setQuantity(2, for: "a") }
        await #expect(throws: AppError.unknown) { try await h.sut.remove("a") }
        await #expect(throws: AppError.unknown) { try await h.sut.clear() }
    }
}

@MainActor
struct CartUseCaseTests {
    @Test func getReturnsRepositoryItems() async {
        let repo = FakeCartManagedRepository(items: [.sample(id: "a")])
        #expect(await GetCartUseCase(repository: repo)().map(\.bookID) == ["a"])
    }

    @Test func updateQuantityDelegates() async throws {
        let repo = FakeCartManagedRepository(items: [.sample(id: "a")])
        try await UpdateCartQuantityUseCase(repository: repo)(bookID: "a", quantity: 5)
        #expect(repo.stored.first?.quantity == 5)
    }

    @Test func removeDelegates() async throws {
        let repo = FakeCartManagedRepository(items: [.sample(id: "a"), .sample(id: "b")])
        try await RemoveFromCartUseCase(repository: repo)(bookID: "a")
        #expect(repo.stored.map(\.bookID) == ["b"])
    }

    @Test func clearDelegates() async throws {
        let repo = FakeCartManagedRepository(items: [.sample(id: "a")])
        try await ClearCartUseCase(repository: repo)()
        #expect(repo.stored.isEmpty)
    }

    @Test func errorsPropagate() async {
        let repo = FakeCartManagedRepository(items: [.sample()])
        repo.shouldFail = true
        await #expect(throws: AppError.unknown) { try await UpdateCartQuantityUseCase(repository: repo)(bookID: "a", quantity: 2) }
        await #expect(throws: AppError.unknown) { try await RemoveFromCartUseCase(repository: repo)(bookID: "a") }
        await #expect(throws: AppError.unknown) { try await ClearCartUseCase(repository: repo)() }
    }
}

@MainActor
struct CartStoreManagementTests {
    @Test func badgeCountSumsQuantitiesAfterSetQuantity() async throws {
        let repo = FakeCartManagedRepository(items: [.sample(id: "a"), .sample(id: "b")])
        let sut = CartStore(repository: repo)
        await sut.reload()
        #expect(sut.count == 2)
        try await sut.setQuantity(4, for: "a")
        #expect(sut.count == 5)
        #expect(sut.quantity(for: "a") == 4)
    }

    @Test func removeUpdatesCountAndContains() async throws {
        let repo = FakeCartManagedRepository(items: [.sample(id: "a", quantity: 3), .sample(id: "b")])
        let sut = CartStore(repository: repo)
        await sut.reload()
        try await sut.remove("a")
        #expect(sut.count == 1)
        #expect(!sut.contains("a"))
    }

    @Test func clearEmptiesStore() async throws {
        let repo = FakeCartManagedRepository(items: [.sample(id: "a", quantity: 3)])
        let sut = CartStore(repository: repo)
        await sut.reload()
        try await sut.clear()
        #expect(sut.count == 0)
        #expect(sut.items.isEmpty)
    }

    @Test func failedMutationThrowsAndLeavesStateUntouched() async {
        let repo = FakeCartManagedRepository(items: [.sample(id: "a")])
        let sut = CartStore(repository: repo)
        await sut.reload()
        repo.shouldFail = true
        await #expect(throws: AppError.unknown) { try await sut.setQuantity(7, for: "a") }
        #expect(sut.count == 1)
    }
}

@MainActor
struct CartViewModelTests {
    private func makeSUT(items: [CartItem] = []) -> (CartViewModel, FakeCartManagedRepository, CartStore) {
        let repo = FakeCartManagedRepository(items: items)
        let store = CartStore(repository: repo)
        return (CartViewModel(cart: store), repo, store)
    }

    @Test func startsIdleThenLoadsItems() async {
        let (sut, _, _) = makeSUT(items: [.sample(id: "a")])
        #expect(sut.content == .idle)
        await sut.send(.onAppear)
        #expect(sut.content == .loaded([.sample(id: "a")]))
    }

    @Test func emptyCartIsLoadedEmptyAndCannotCheckout() async {
        let (sut, _, _) = makeSUT()
        await sut.send(.onAppear)
        #expect(sut.content == .loaded([]))
        #expect(!sut.canCheckout)
        #expect(sut.summary == CartSummary(subtotal: 0, tax: 0, shipping: 0))
    }

    @Test func contentReflectsChangesMadeElsewhere() async {
        let (sut, _, store) = makeSUT()
        await sut.send(.onAppear)
        await store.add(.sample(id: "x"))
        #expect(sut.content.value?.map(\.bookID) == ["x"])
    }

    @Test func incrementAndDecrementChangeQuantity() async {
        let (sut, _, store) = makeSUT(items: [.sample(id: "a")])
        await sut.send(.onAppear)
        await sut.send(.increment("a"))
        await sut.send(.increment("a"))
        #expect(store.quantity(for: "a") == 3)
        await sut.send(.decrement("a"))
        #expect(store.quantity(for: "a") == 2)
        #expect(store.count == 2)
    }

    @Test func decrementNeverGoesBelowOne() async {
        let (sut, repo, store) = makeSUT(items: [.sample(id: "a")])
        await sut.send(.onAppear)
        await sut.send(.decrement("a"))
        #expect(store.quantity(for: "a") == 1)
        #expect(repo.setQuantityCalls.isEmpty)
    }

    @Test func incrementStopsAtMaximum() async {
        let (sut, _, store) = makeSUT(items: [.sample(id: "a", quantity: CartLimits.maxQuantity)])
        await sut.send(.onAppear)
        await sut.send(.increment("a"))
        #expect(store.quantity(for: "a") == CartLimits.maxQuantity)
    }

    @Test func removalNeedsConfirmationAndNoKeepsItem() async {
        let (sut, _, store) = makeSUT(items: [.sample(id: "a")])
        await sut.send(.onAppear)
        await sut.send(.requestRemove("a"))
        #expect(sut.state.pendingRemovalID == "a")
        #expect(store.contains("a"))
        await sut.send(.cancelRemove)
        #expect(sut.state.pendingRemovalID == nil)
        #expect(store.contains("a"))
    }

    @Test func confirmingRemovalDeletesItemAndClearsPending() async {
        let (sut, _, store) = makeSUT(items: [.sample(id: "a"), .sample(id: "b")])
        await sut.send(.onAppear)
        await sut.send(.requestRemove("a"))
        await sut.send(.confirmRemove("a"))
        #expect(sut.state.pendingRemovalID == nil)
        #expect(sut.content.value?.map(\.bookID) == ["b"])
        #expect(store.count == 1)
    }

    @Test func removingLastItemShowsEmptyCart() async {
        let (sut, _, _) = makeSUT(items: [.sample(id: "a")])
        await sut.send(.onAppear)
        await sut.send(.confirmRemove("a"))
        #expect(sut.content == .loaded([]))
    }

    @Test func summaryFollowsItemsAndQuantities() async {
        let (sut, _, _) = makeSUT(items: [.sample(id: "a", price: 100), .sample(id: "b", price: 50)])
        await sut.send(.onAppear)
        #expect(sut.summary.subtotal == 150)
        await sut.send(.increment("b"))
        #expect(sut.summary.subtotal == 200)
        #expect(sut.summary.tax == 40)
        #expect(sut.summary.shipping == ShippingPolicy.fee)
        #expect(sut.summary.total == 200 + 40 + ShippingPolicy.fee)
        #expect(sut.canCheckout)
    }

    @Test func failedMutationSetsErrorAndKeepsQuantity() async {
        let (sut, repo, store) = makeSUT(items: [.sample(id: "a")])
        await sut.send(.onAppear)
        repo.shouldFail = true
        await sut.send(.increment("a"))
        #expect(sut.state.error == .unknown)
        #expect(store.quantity(for: "a") == 1)
        await sut.send(.dismissError)
        #expect(sut.state.error == nil)
    }

    @Test func retryClearsErrorAndReloads() async {
        let (sut, repo, _) = makeSUT(items: [.sample(id: "a")])
        await sut.send(.onAppear)
        repo.shouldFail = true
        await sut.send(.confirmRemove("a"))
        #expect(sut.state.error != nil)
        repo.shouldFail = false
        await sut.send(.retry)
        #expect(sut.state.error == nil)
        #expect(sut.content == .loaded([.sample(id: "a")]))
    }

    @Test func onAppearDoesNotReloadWhenAlreadyLoaded() async {
        let (sut, repo, store) = makeSUT(items: [.sample(id: "a")])
        await sut.send(.onAppear)
        try? await repo.remove("a")
        await sut.send(.onAppear)
        #expect(store.contains("a"))
    }
}
