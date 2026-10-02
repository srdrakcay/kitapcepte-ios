import SwiftUI

struct AppTheme: Sendable {
    let colors: AppColors
    let typography: AppTypography
    let dimens: AppDimens
    let shapes: AppShapes

    static let standard: AppTheme = {
        let dimens = AppDimens()
        return AppTheme(colors: AppColors(), typography: AppTypography(), dimens: dimens, shapes: AppShapes(dimens: dimens))
    }()
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.standard
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}
