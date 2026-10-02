import SwiftUI

enum AppTab: CaseIterable, Hashable, Sendable {
    case home, favorites, cart, profile

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .favorites: "heart.fill"
        case .cart: "cart.fill"
        case .profile: "person.fill"
        }
    }

    var title: String {
        switch self {
        case .home: Strings.Tab.home
        case .favorites: Strings.Tab.favorites
        case .cart: Strings.Tab.cart
        case .profile: Strings.Tab.profile
        }
    }
}

/// Özel tab bar: seçili öğe mor hap (ikon + yazı), diğerleri yalnızca ikon.
struct AppTabBar: View {
    @Environment(\.appTheme) private var theme
    let selection: AppTab
    let cartCount: Int
    let onSelect: (AppTab) -> Void

    var body: some View {
        HStack(spacing: theme.dimens.spacingS) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                item(tab)
            }
        }
        .padding(theme.dimens.spacingS)
        .background(theme.colors.surfaceWhite, in: theme.shapes.pill)
        .shadow(color: theme.colors.shadow, radius: theme.dimens.shadowRadius, y: theme.dimens.shadowOffsetY)
        .padding(.horizontal, theme.dimens.spacingL)
        .padding(.bottom, theme.dimens.spacingS)
        .animation(.easeInOut(duration: theme.dimens.animationDuration), value: selection)
    }

    private func item(_ tab: AppTab) -> some View {
        let isSelected = tab == selection
        return Button { onSelect(tab) } label: {
            HStack(spacing: theme.dimens.spacingXS) {
                Image(systemName: tab.systemImage)
                if isSelected {
                    Text(tab.title)
                        .font(theme.typography.callout.weight(.semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .foregroundStyle(isSelected ? theme.colors.textOnPrimary : theme.colors.textSecondary)
            .padding(.horizontal, theme.dimens.spacingL)
            .frame(maxWidth: isSelected ? nil : .infinity, minHeight: theme.dimens.minTouchTarget)
            .background(isSelected ? theme.colors.primary : .clear, in: theme.shapes.pill)
            .overlay(alignment: .topTrailing) {
                if tab == .cart && cartCount > 0 {
                    AppBadge(text: String(cartCount), style: .cart)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .layoutPriority(isSelected ? 1 : 0)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack {
        AppTabBar(selection: .home, cartCount: 0, onSelect: { _ in })
        AppTabBar(selection: .favorites, cartCount: 3, onSelect: { _ in })
    }
    .padding(.vertical)
    .background(AppTheme.standard.colors.backgroundGradient)
}
