import Observation

enum RootRoute: Equatable {
    case onboarding
    case auth
}

@MainActor @Observable
final class RootViewModel {
    private(set) var route: RootRoute

    init(onboardingRepository: OnboardingRepository) {
        route = onboardingRepository.hasSeenOnboarding ? .auth : .onboarding
    }

    func onboardingCompleted() {
        route = .auth
    }
}
