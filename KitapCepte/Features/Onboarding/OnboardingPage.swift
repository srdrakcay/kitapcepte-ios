struct OnboardingPage: Identifiable, Equatable, Sendable {
    let id: Int
    let systemImage: String
    let title: String
    let message: String

    static var all: [OnboardingPage] {
        [
            OnboardingPage(id: 0, systemImage: "books.vertical.fill", title: Strings.Onboarding.page1Title, message: Strings.Onboarding.page1Message),
            OnboardingPage(id: 1, systemImage: "heart.fill", title: Strings.Onboarding.page2Title, message: Strings.Onboarding.page2Message),
            OnboardingPage(id: 2, systemImage: "person.crop.circle.badge.checkmark", title: Strings.Onboarding.page3Title, message: Strings.Onboarding.page3Message)
        ]
    }
}
