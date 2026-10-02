import SwiftUI

struct OnboardingView: View {
    @Environment(\.appTheme) private var theme
    @State private var viewModel: OnboardingViewModel
    private let onFinish: () -> Void

    init(viewModel: OnboardingViewModel, onFinish: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        let state = viewModel.state
        AppScaffold {
            VStack(spacing: theme.dimens.spacingL) {
                HStack {
                    Spacer()
                    AppButton(title: Strings.Onboarding.skip, kind: .text) { viewModel.send(.skip) }
                        .frame(width: theme.dimens.iconL * 3)
                        .opacity(state.isLastPage ? 0 : 1)
                        .disabled(state.isLastPage)
                }
                .padding(.horizontal, theme.dimens.spacingL)

                TabView(selection: Binding(
                    get: { state.currentIndex },
                    set: { viewModel.send(.pageChanged($0)) }
                )) {
                    ForEach(state.pages) { page in
                        OnboardingPageView(page: page).tag(page.id)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                AppButton(
                    title: state.isLastPage ? Strings.Onboarding.start : Strings.Onboarding.next
                ) { viewModel.send(.next) }
                    .padding(.horizontal, theme.dimens.spacingXL)
                    .padding(.bottom, theme.dimens.spacingL)
            }
        }
        .animation(.easeInOut(duration: theme.dimens.animationDuration), value: state.currentIndex)
        .onChange(of: state.isFinished) { _, finished in
            if finished { onFinish() }
        }
    }
}

private struct OnboardingPageView: View {
    @Environment(\.appTheme) private var theme
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: theme.dimens.spacingXL) {
            Image(systemName: page.systemImage)
                .font(.system(size: theme.dimens.iconL * 2))
                .foregroundStyle(theme.colors.primary)
                .frame(width: theme.dimens.iconL * 5, height: theme.dimens.iconL * 5)
                .background(theme.colors.surfaceWhite, in: Circle())
                .accessibilityHidden(true)
            Text(page.title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textOnPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(page.message)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textOnGradientSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, theme.dimens.spacingXL)
        .padding(.bottom, theme.dimens.iconL)
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(repository: UserDefaultsOnboardingRepository(defaults: .standard)),
        onFinish: {}
    )
}
