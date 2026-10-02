import SwiftUI

/// Etiket, ikon ve hata mesajı çerçevesi; AppTextField ve AppSecureField paylaşır.
private struct AppFieldContainer<Field: View>: View {
    @Environment(\.appTheme) private var theme
    let label: String
    let systemImage: String?
    let errorMessage: String?
    let field: Field

    init(label: String, systemImage: String?, errorMessage: String?, @ViewBuilder field: () -> Field) {
        self.label = label
        self.systemImage = systemImage
        self.errorMessage = errorMessage
        self.field = field()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.dimens.spacingXS) {
            Text(label)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
            HStack(spacing: theme.dimens.spacingS) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(theme.colors.textSecondary)
                        .accessibilityHidden(true)
                }
                field
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .padding(.horizontal, theme.dimens.spacingL)
            .frame(minHeight: theme.dimens.minTouchTarget)
            .background(theme.colors.surfaceWhite, in: theme.shapes.control)
            .overlay {
                theme.shapes.control.stroke(
                    errorMessage == nil ? Color.clear : theme.colors.error,
                    lineWidth: theme.dimens.borderWidth
                )
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.error)
            }
        }
    }
}

struct AppTextField: View {
    let label: String
    @Binding var text: String
    var systemImage: String?
    var errorMessage: String?
    var keyboard: UIKeyboardType = .default

    var body: some View {
        AppFieldContainer(label: label, systemImage: systemImage, errorMessage: errorMessage) {
            TextField(label, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }
}

struct AppSecureField: View {
    let label: String
    @Binding var text: String
    var systemImage: String? = "lock"
    var errorMessage: String?

    var body: some View {
        AppFieldContainer(label: label, systemImage: systemImage, errorMessage: errorMessage) {
            SecureField(label, text: $text)
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    return VStack {
        AppTextField(label: "E-posta", text: $text, systemImage: "envelope")
        AppSecureField(label: "Şifre", text: $text, errorMessage: "Şifre çok kısa")
    }
    .padding()
    .background(AppTheme.standard.colors.surface)
}
