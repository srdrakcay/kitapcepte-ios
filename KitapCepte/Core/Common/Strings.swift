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

    enum Onboarding {
        static let skip = String(localized: "onboarding.skip")
        static let next = String(localized: "onboarding.next")
        static let start = String(localized: "onboarding.start")
        static let page1Title = String(localized: "onboarding.page1.title")
        static let page1Message = String(localized: "onboarding.page1.message")
        static let page2Title = String(localized: "onboarding.page2.title")
        static let page2Message = String(localized: "onboarding.page2.message")
        static let page3Title = String(localized: "onboarding.page3.title")
        static let page3Message = String(localized: "onboarding.page3.message")
    }

    enum Auth {
        static let placeholderTitle = String(localized: "auth.placeholder.title")
        static let placeholderMessage = String(localized: "auth.placeholder.message")
    }
}
