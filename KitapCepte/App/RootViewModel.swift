import Observation

enum RootRoute: Equatable {
    case onboarding
    case launching
    case auth
    case main
}

@MainActor @Observable
final class RootViewModel {
    private var hasSeenOnboarding: Bool
    private let sessionManager: SessionManager

    init(onboardingRepository: OnboardingRepository, sessionManager: SessionManager) {
        hasSeenOnboarding = onboardingRepository.hasSeenOnboarding
        self.sessionManager = sessionManager
    }

    var route: RootRoute {
        if !hasSeenOnboarding { return .onboarding }
        if sessionManager.isRestoring { return .launching }
        return sessionManager.session == .none ? .auth : .main
    }

    func onboardingCompleted() {
        hasSeenOnboarding = true
    }
}
