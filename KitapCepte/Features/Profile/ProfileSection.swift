import SwiftUI

/// Profil ekranının bölüm kartı: başlık + içerik. "Kayıtlı Kartlar" gibi yeni bölümler bununla eklenir.
struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        AppFormCard {
            SectionHeader(title: title)
            content
        }
    }
}

extension AppDimens {
    /// Profil avatarı çapı.
    var avatarSize: CGFloat { 72 }
}

extension User {
    /// Avatar için en fazla iki baş harf (büyük harf).
    var initials: String {
        let letters = name.split(whereSeparator: \.isWhitespace).prefix(2).compactMap(\.first)
        return String(letters).uppercased()
    }
}
