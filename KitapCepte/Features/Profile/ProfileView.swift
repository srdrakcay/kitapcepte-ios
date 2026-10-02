import SwiftUI

struct ProfileView: View {
    @Environment(\.appTheme) private var theme
    @State private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: theme.dimens.spacingM) {
            AppTopBar(title: Strings.Profile.title) { EmptyView() }
            if let user = viewModel.user {
                ScrollView {
                    VStack(spacing: theme.dimens.spacingL) {
                        accountSection(user)
                        passwordSection(viewModel.state)
                        AppButton(title: Strings.Profile.signOutButton, kind: .secondary) {
                            viewModel.send(.signOutTapped)
                        }
                    }
                    .padding(.horizontal, theme.dimens.spacingL)
                    .padding(.bottom, theme.dimens.spacingL)
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                EmptyStateView(message: Strings.Profile.unavailable, systemImage: "person.crop.circle.badge.exclamationmark")
            }
        }
        .appSheet(isPresented: Binding(
            get: { viewModel.state.isConfirmingSignOut },
            set: { if !$0 { viewModel.send(.signOutDismissed) } }
        )) {
            AppSheetContent(
                title: Strings.Profile.signOutTitle,
                message: Strings.Profile.signOutMessage,
                primaryTitle: Strings.Profile.signOutConfirm,
                onPrimary: { Task { await viewModel.confirmSignOut() } },
                secondaryTitle: Strings.Profile.signOutCancel,
                onSecondary: { viewModel.send(.signOutDismissed) }
            )
        }
    }

    private func accountSection(_ user: User) -> some View {
        ProfileSection(title: Strings.Profile.accountTitle) {
            VStack(spacing: theme.dimens.spacingM) {
                Text(user.initials)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.primary)
                    .frame(width: theme.dimens.avatarSize, height: theme.dimens.avatarSize)
                    .background(theme.colors.primaryContainer, in: Circle())
                    .accessibilityHidden(true)
                Text(user.name)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(user.email)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private func passwordSection(_ state: ProfileViewModel.State) -> some View {
        ProfileSection(title: Strings.Profile.passwordTitle) {
            AppSecureField(
                label: Strings.Profile.fieldCurrent,
                text: Binding(get: { state.currentPassword }, set: { viewModel.send(.currentPasswordChanged($0)) }),
                errorMessage: state.errors[.currentPassword]
            )
            AppSecureField(
                label: Strings.Profile.fieldNew,
                text: Binding(get: { state.newPassword }, set: { viewModel.send(.newPasswordChanged($0)) }),
                errorMessage: state.errors[.newPassword]
            )
            AppSecureField(
                label: Strings.Profile.fieldConfirm,
                text: Binding(get: { state.confirmation }, set: { viewModel.send(.confirmationChanged($0)) }),
                errorMessage: state.errors[.confirmPassword]
            )
            if let formError = state.formError { AppErrorBanner(message: formError) }
            if let success = state.successMessage { successBanner(success) }
            AppButton(title: Strings.Profile.passwordSubmit, isLoading: state.isLoading) {
                Task { await viewModel.submit() }
            }
        }
    }

    private func successBanner(_ message: String) -> some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(theme.typography.callout)
            .foregroundStyle(theme.colors.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.dimens.spacingM)
            .background(theme.colors.surfaceWhite, in: theme.shapes.control)
    }
}

@MainActor
private final class PreviewAuthRepository: AuthRepository {
    func register(name: String, email: String, password: String) async throws -> User { throw AuthError.invalidCredentials }
    func login(email: String, password: String) async throws -> User { throw AuthError.invalidCredentials }
    func restoreSession() async -> User? { nil }
    func logout() async {}
    func changePassword(userID: UUID, current: String, new: String) async throws { throw AuthError.invalidCredentials }
}

#Preview {
    let viewModel = ProfileViewModel(
        userProvider: { User(id: UUID(), name: "Ada Lovelace", email: "ada@example.com") },
        changePassword: ChangePasswordUseCase(repository: PreviewAuthRepository()),
        signOut: {}
    )
    return AppScaffold { ProfileView(viewModel: viewModel) }
}
