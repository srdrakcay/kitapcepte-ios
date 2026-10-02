import SwiftUI

/// Faz 0: boş iskelet. Sonraki fazlarda oturum durumuna göre Onboarding/Auth/Tab akışı burada seçilir.
struct RootView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        AppScaffold {
            Text(Strings.App.name)
                .font(theme.typography.largeTitle)
                .foregroundStyle(theme.colors.textOnPrimary)
        }
    }
}

#Preview { RootView() }
