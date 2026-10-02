import SwiftUI

struct RootView: View {
    private let container: AppContainer
    @State private var viewModel: RootViewModel
    @State private var onboardingViewModel: OnboardingViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: container.makeRootViewModel())
        _onboardingViewModel = State(initialValue: container.makeOnboardingViewModel())
    }

    var body: some View {
        Group {
            switch viewModel.route {
            case .onboarding:
                OnboardingView(viewModel: onboardingViewModel, onFinish: viewModel.onboardingCompleted)
            case .launching:
                AppScaffold { LoadingView() }
            case .auth:
                AuthView(
                    startsAtLogin: container.sessionManager.opensLoginDirectly,
                    makeLoginViewModel: container.makeLoginViewModel,
                    makeRegisterViewModel: container.makeRegisterViewModel,
                    onContinueAsGuest: container.sessionManager.continueAsGuest
                )
            case .main:
                MainView(
                    viewModel: container.makeMainViewModel(),
                    homeViewModel: container.makeHomeViewModel(),
                    cartViewModel: container.makeCartViewModel(), // MARK: Faz 6
                    makeDetailViewModel: container.makeDetailViewModel
                )
            }
        }
        .environment(container.sessionManager)
        .environment(container.guestGate)
        .environment(container.favoritesStore)
        .environment(container.cartStore)
        .guestGateSheet(container.guestGate)
        .task { await container.sessionManager.restore() }
    }
}

#Preview { RootView(container: .live()) }
