import CoreGraphics

/// Spacing, radius ve boyut token'ları.
struct AppDimens: Sendable {
    // Spacing
    let spacingXS: CGFloat = 4
    let spacingS: CGFloat = 8
    let spacingM: CGFloat = 12
    let spacingL: CGFloat = 16
    let spacingXL: CGFloat = 24

    // Radius
    let radiusS: CGFloat = 12
    let radiusM: CGFloat = 20
    let radiusL: CGFloat = 28
    let radiusPill: CGFloat = 999

    // Boyutlar
    let minTouchTarget: CGFloat = 44
    let iconS: CGFloat = 16
    let iconM: CGFloat = 24
    let iconL: CGFloat = 40
    let borderWidth: CGFloat = 1
    let badgeSize: CGFloat = 18
    /// Kitap kapağı en/boy oranı (genişlik / yükseklik).
    let coverAspectRatio: CGFloat = 2.0 / 3.0
    /// Detay ekranı büyük kapak yüksekliği.
    let detailCoverHeight: CGFloat = 320
    /// Benzer kitaplar yatay listesindeki kart genişliği.
    let similarCardWidth: CGFloat = 148

    let shadowRadius: CGFloat = 16
    let shadowOffsetY: CGFloat = 4

    // Animasyon
    let animationDuration: Double = 0.25

    // Sepet (Faz 6)
    /// Sepet satırındaki kapak genişliği.
    let cartCoverWidth: CGFloat = 76

    // Profil (Faz 8a)
    /// Profil avatarı çapı.
    let avatarSize: CGFloat = 72

    // Ödeme (Faz 7)
    /// Kart önizleme en/boy oranı (ISO/IEC 7810 ID-1).
    let cardAspectRatio: CGFloat = 1.586
    /// Başarı ekranı ikon boyutu.
    let successIconSize: CGFloat = 72
}
