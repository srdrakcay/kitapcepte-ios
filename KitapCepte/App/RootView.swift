import SwiftUI

struct RootView: View {
    @State private var viewModel: RootViewModel
    @State private var onboardingViewModel: OnboardingViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeRootViewModel())
        _onboardingViewModel = State(initialValue: container.makeOnboardingViewModel())
    }

    var body: some View {
        switch viewModel.route {
        case .onboarding:
            OnboardingView(viewModel: onboardingViewModel, onFinish: viewModel.onboardingCompleted)
        case .auth:
            AuthPlaceholderView()
        }
    }
}

#Preview { RootView(container: .live()) }
