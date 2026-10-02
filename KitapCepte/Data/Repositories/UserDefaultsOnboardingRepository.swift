import Foundation

final class UserDefaultsOnboardingRepository: OnboardingRepository, @unchecked Sendable {
    static let storageKey = "hasSeenOnboarding"
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var hasSeenOnboarding: Bool {
        defaults.bool(forKey: Self.storageKey)
    }

    func markOnboardingSeen() {
        defaults.set(true, forKey: Self.storageKey)
    }
}
