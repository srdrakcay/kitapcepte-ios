import SwiftUI

struct AppChip: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.callout)
                .foregroundStyle(isSelected ? theme.colors.textOnPrimary : theme.colors.textPrimary)
                .padding(.horizontal, theme.dimens.spacingL)
                .frame(minHeight: theme.dimens.minTouchTarget)
                .background(isSelected ? theme.colors.primary : theme.colors.surfaceWhite, in: theme.shapes.pill)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeOut(duration: theme.dimens.animationDuration), value: isSelected)
    }
}

/// Yatay kaydırılan chip listesi. `selection` nil ise hiçbiri seçili değildir.
struct AppChipRow<Item: Hashable>: View {
    @Environment(\.appTheme) private var theme
    let items: [Item]
    let selection: Item?
    let title: (Item) -> String
    let onSelect: (Item) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.dimens.spacingS) {
                ForEach(items, id: \.self) { item in
                    AppChip(title: title(item), isSelected: item == selection) { onSelect(item) }
                }
            }
            .padding(.horizontal, theme.dimens.spacingL)
        }
    }
}

#Preview {
    AppChipRow(items: ["Fantasy", "Romance", "Mystery"], selection: "Fantasy", title: { $0 }, onSelect: { _ in })
        .padding(.vertical)
        .background(AppTheme.standard.colors.backgroundGradient)
}
