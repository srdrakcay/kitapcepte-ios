import Foundation

extension Strings {
    enum Profile {
        static let title = String(localized: "profile.title", table: "Profile")
        static let unavailable = String(localized: "profile.unavailable", table: "Profile")
        static let accountTitle = String(localized: "profile.account.title", table: "Profile")
        static let passwordTitle = String(localized: "profile.password.title", table: "Profile")
        static let passwordSubmit = String(localized: "profile.password.submit", table: "Profile")
        static let passwordSuccess = String(localized: "profile.password.success", table: "Profile")
        static let fieldCurrent = String(localized: "profile.field.current", table: "Profile")
        static let fieldNew = String(localized: "profile.field.new", table: "Profile")
        static let fieldConfirm = String(localized: "profile.field.confirm", table: "Profile")
        static let errorCurrentEmpty = String(localized: "profile.error.currentEmpty", table: "Profile")
        static let errorCurrentWrong = String(localized: "profile.error.currentWrong", table: "Profile")
        static let errorNewShort = String(localized: "profile.error.newShort", table: "Profile")
        static let errorNewSame = String(localized: "profile.error.newSame", table: "Profile")
        static let errorMismatch = String(localized: "profile.error.mismatch", table: "Profile")
        static let signOutButton = String(localized: "profile.signOut.button", table: "Profile")
        static let signOutTitle = String(localized: "profile.signOut.title", table: "Profile")
        static let signOutMessage = String(localized: "profile.signOut.message", table: "Profile")
        static let signOutConfirm = String(localized: "profile.signOut.confirm", table: "Profile")
        static let signOutCancel = String(localized: "profile.signOut.cancel", table: "Profile")
    }
}
