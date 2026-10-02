# RULES SKILL — Kitap Cepte

## Faz süreci (kesin kurallar)
1. Her ekran = bir faz. Fazlar sırayla ilerler.
2. Faz bitince **projeyi derle** (`xcodebuild build`) ve **testleri çalıştır** (`xcodebuild test`).
3. Derleme/test başarısızsa düzelt; başarılı olmadan onaya sunma.
4. Onaya sun: yapılanlar, derleme/test sonucu, ekran görüntüsü (mümkünse), açık sorular.
5. **Kullanıcı onayı gelmeden bir sonraki faza GEÇME.**
6. Onay sonrası o fazın değişikliklerini **commit + push** et.
7. Onay yokken commit/push yapma.

## Git
- Faz branch'i: `phase/<no>-<ad>` (ör. `phase/03-home`). Merge/push yöntemi kullanıcıyla netleşir.
- Commit mesajı (Conventional Commits): `feat(home): add book grid with chip filter`.
- Her commit derlenebilir olmalı. `.gitignore` (xcuserdata, DerivedData, .DS_Store) en başta eklenir. Gizli bilgi commit edilmez.

## Kod kuralları
- Swift API Design Guidelines; SwiftLint + SwiftFormat temiz.
- ViewModel'de SwiftUI view/render kodu yok; View'da iş mantığı yok.
- Hard-coded renk/boyut/font/metin yok (bkz. ui_skill).
- Kod tekrarı yok: 2. kullanımda ortak bileşene/yardımcıya taşı.
- `!`, `try!`, `as!` yok; singleton yok (DI); mutable state dışarı açılmaz (`private(set)`).
- Swift 6 concurrency uyarıları sıfır tutulur (`@MainActor`, `Sendable`).
- Domain katmanı SwiftUI/SwiftData/URLSession import etmez.
- Sihirli sayı/string yok.

## Test kuralları
- Use case, mapper, repository (URLProtocol stub), ViewModel testleri **her fazda** yazılır.
- Mock kütüphanesi yok; protocol + Fake/Stub kullan. Swift Testing (`@Test`, `#expect`).
- Test isimleri açıklayıcı (`func addsToCart_whenLoggedIn`).
- Fazın testleri yeşil olmadan onaya gidilmez.

## İletişim
- Belirsiz gereksinimde varsayım yapıp ilerleme; açık soru olarak sor.
- Kapsam dışı özellik ekleme.
- Her faz sonunda kısa rapor: yapılanlar / test / derleme / sonraki faz.
