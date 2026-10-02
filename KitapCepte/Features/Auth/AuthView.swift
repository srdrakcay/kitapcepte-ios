import SwiftUI

enum AuthRoute: Hashable {
    case login
    case register
}

struct AuthView: View {
    @Environment(\.appTheme) private var theme
    @State private var path: [AuthRoute]
    let makeLoginViewModel: () -> LoginViewModel
    let makeRegisterViewModel: () -> RegisterViewModel
    let onContinueAsGuest: () -> Void

    init(
        startsAtLogin: Bool = false,
        makeLoginViewModel: @escaping () -> LoginViewModel,
        makeRegisterViewModel: @escaping () -> RegisterViewModel,
        onContinueAsGuest: @escaping () -> Void
    ) {
        _path = State(initialValue: startsAtLogin ? [.login] : [])
        self.makeLoginViewModel = makeLoginViewModel
        self.makeRegisterViewModel = makeRegisterViewModel
        self.onContinueAsGuest = onContinueAsGuest
    }

    var body: some View {
        NavigationStack(path: $path) {
            welcome
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .login:
                        LoginView(viewModel: makeLoginViewModel(), onRegister: { path.append(.register) })
                    case .register:
                        RegisterView(viewModel: makeRegisterViewModel(), onLogin: { path.removeLast() })
                    }
                }
        }
        .tint(theme.colors.textOnPrimary)
    }

    private var welcome: some View {
        AppScaffold {
            VStack(spacing: theme.dimens.spacingXL) {
                Spacer()
                Image(systemName: "book.closed.fill")
                    .font(.system(size: theme.dimens.iconL * 2))
                    .foregroundStyle(theme.colors.primary)
                    .frame(width: theme.dimens.iconL * 4, height: theme.dimens.iconL * 4)
                    .background(theme.colors.surfaceWhite, in: Circle())
                    .accessibilityHidden(true)
                VStack(spacing: theme.dimens.spacingS) {
                    Text(Strings.App.name)
                        .font(theme.typography.largeTitle)
                        .foregroundStyle(theme.colors.textOnPrimary)
                    Text(Strings.Auth.welcomeSubtitle)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textOnGradientSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                VStack(spacing: theme.dimens.spacingM) {
                    AppButton(title: Strings.Auth.loginWithMail) { path.append(.login) }
                    AppButton(title: Strings.Auth.continueAsGuest, kind: .secondary, action: onContinueAsGuest)
                }
            }
            .padding(theme.dimens.spacingXL)
        }
    }
}
