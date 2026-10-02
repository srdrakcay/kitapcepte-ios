import SwiftUI

/// Ortak şekiller.
struct AppShapes: Sendable {
    let dimens: AppDimens

    var card: RoundedRectangle { RoundedRectangle(cornerRadius: dimens.radiusM, style: .continuous) }
    var control: RoundedRectangle { RoundedRectangle(cornerRadius: dimens.radiusS, style: .continuous) }
    var sheet: RoundedRectangle { RoundedRectangle(cornerRadius: dimens.radiusL, style: .continuous) }
    var pill: Capsule { Capsule() }
}
