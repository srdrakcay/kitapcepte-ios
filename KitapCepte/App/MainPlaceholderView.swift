import SwiftUI

/// Faz 3'te Home + tab bar ile değişir. Oturum ve GuestGate akışını doğrulamak için geçici ekran.
struct MainPlaceholderView: View {
    @Environment(\.appTheme) private var theme
    @Environment(SessionManager.self) private var sessionManager
    @Environment(GuestGate.self) private var gate

    var body: some View {
        AppScaffold {
            VStack(spacing: theme.dimens.spacingL) {
                Text(sessionManager.currentUser.map { Strings.Main.greeting($0.name) } ?? Strings.Main.guest)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textOnPrimary)
                AppButton(title: Strings.Main.restricted, kind: .secondary) { gate.require {} }
                AppButton(title: Strings.Main.signOut, kind: .text) {
                    Task { await sessionManager.signOut() }
                }
            }
            .padding(theme.dimens.spacingXL)
        }
    }
}
