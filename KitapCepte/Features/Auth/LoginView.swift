import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    let onRegister: () -> Void

    init(viewModel: LoginViewModel, onRegister: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onRegister = onRegister
    }

    var body: some View {
        let state = viewModel.state
        AuthFormScreen(title: Strings.Auth.loginTitle) {
            AppTextField(
                label: Strings.Field.email,
                text: Binding(get: { state.email }, set: { viewModel.send(.emailChanged($0)) }),
                systemImage: "envelope",
                errorMessage: state.errors[.email],
                keyboard: .emailAddress
            )
            AppSecureField(
                label: Strings.Field.password,
                text: Binding(get: { state.password }, set: { viewModel.send(.passwordChanged($0)) }),
                errorMessage: state.errors[.password]
            )
            if let formError = state.formError { AppErrorBanner(message: formError) }
            AppButton(title: Strings.Auth.loginSubmit, isLoading: state.isLoading) {
                Task { await viewModel.submit() }
            }
            AppButton(title: Strings.Auth.noAccount, kind: .text, action: onRegister)
        }
    }
}
