import Observation

@MainActor @Observable
final class RegisterViewModel {
    struct State: Equatable {
        var name = ""
        var email = ""
        var password = ""
        var confirmation = ""
        var errors: [AuthField: String] = [:]
        var formError: String?
        var isLoading = false
    }

    enum Action {
        case nameChanged(String)
        case emailChanged(String)
        case passwordChanged(String)
        case confirmationChanged(String)
    }

    private(set) var state = State()
    private let register: RegisterUseCase
    private let onAuthenticated: (User) -> Void

    init(register: RegisterUseCase, onAuthenticated: @escaping (User) -> Void) {
        self.register = register
        self.onAuthenticated = onAuthenticated
    }

    func send(_ action: Action) {
        switch action {
        case .nameChanged(let value):
            state.name = value
            state.errors[.name] = nil
        case .emailChanged(let value):
            state.email = value
            state.errors[.email] = nil
        case .passwordChanged(let value):
            state.password = value
            state.errors[.password] = nil
        case .confirmationChanged(let value):
            state.confirmation = value
            state.errors[.confirmPassword] = nil
        }
    }

    func submit() async {
        guard !state.isLoading else { return }
        state.isLoading = true
        state.errors = [:]
        state.formError = nil
        do {
            let user = try await register(
                name: state.name, email: state.email,
                password: state.password, confirmation: state.confirmation
            )
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
