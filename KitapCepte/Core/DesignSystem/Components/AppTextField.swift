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

/// `format` verilirse yerel taslak metin tutar: biçimlendirme sonucu dışarıdaki değer değişmese bile alanın gösterdiği
/// metin düzeltilir (TextField/SecureField içeride metin önbelleği tuttuğu için yalnızca binding'e geri yazmak yetmez).
/// Taslak tek yönlüdür (alan -> dışarı); `format` yoksa doğrudan binding kullanılır.
private struct DraftField<Field: View>: View {
    @Binding var text: String
    let format: ((String) -> String)?
    let field: (Binding<String>) -> Field
    @State private var draft: String

    init(text: Binding<String>, format: ((String) -> String)?, @ViewBuilder field: @escaping (Binding<String>) -> Field) {
        _text = text
        self.format = format
        self.field = field
        _draft = State(initialValue: text.wrappedValue)
    }

    @ViewBuilder
    var body: some View {
        if let format {
            field($draft)
                .onChange(of: draft) { _, new in
                    let formatted = format(new)
                    if formatted != new { draft = formatted }
                    if formatted != text { text = formatted }
                }
        } else {
            field($text)
        }
    }
}

struct AppTextField: View {
    let label: String
    @Binding var text: String
    var systemImage: String?
    var errorMessage: String?
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .never
    var accessibilityLabel: String?
    /// Girdiyi yazarken yeniden biçimlendirir.
    var format: ((String) -> String)?

    var body: some View {
        AppFieldContainer(label: label, systemImage: systemImage, errorMessage: errorMessage) {
            DraftField(text: $text, format: format) { draft in
                TextField(label, text: draft)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(capitalization)
                    .autocorrectionDisabled()
                    .accessibilityLabel(accessibilityLabel ?? label)
            }
        }
    }
}

struct AppSecureField: View {
    let label: String
    @Binding var text: String
    var systemImage: String? = "lock"
    var errorMessage: String?
    var keyboard: UIKeyboardType = .default
    var format: ((String) -> String)?

    var body: some View {
        AppFieldContainer(label: label, systemImage: systemImage, errorMessage: errorMessage) {
            DraftField(text: $text, format: format) { draft in
                SecureField(label, text: draft)
                    .keyboardType(keyboard)
            }
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
