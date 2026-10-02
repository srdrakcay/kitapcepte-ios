import SwiftUI

enum AppButtonKind: Sendable {
    case primary, secondary, text
}

struct AppButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    let kind: AppButtonKind
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: theme.dimens.spacingS) {
            if isLoading { ProgressView().tint(foreground) }
            configuration.label
        }
        .font(theme.typography.button)
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, minHeight: theme.dimens.minTouchTarget)
        .padding(.horizontal, theme.dimens.spacingL)
        .background(background, in: theme.shapes.pill)
        .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.5)
        .animation(.easeOut(duration: theme.dimens.animationDuration), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary: theme.colors.textOnPrimary
        case .secondary, .text: theme.colors.primary
        }
    }

    private var background: Color {
        switch kind {
        case .primary: theme.colors.primary
        case .secondary: theme.colors.primaryContainer
        case .text: .clear
        }
    }
}

struct AppButton: View {
    let title: String
    var kind: AppButtonKind = .primary
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) { Text(title) }
            .buttonStyle(AppButtonStyle(kind: kind, isLoading: isLoading))
            .disabled(isLoading)
    }
}

#Preview {
    VStack {
        AppButton(title: "Birincil", action: {})
        AppButton(title: "İkincil", kind: .secondary, action: {})
        AppButton(title: "Metin", kind: .text, action: {})
        AppButton(title: "Yükleniyor", isLoading: true, action: {})
    }
    .padding()
}
