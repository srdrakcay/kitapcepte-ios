import Foundation

/// Bağımlılıkların oluşturulduğu tek yer (constructor injection).
struct AppContainer {
    let theme: AppTheme
    let onboardingRepository: OnboardingRepository

    static func live() -> AppContainer {
        AppContainer(
            theme: .standard,
            onboardingRepository: UserDefaultsOnboardingRepository(defaults: .standard)
        )
    }

    @MainActor func makeRootViewModel() -> RootViewModel {
        RootViewModel(onboardingRepository: onboardingRepository)
    }

    @MainActor func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(repository: onboardingRepository)
    }
}
