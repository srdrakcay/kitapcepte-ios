import Testing
@testable import KitapCepte

struct AppThemeTests {
    @Test func minimumTouchTargetIsAtLeast44() {
        #expect(AppTheme.standard.dimens.minTouchTarget >= 44)
    }

    @Test func spacingScaleIsAscending() {
        let d = AppTheme.standard.dimens
        #expect(d.spacingXS < d.spacingS && d.spacingS < d.spacingM && d.spacingM < d.spacingL && d.spacingL < d.spacingXL)
    }
}
