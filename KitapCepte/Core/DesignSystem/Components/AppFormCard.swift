import SwiftUI

/// Açık zeminli form/bölüm kartı (Auth formları ve Profil bölümleri paylaşır).
struct AppFormCard<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: theme.dimens.spacingL) { content }
            .padding(theme.dimens.spacingL)
            .frame(maxWidth: .infinity)
            .background(theme.colors.surface, in: theme.shapes.card)
    }
}
