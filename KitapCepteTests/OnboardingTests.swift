import Foundation
import Testing
@testable import KitapCepte

final class FakeOnboardingRepository: OnboardingRepository, @unchecked Sendable {
    var hasSeenOnboarding: Bool
    private(set) var markCount = 0

    init(hasSeen: Bool = false) { hasSeenOnboarding = hasSeen }

    func markOnboardingSeen() {
        hasSeenOnboarding = true
        markCount += 1
    }
}

@MainActor
struct OnboardingViewModelTests {
    private func makeSUT(seen: Bool = false) -> (OnboardingViewModel, FakeOnboardingRepository) {
        let repo = FakeOnboardingRepository(hasSeen: seen)
        return (OnboardingViewModel(repository: repo), repo)
    }

    @Test func startsOnFirstPage() {
        let (sut, _) = makeSUT()
        #expect(sut.state.currentIndex == 0)
        #expect(sut.state.pages.count == 3)
        #expect(!sut.state.isLastPage)
    }

    @Test func nextAdvancesPage() {
        let (sut, repo) = makeSUT()
        sut.send(.next)
        #expect(sut.state.currentIndex == 1)
        #expect(repo.markCount == 0)
    }

    @Test func nextOnLastPageFinishesAndMarksSeen() {
        let (sut, repo) = makeSUT()
        sut.send(.next); sut.send(.next)
        #expect(sut.state.isLastPage)
        sut.send(.next)
        #expect(sut.state.isFinished)
        #expect(repo.hasSeenOnboarding)
    }

    @Test func skipFinishesImmediately() {
        let (sut, repo) = makeSUT()
        sut.send(.skip)
        #expect(sut.state.isFinished)
        #expect(repo.markCount == 1)
    }

    @Test func pageChangedIgnoresOutOfRangeIndex() {
        let (sut, _) = makeSUT()
        sut.send(.pageChanged(2))
        #expect(sut.state.currentIndex == 2)
        sut.send(.pageChanged(9))
        #expect(sut.state.currentIndex == 2)
    }
}

@MainActor
struct RootViewModelTests {
    @Test func showsOnboardingOnFirstLaunch() {
        let sut = RootViewModel(onboardingRepository: FakeOnboardingRepository(hasSeen: false))
        #expect(sut.route == .onboarding)
    }

    @Test func skipsOnboardingWhenAlreadySeen() {
        let sut = RootViewModel(onboardingRepository: FakeOnboardingRepository(hasSeen: true))
        #expect(sut.route == .auth)
    }

    @Test func movesToAuthAfterOnboardingCompleted() {
        let sut = RootViewModel(onboardingRepository: FakeOnboardingRepository())
        sut.onboardingCompleted()
        #expect(sut.route == .auth)
    }
}

struct UserDefaultsOnboardingRepositoryTests {
    @Test func persistsSeenFlag() throws {
        let suite = "test.onboarding.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let sut = UserDefaultsOnboardingRepository(defaults: defaults)
        #expect(!sut.hasSeenOnboarding)
        sut.markOnboardingSeen()
        #expect(UserDefaultsOnboardingRepository(defaults: defaults).hasSeenOnboarding)
    }
}
