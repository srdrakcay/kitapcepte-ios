import SwiftUI

/// Misafir kullanıcı kısıtlı bir alana girdiğinde gösterilen ortak "üye ol" sheet'i.
struct LoginRequiredSheet: View {
    let onSignUp: () -> Void
    let onCancel: () -> Void

    var body: some View {
        AppSheetContent(
            title: Strings.Gate.title,
            message: Strings.Gate.message,
            primaryTitle: Strings.Gate.action,
            onPrimary: onSignUp,
            secondaryTitle: Strings.Common.cancel,
            onSecondary: onCancel
        )
    }
}

#Preview { LoginRequiredSheet(onSignUp: {}, onCancel: {}) }
