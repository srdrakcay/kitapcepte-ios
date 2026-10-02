import Observation

@MainActor @Observable
final class LoginViewModel {
    struct State: Equatable {
        var email = ""
        var password = ""
        var errors: [AuthField: String] = [:]
        var formError: String?
        var isLoading = false
    }

    enum Action {
        case emailChanged(String)
        case passwordChanged(String)
    }

    private(set) var state = State()
    private let login: LoginUseCase
    private let onAuthenticated: (User) -> Void

    init(login: LoginUseCase, onAuthenticated: @escaping (User) -> Void) {
        self.login = login
        self.onAuthenticated = onAuthenticated
    }

    func send(_ action: Action) {
        switch action {
        case .emailChanged(let value):
            state.email = value
            state.errors[.email] = nil
        case .passwordChanged(let value):
            state.password = value
            state.errors[.password] = nil
        }
    }

    func submit() async {
        guard !state.isLoading else { return }
        state.isLoading = true
        state.errors = [:]
        state.formError = nil
        do {
            let user = try await login(email: state.email, password: state.password)
            state.isLoading = false
            onAuthenticated(user)
        } catch {
            let failure = AuthFailure(error)
            state.errors = failure.fieldErrors
            state.formError = failure.formError
            state.isLoading = false
        }
    }
}
