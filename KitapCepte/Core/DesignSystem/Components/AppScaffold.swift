import SwiftUI

/// Gradyan arka plan + üst/alt bar slotları.
struct AppScaffold<Top: View, Bottom: View, Content: View>: View {
    @Environment(\.appTheme) private var theme
    private let top: Top
    private let bottom: Bottom
    private let content: Content

    init(
        @ViewBuilder top: () -> Top,
        @ViewBuilder bottom: () -> Bottom,
        @ViewBuilder content: () -> Content
    ) {
        self.top = top()
        self.bottom = bottom()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            top
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            bottom
        }
        .background(theme.colors.backgroundGradient.ignoresSafeArea())
    }
}

extension AppScaffold where Top == EmptyView, Bottom == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(top: { EmptyView() }, bottom: { EmptyView() }, content: content)
    }
}

extension AppScaffold where Top == EmptyView {
    init(@ViewBuilder bottom: () -> Bottom, @ViewBuilder content: () -> Content) {
        self.init(top: { EmptyView() }, bottom: bottom, content: content)
    }
}
