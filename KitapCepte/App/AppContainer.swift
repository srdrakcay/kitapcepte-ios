import Foundation
import SwiftData

/// Bağımlılıkların oluşturulduğu tek yer (constructor injection).
@MainActor
struct AppContainer {
    let theme: AppTheme
    let onboardingRepository: OnboardingRepository
    let authRepository: AuthRepository
    let bookRepository: BookRepository
    let sessionManager: SessionManager
    let guestGate: GuestGate
    let favoritesStore: FavoritesStore
    let modelContainer: ModelContainer

    static func live() -> AppContainer {
        let modelContainer = makeModelContainer()
        let context = modelContainer.mainContext
        let authRepository = SwiftDataAuthRepository(
            context: context,
            secureStore: KeychainStore(service: Bundle.main.bundleIdentifier ?? "com.kitapcepte.app")
        )
        let sessionManager = SessionManager(repository: authRepository)
        let favoritesRepository = SwiftDataFavoritesRepository(
            context: context,
            userIDProvider: { [weak sessionManager] in sessionManager?.currentUser?.id }
        )
        let apiClient = URLSessionAPIClient(session: .shared)
        return AppContainer(
            theme: .standard,
            onboardingRepository: UserDefaultsOnboardingRepository(defaults: .standard),
            authRepository: authRepository,
            bookRepository: BookRepositoryImpl(service: OpenLibraryService(client: apiClient)),
            sessionManager: sessionManager,
            guestGate: GuestGate(sessionManager: sessionManager),
            favoritesStore: FavoritesStore(repository: favoritesRepository),
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

    func makeMainViewModel() -> MainViewModel {
        MainViewModel(gate: guestGate)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(getBooks: GetBooksUseCase(repository: bookRepository))
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([AccountEntity.self, FavoriteEntity.self])
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
