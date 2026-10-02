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
        static let welcomeSubtitle = String(localized: "auth.welcome.subtitle")
        static let loginWithMail = String(localized: "auth.loginWithMail")
        static let continueAsGuest = String(localized: "auth.continueAsGuest")
        static let loginTitle = String(localized: "auth.login.title")
        static let loginSubmit = String(localized: "auth.login.submit")
        static let registerTitle = String(localized: "auth.register.title")
        static let registerSubmit = String(localized: "auth.register.submit")
        static let noAccount = String(localized: "auth.noAccount")
        static let haveAccount = String(localized: "auth.haveAccount")
        static let invalidCredentials = String(localized: "auth.error.invalidCredentials")
        static let emailTaken = String(localized: "auth.error.emailTaken")
    }

    enum Field {
        static let name = String(localized: "field.name")
        static let email = String(localized: "field.email")
        static let password = String(localized: "field.password")
        static let confirmPassword = String(localized: "field.confirmPassword")
    }

    enum Validation {
        static let nameEmpty = String(localized: "validation.name.empty")
        static let emailInvalid = String(localized: "validation.email.invalid")
        static let passwordEmpty = String(localized: "validation.password.empty")
        static let passwordShort = String(localized: "validation.password.short")
        static let passwordMismatch = String(localized: "validation.password.mismatch")
    }

    enum Gate {
        static let title = String(localized: "gate.title")
        static let message = String(localized: "gate.message")
        static let action = String(localized: "gate.action")
    }

    enum Tab {
        static let home = String(localized: "tab.home")
        static let favorites = String(localized: "tab.favorites")
        static let cart = String(localized: "tab.cart")
        static let profile = String(localized: "tab.profile")
    }

    enum Home {
        static let empty = String(localized: "home.empty")
        static let topItem = String(localized: "badge.topItem")
    }

    enum Detail {
        static let title = String(localized: "detail.title")
        static let descriptionTitle = String(localized: "detail.description.title")
        static let descriptionEmpty = String(localized: "detail.description.empty")
        static let similarTitle = String(localized: "detail.similar.title")
        static let similarEmpty = String(localized: "detail.similar.empty")
        static let price = String(localized: "detail.price")
        static let addToCart = String(localized: "detail.addToCart")
        static let inCart = String(localized: "detail.inCart")
    }

    enum Accessibility {
        static let back = String(localized: "a11y.back")
        static let profile = String(localized: "a11y.profile")
        static let addFavorite = String(localized: "a11y.favorite.add")
        static let removeFavorite = String(localized: "a11y.favorite.remove")
    }
}
