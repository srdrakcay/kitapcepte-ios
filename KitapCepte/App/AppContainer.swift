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
    let favoritesRepository: FavoritesRepository // MARK: Faz 5
    let cartStore: CartStore
    let savedCardsStore: SavedCardsStore // MARK: Faz 7
    let paymentGateway: PaymentGateway // MARK: Faz 7
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
        let cartRepository = SwiftDataCartRepository(
            context: context,
            userIDProvider: { [weak sessionManager] in sessionManager?.currentUser?.id }
        )
        let savedCardRepository = SwiftDataSavedCardRepository(
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
            favoritesRepository: favoritesRepository, // MARK: Faz 5
            cartStore: CartStore(repository: cartRepository),
            savedCardsStore: SavedCardsStore(repository: savedCardRepository), // MARK: Faz 7
            paymentGateway: SimulatedPaymentGateway(), // MARK: Faz 7
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

    // MARK: Faz 5
    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(getFavorites: GetFavoritesUseCase(repository: favoritesRepository), favorites: favoritesStore)
    }

    // MARK: Faz 8a
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            userProvider: { [sessionManager] in sessionManager.currentUser },
            changePassword: ChangePasswordUseCase(repository: authRepository),
            signOut: { [sessionManager] in await sessionManager.signOut() }
        )
    }

    func makeDetailViewModel(book: Book) -> DetailViewModel {
        DetailViewModel(
            book: book,
            getDescription: GetBookDescriptionUseCase(repository: bookRepository),
            getSimilarBooks: GetSimilarBooksUseCase(repository: bookRepository),
            favorites: favoritesStore,
            cart: cartStore,
            gate: guestGate
        )
    }

    // MARK: Faz 6
    func makeCartViewModel() -> CartViewModel {
        CartViewModel(cart: cartStore)
    }


    // MARK: Faz 7
    func makePaymentViewModel() -> PaymentViewModel {
        PaymentViewModel(
            pay: PayUseCase(validator: CardValidator(), gateway: paymentGateway, cart: cartStore, savedCards: savedCardsStore),
            cart: cartStore
        )
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([AccountEntity.self, FavoriteEntity.self, CartItemEntity.self, SavedCardEntity.self])
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
