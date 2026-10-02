import SwiftUI

struct RegisterView: View {
    @State private var viewModel: RegisterViewModel
    let onLogin: () -> Void

    init(viewModel: RegisterViewModel, onLogin: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onLogin = onLogin
    }

    var body: some View {
        let state = viewModel.state
        AuthFormScreen(title: Strings.Auth.registerTitle) {
            AppTextField(
                label: Strings.Field.name,
                text: Binding(get: { state.name }, set: { viewModel.send(.nameChanged($0)) }),
                systemImage: "person",
                errorMessage: state.errors[.name]
            )
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
            AppSecureField(
                label: Strings.Field.confirmPassword,
                text: Binding(get: { state.confirmation }, set: { viewModel.send(.confirmationChanged($0)) }),
                errorMessage: state.errors[.confirmPassword]
            )
            if let formError = state.formError { AppErrorBanner(message: formError) }
            AppButton(title: Strings.Auth.registerSubmit, isLoading: state.isLoading) {
                Task { await viewModel.submit() }
            }
            AppButton(title: Strings.Auth.haveAccount, kind: .text, action: onLogin)
        }
    }
}
