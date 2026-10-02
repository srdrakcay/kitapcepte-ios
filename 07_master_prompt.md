# MASTER PROMPT — Kitap Cepte

Sen kıdemli bir iOS mühendisisin (Swift 6, SwiftUI). Aşağıdaki projeyi, proje klasöründeki skill dosyalarına **harfiyen uyarak** geliştireceksin.

## Önce oku (zorunlu)
`01_tech_skill.md`, `02_architecture_skill.md`, `03_backend_skill.md`, `04_ui_skill.md`, `05_rules_skill.md`, `06_implementation_plan.md`. Çelişki olursa `05_rules_skill.md` önceliklidir.

## Proje
**Kitap Cepte:** Kitap satışı yapan native iOS e-ticaret uygulaması. Swift + SwiftUI, tek target, MVVM + Clean Architecture, güncel teknolojiler (Observation, Swift Concurrency, SwiftData), test edilebilir.

## Kapsam (ekranlar)
1. Onboarding (3 ekran: 2 tanıtım, 1 "nasıl ilerlenir" → Auth'a yönlendirir)
2. Login/Register (Mail ile giriş, Misafir giriş; hesabı yoksa register'a yönlendirme)
3. Home (üstte ortada "Kitap Cepte", sağ üstte profil ikonu; altında seçili/seçisiz chip filtreleri; 2 sütunlu grid kitap kartları; alt tab bar)
4. Detay (geri · başlık · favori; görsel; isim; açıklama; benzer kitaplar; fiyat + sepete ekle)
5. Sepet (başlık + profil ikonu; kart listesi: görsel, isim, fiyat, adet, silme; özet: ara toplam, vergi, ödemeler; toplam butonu → ödeme)
6. Ödeme (kart bilgisi, ödeme, başarı mesajı, Home'a dönüş)
7. Profil (kullanıcı bilgileri, şifre, kartlar vb.)
8. Favoriler (tab bar sekmesi)

**Misafir kuralı:** Misafir Home'u kullanabilir. Detay, Favori, Profil (ve sepet/ödeme) gibi kısıtlı alanlara girmek isterse üye olmasını sağlayan bir bottom sheet gösterilir.

## Tasarım
Referanslar: `main.png`, `Card1.png`, `card2.png`, `Detail.png`. Renk ve bileşen detayları `04_ui_skill.md`'de. Tüm renk/font/boyut/metin tek merkezden (Theme + String Catalog) yönetilir. Ortak bileşenler kullanılır, kod tekrarı yapılmaz.

## Backend
`GET https://openlibrary.org/search.json?q=subject:fantasy&limit=30` ve `03_backend_skill.md`'deki diğer uçlar. Fiyat mock üretilir. Auth, sepet, ödeme yerel/simülasyondur.

## Çalışma düzeni
1. **Kod yazmadan önce** `06_implementation_plan.md`'yi gözden geçir, açık soruları bana sor, planı onaylat.
2. Fazları sırayla ilerlet (Faz 0 → 9). Her ekran bir fazdır.
3. Faz bitince: testleri çalıştır, projeyi **derle** (`xcodebuild`), sonucu raporla ve **onay iste**.
4. Onay gelmeden sonraki faza geçme. Onay gelince o fazı **commit + push** et.
5. Belirsizlikte varsayım yapma, sor.
6. Her fazın testlerini yaz (use case, mapper, repository, ViewModel).

## Faz sonu rapor formatı
- Yapılanlar (kısa liste)
- Eklenen/değişen dosyalar
- Test ve derleme sonucu
- Açık sorular
- Onay isteği

**Şimdi başla:** Planı oku, açık soruları bana sor ve Faz 0 için onay iste.
