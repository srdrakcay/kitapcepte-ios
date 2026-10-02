import SwiftUI

/// Ortak bottom sheet içeriği. `LoginRequiredSheet` bunun üzerine kurulur.
struct AppSheetContent: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let message: String
    let primaryTitle: String
    let onPrimary: () -> Void
    var secondaryTitle: String?
    var onSecondary: (() -> Void)?

    var body: some View {
        VStack(spacing: theme.dimens.spacingL) {
            Text(title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
            Text(message)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            AppButton(title: primaryTitle, action: onPrimary)
            if let secondaryTitle, let onSecondary {
                AppButton(title: secondaryTitle, kind: .text, action: onSecondary)
            }
        }
        .padding(theme.dimens.spacingXL)
        .frame(maxWidth: .infinity)
        .background(theme.colors.surface)
    }
}

private struct AppSheetStyle: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(theme.colors.surface)
    }
}

extension View {
    /// Ortak bottom sheet.
    func appSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: isPresented) {
            content().modifier(AppSheetStyle())
        }
    }
}
