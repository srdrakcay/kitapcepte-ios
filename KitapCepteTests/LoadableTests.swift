import Testing
@testable import KitapCepte

struct LoadableTests {
    @Test func valueIsAvailableOnlyWhenLoaded() {
        #expect(Loadable.loaded(3).value == 3)
        #expect(Loadable<Int>.idle.value == nil)
        #expect(Loadable<Int>.loading.value == nil)
    }

    @Test func isLoadingOnlyForLoadingCase() {
        #expect(Loadable<Int>.loading.isLoading)
        #expect(!Loadable<Int>.idle.isLoading)
    }

    @Test func exposesErrorWhenFailed() {
        #expect(Loadable<Int>.failed(.network).error == .network)
        #expect(Loadable.loaded(1).error == nil)
    }
}
