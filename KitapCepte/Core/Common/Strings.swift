import Foundation

/// Tüm kullanıcı metinlerine tek erişim noktası (`Localizable.xcstrings`).
enum Strings {
    enum App {
        static let name = String(localized: "app.name")
    }

    enum Common {
        static let retry = String(localized: "common.retry")
        static let loading = String(localized: "common.loading")
        static let cancel = String(localized: "common.cancel")
        static let ok = String(localized: "common.ok")
        static let errorTitle = String(localized: "common.error.title")
        static let emptyTitle = String(localized: "common.empty.title")
    }

    enum Error {
        static let network = String(localized: "error.network")
        static let decoding = String(localized: "error.decoding")
        static let notFound = String(localized: "error.notFound")
        static let unknown = String(localized: "error.unknown")
    }
}
