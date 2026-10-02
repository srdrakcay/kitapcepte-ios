import Foundation
import SwiftData

/// Bağımlılıkların oluşturulduğu tek yer (constructor injection).
@MainActor
struct AppContainer {
    let theme: AppTheme
    let onboardingRepository: OnboardingRepository
    let authRepository: AuthRepository
    let sessionManager: SessionManager
    let guestGate: GuestGate
    let modelContainer: ModelContainer

    static func live() -> AppContainer {
        let modelContainer = makeModelContainer()
        let authRepository = SwiftDataAuthRepository(
            context: modelContainer.mainContext,
            secureStore: KeychainStore(service: Bundle.main.bundleIdentifier ?? "com.kitapcepte.app")
        )
        return make(
            onboardingRepository: UserDefaultsOnboardingRepository(defaults: .standard),
            authRepository: authRepository,
            modelContainer: modelContainer
        )
    }

    static func make(
        onboardingRepository: OnboardingRepository,
        authRepository: AuthRepository,
        modelContainer: ModelContainer
    ) -> AppContainer {
        let sessionManager = SessionManager(repository: authRepository)
        return AppContainer(
            theme: .standard,
            onboardingRepository: onboardingRepository,
            authRepository: authRepository,
            sessionManager: sessionManager,
            guestGate: GuestGate(sessionManager: sessionManager),
            modelContainer: modelContainer
        )
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel(onboardingRepository: onboardingRepository, sessionManager: sessionManager)
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(repository: onboardingRepository)
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(login: LoginUseCase(repository: authRepository), onAuthenticated: sessionManager.signedIn)
    }

    func makeRegisterViewModel() -> RegisterViewModel {
        RegisterViewModel(register: RegisterUseCase(repository: authRepository), onAuthenticated: sessionManager.signedIn)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([AccountEntity.self])
        if let container = try? ModelContainer(for: schema) { return container }
        // Disk deposu açılamazsa uygulama bellek içi depoyla çalışmaya devam eder.
        let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: fallback)
        } catch {
            preconditionFailure("SwiftData container could not be created: \(error)")
        }
    }
}
