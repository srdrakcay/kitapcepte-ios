import SwiftUI

/// Login ve Register'ın ortak iskeleti: başlık + açık zeminli form kartı.
struct AuthFormScreen<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        AppScaffold {
            ScrollView {
                VStack(spacing: theme.dimens.spacingXL) {
                    Text(title)
                        .font(theme.typography.largeTitle)
                        .foregroundStyle(theme.colors.textOnPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                    AppFormCard { content }
                }
                .padding(theme.dimens.spacingL)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}
