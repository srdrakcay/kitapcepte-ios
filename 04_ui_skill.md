# UI SKILL — Kitap Cepte (SwiftUI)

Referanslar: `main.png` (genel stil), `Card1.png` (ürün kartı), `card2.png` (sepet kartı), `Detail.png` (detay).
Stil: yumuşak, cam (glass) hissi, yuvarlak köşeli, mor/indigo vurgulu modern e-ticaret.

## 1. Tek noktadan yönetim (ZORUNLU)
```
Core/DesignSystem/Theme/
  AppColors.swift      -> tüm renk token'ları
  AppTypography.swift  -> font ailesi + text style'lar
  AppDimens.swift      -> spacing (4/8/12/16/24), radius, ikon boyutları
  AppShapes.swift
  AppTheme.swift       -> Environment ile erişim: @Environment(\.appTheme)
Resources/Localizable.xcstrings -> ekran başlıkları ve tüm metinler
```
- View'larda **hard-coded renk, font, boyut, string YASAK**. Sadece theme token'ları ve String Catalog.
- Font değişimi tek satırda (`AppTypography`) yapılabilmeli.
- Renkler Asset Catalog yerine kodda (hex) tanımlanır veya ikisi tek yerden okunur; tek kaynak olmalı.

## 2. Renk token'ları
| Token | Hex | Kullanım |
|---|---|---|
| primary | #5B3FE8 | Butonlar, seçili sekme/chip, toplam fiyat butonu |
| primaryContainer | #E8E3FB | İkincil buton, "In cart" arka planı, seçili kart vurgusu |
| backgroundGradientStart | #6E7BE6 | Arka plan gradyanı sol üst |
| backgroundGradientEnd | #A08BEF | Arka plan gradyanı sağ alt |
| surface | #EEEBF8 | Ekran/kart zemini |
| surfaceWhite | #FFFFFF | Kart, buton |
| textPrimary | #1F1B33 | Başlık/metin |
| textSecondary | #8D8AA3 | Açıklama, eski fiyat |
| badgeTopItem | #FFD93B | "Top Item" rozeti |
| badgeCart | #F04A3C | Sepet bildirim rozeti |

## 3. Ortak bileşenler (`Core/DesignSystem/Components/`) — kod tekrarı yok
| Bileşen | Açıklama |
|---|---|
| `AppScaffold` | Gradyan arka plan + safe area + üst/alt bar slotları |
| `AppTopBar` | Varyantlar: Home (ortada "Kitap Cepte", sağda profil), Detail (geri · başlık · favori), Cart (başlık · profil), basit başlık |
| `AppTabBar` | Seçili öğe mor hap (ikon+yazı), diğerleri ikon; sepet rozetli (özel tasarım, sistem TabBar gizlenir) |
| `AppChip` / `AppChipRow` | Selected/unselected, yatay `ScrollView` |
| `BookCard` | Görsel, sağ üst `FavoriteButton`, isim (2 satır), alt fiyat butonu; "Top Item" rozeti |
| `FavoriteButton` | Dolu/boş kalp, beyaz yuvarlak zemin |
| `AppButton` | `ButtonStyle` ile Primary / Secondary / Text; loading + disabled |
| `PriceButton` | Fiyat metinli hap buton |
| `CartItemCard` | Görsel, isim, alt başlık, fiyat, adet, silme; "Remove item? No / Yes" satır içi onay |
| `QuantityStepper` | Adet artır/azalt |
| `SummaryRow` / `OrderSummaryCard` | Ara toplam, vergi, ödemeler, toplam |
| `AppTextField` / `AppSecureField` | Etiket, hata mesajı, ikon |
| `AppSheet` | Ortak bottom sheet; `LoginRequiredSheet` bunun üzerine kurulur |
| `AppAsyncImage` | NukeUI, placeholder + hata görseli |
| `LoadingView` / `ErrorView` / `EmptyView` | Ortak durum görünümleri |
| `AppBadge` | Top Item ve sepet sayacı |
| `SectionHeader`, `AppDivider` | |

## 4. Ekran düzenleri
- **Onboarding (3):** `TabView(.page)`, Skip/Next, son sayfada "Başla" → Auth.
- **Auth:** "Mail ile giriş yap" + "Misafir olarak devam et"; register formu (ad, mail, şifre, şifre tekrar).
- **Home:** TopBar (profil sağda, ortada "Kitap Cepte") → Chip listesi → 2 sütunlu `LazyVGrid` → tab bar.
- **Detail:** TopBar (geri/başlık/favori) → büyük kapak (Top Item rozeti) → isim, yazar, açıklama → benzer kitaplar (yatay) → alt sabit "₺fiyat · Sepete ekle".
- **Cart:** TopBar → yatay kart listesi → özet alanı → toplam butonu (ödemeye gider).
- **Payment:** kart önizleme + form (kart no, isim, SKT, CVV) → "Öde" → başarı mesajı → Home.
- **Profile:** kullanıcı bilgileri, şifre değiştir, kayıtlı kartlar, çıkış.

## 5. Kurallar
- Her ekran loading / error / empty durumu ve `#Preview` içerir.
- Min. dokunma alanı 44pt, `accessibilityLabel`, Dynamic Type desteği.
- Animasyonlar hafif (chip seçimi, favori, sepet rozeti).
- Yeni UI yazmadan önce mevcut ortak bileşen kontrol edilir; yoksa **önce ortak bileşen** eklenir.
