import SwiftUI

/// Font ailesi ve text style'lar. Font değişimi yalnızca `design` ile yapılır.
struct AppTypography: Sendable {
    private let design: Font.Design = .rounded

    var largeTitle: Font { .system(.largeTitle, design: design).weight(.bold) }
    var title: Font { .system(.title2, design: design).weight(.bold) }
    var headline: Font { .system(.headline, design: design) }
    var body: Font { .system(.body, design: design) }
    var callout: Font { .system(.callout, design: design) }
    var caption: Font { .system(.caption, design: design) }
    var button: Font { .system(.body, design: design).weight(.semibold) }
}
