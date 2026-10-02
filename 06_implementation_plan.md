# IMPLEMENTATION PLAN — Kitap Cepte (Swift / SwiftUI)

> Bu plan onaylanmadan kodlamaya başlanmaz.

## Açık sorular / varsayımlar (onayına sunuyorum)
1. **Bottom bar:** Metinde 3 sekme var, `main` referansında Cart da var. Öneri: **4 sekme (Home, Favori, Sepet [rozetli], Profil)**. Onay?
2. **Misafir kısıtı:** Misafir Home'da gezer/filtreler. Kitap kartı (detay), Favori, Profil, Sepet/Ödeme'de "Üye ol" bottom sheet'i çıkar. Doğru mu?
3. **Kayıt/Giriş:** Backend olmadığı için yerel (mock) hesap sistemi (SwiftData + Keychain). Uygun mu?
4. **Fiyat:** Open Library'de fiyat yok; `key`'ten deterministik mock fiyat (TRY).
5. **Ödeme:** Simülasyon; kart verisi saklanmaz (yalnızca son 4 hane).
6. **Minimum iOS:** 17.0 (Observation + SwiftData). Daha eski sürüm gerekiyor mu? Xcode sürümün nedir?
7. **Üçüncü parti:** Sadece Nuke (görsel) + SwiftLint/SwiftFormat. Başka eklemek ister misin?
8. **Dil:** Metinler Türkçe mi İngilizce mi (referans görsel İngilizce)? String Catalog ile çoklu dil hazır olur.
9. **Proje:** Xcode projesini sen mi oluşturacaksın, yoksa Claude Code ile `xcodegen`/manuel yapı mı kurulsun?

## Fazlar
Her fazda: kod → test → derleme → onay → commit/push.

| Faz | İçerik | Çıktı |
|---|---|---|
| **0** | **Kurulum:** Xcode projesi, klasör yapısı, SPM (Nuke), SwiftLint/SwiftFormat, `.gitignore`, AppContainer (DI), **Design System** (AppColors, Typography, Dimens, Theme) ve temel ortak bileşenler (AppScaffold, AppButton, AppTextField, AppChip, AppSheet, Loading/Error/Empty), String Catalog | Boş ekranlarla derlenen uygulama |
| **1** | **Onboarding** (3 ekran, page TabView, Skip/Next, ilk açılış bilgisi `@AppStorage`) | Onboarding → Auth |
| **2** | **Login / Register:** mail girişi, misafir girişi, kayıt formu + doğrulama, SessionManager, GuestGate + LoginRequiredSheet | Oturum akışı |
| **3** | **Home:** OpenLibraryService, DTO/mapper, BookRepository, chip filtre, 2 sütunlu grid, BookCard, favori toggle, TopBar, AppTabBar | Gerçek veriyle Home |
| **4** | **Detay:** TopBar, kapak, açıklama (works endpoint), benzer kitaplar, fiyat + sepete ekle, favori | Detay ekranı |
| **5** | **Favoriler:** SwiftData, liste, kaldırma, boş durum | Favoriler sekmesi |
| **6** | **Sepet:** CartItemCard, adet/silme onayı, özet (ara toplam, vergi, ödemeler), toplam butonu, rozet | Sepet |
| **7** | **Ödeme:** kart formu + Luhn/SKT/CVV doğrulama, başarı mesajı, sepeti temizle, Home'a dönüş | Ödeme akışı |
| **8** | **Profil:** kullanıcı bilgileri, şifre değiştirme, kayıtlı kartlar (son 4 hane), çıkış | Profil |
| **9** | **Son rötuşlar:** hata/boş durumlar, erişilebilirlik, performans, test boşlukları, README | Yayına hazır sürüm |

## Definition of Done (her faz)
- [ ] Ekran referans tasarıma uygun; yalnızca ortak bileşen ve tema token'ları
- [ ] Loading / Error / Empty durumları ve `#Preview`
- [ ] Unit testler yazıldı ve yeşil
- [ ] `xcodebuild build` ve `test` başarılı
- [ ] Kullanıcı onayı alındı
- [ ] Commit + push yapıldı

## Riskler
- Open Library yavaş/oran sınırlı olabilir → cache + retry + User-Agent.
- Bazı kitaplarda kapak/yazar yok → placeholder ve null-safe mapping.
- Referanstaki cam/blur efekti iOS sürümüne göre farklılaşabilir → `Material` ile yaklaşılır.
