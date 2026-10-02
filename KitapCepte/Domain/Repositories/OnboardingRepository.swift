/// Onboarding'in daha önce görülüp görülmediğini tutar.
protocol OnboardingRepository: AnyObject, Sendable {
    var hasSeenOnboarding: Bool { get }
    func markOnboardingSeen()
}
