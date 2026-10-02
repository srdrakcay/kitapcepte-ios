import SwiftUI

/// Ortada başlık, solda/sağda opsiyonel öğeler. Varyantlar: `.home`, `.detail`, ileride sepet.
struct AppTopBar<Leading: View, Trailing: View>: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let leading: Leading
    let trailing: Trailing

    init(title: String, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textOnPrimary)
                .lineLimit(1)
                // Başlık, iki yandaki butonlarla çakışmasın.
                .padding(.horizontal, theme.dimens.minTouchTarget)
                .accessibilityAddTraits(.isHeader)
            HStack {
                leading
                Spacer()
                trailing
            }
        }
        .padding(.horizontal, theme.dimens.spacingL)
        .frame(minHeight: theme.dimens.minTouchTarget)
    }
}

extension AppTopBar where Leading == EmptyView {
    init(title: String, @ViewBuilder trailing: () -> Trailing) {
        self.init(title: title, leading: { EmptyView() }, trailing: trailing)
    }
}

extension AppTopBar where Leading == EmptyView, Trailing == AppIconButton {
    /// Home varyantı: ortada uygulama adı, sağda profil.
    static func home(onProfile: @escaping () -> Void) -> AppTopBar {
        AppTopBar(title: Strings.App.name) {
            AppIconButton(systemImage: "person.fill", accessibilityLabel: Strings.Accessibility.profile, action: onProfile)
        }
    }
}

extension AppTopBar where Leading == AppIconButton, Trailing == FavoriteButton {
    /// Detay varyantı: solda geri, ortada başlık, sağda favori.
    static func detail(
        title: String, isFavorite: Bool, onBack: @escaping () -> Void, onToggleFavorite: @escaping () -> Void
    ) -> AppTopBar {
        AppTopBar(
            title: title,
            leading: { AppIconButton(systemImage: "chevron.left", accessibilityLabel: Strings.Accessibility.back, action: onBack) },
            trailing: { FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite) }
        )
    }
}
