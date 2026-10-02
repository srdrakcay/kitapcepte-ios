import Observation

@MainActor @Observable
final class OnboardingViewModel {
    struct State: Equatable {
        var pages: [OnboardingPage]
        var currentIndex = 0
        var isFinished = false

        var isLastPage: Bool { currentIndex == pages.count - 1 }
    }

    enum Action {
        case next
        case skip
        case pageChanged(Int)
    }

    private(set) var state: State
    private let repository: OnboardingRepository

    init(repository: OnboardingRepository, pages: [OnboardingPage] = OnboardingPage.all) {
        self.repository = repository
        self.state = State(pages: pages)
    }

    func send(_ action: Action) {
        switch action {
        case .next:
            if state.isLastPage { finish() } else { state.currentIndex += 1 }
        case .skip:
            finish()
        case .pageChanged(let index):
            guard state.pages.indices.contains(index) else { return }
            state.currentIndex = index
        }
    }

    private func finish() {
        repository.markOnboardingSeen()
        state.isFinished = true
    }
}
