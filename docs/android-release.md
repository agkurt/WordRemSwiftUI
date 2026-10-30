# WordRem AI — Android'i Google Play'e çıkarma listesi

Android uygulaması `android/` klasöründe (Kotlin + Jetpack Compose). iOS ile aynı ses sunucusunu
(`api.wordremai.app`), aynı ders içeriğini (`WordRemSwiftUI/Resources/content.json`, `scenarios.json`) ve
aynı RevenueCat projesini kullanır. **Sunucuda hiçbir değişiklik gerekmiyor.**

Paket adı (applicationId): **`com.twinflare.wordrem`** — Play'e ilk yüklemeden sonra değiştirilemez.
Farklı bir ad istersen ilk yüklemeden önce `android/app/build.gradle.kts` içinde değiştir.

---

## 0. Bilgisayarda derleme (hazır)

Kurulu olanlar: JDK 17 (`brew install openjdk@17`), Android SDK (`~/Library/Android/sdk`).

```bash
cd android
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
./gradlew assembleDebug        # → app/build/outputs/apk/debug/app-debug.apk
./gradlew bundleRelease        # → app/build/outputs/bundle/release/app-release.aab (Play'e bu yüklenir)
```

Telefona kurmak: Telefonda *Ayarlar → Telefon hakkında → Derleme numarası*na 7 kez dokun → *Geliştirici
seçenekleri → USB hata ayıklama* aç → USB ile bağla:

```bash
~/Library/Android/sdk/platform-tools/adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

Gizli değerler `android/secrets.properties` dosyasına yazılır (git'e girmez). Şablon:

```properties
# RevenueCat → Project → Apps → Play Store uygulaması → Public SDK key (goog_ ile başlar)
revenuecat.googleApiKey=goog_XXXXXXXX
# İmza (adım 4)
release.storeFile=wordrem-upload.jks
release.storePassword=...
release.keyAlias=upload
release.keyPassword=...
# Ses sunucusu anahtarı yazılmazsa iOS Info.plist'teki VoiceAppKey kullanılır
```

RevenueCat anahtarı yokken uygulama çalışır ama ödeme ekranı "Abonelikler yüklenemedi" der
(herkes ücretsiz kullanıcıdır, sunucu yine 120 sn ücretsiz deneme verir).

---

## Senin yapman gerekenler (ben hesap açamam / şifre giremem)

### 1. Google Play Console geliştirici hesabı — 25 USD
- [ ] https://play.google.com/console → hesap aç (Kişisel ya da Kuruluş). Twinflare adına çıkacaksa
      **Kuruluş** seç: D-U-N-S numarası gerekir ama aşağıdaki "12 test kullanıcısı" kuralı kalkar.
- [ ] Kimlik doğrulama + 25 USD ödeme. Onay birkaç gün sürebilir.
- [ ] **Kişisel hesapta önemli kural:** yeni kişisel hesaplar, uygulamayı herkese açmadan önce en az
      **12 test kullanıcısıyla 14 gün kapalı test** yapmak zorunda. Bunu erkenden başlat (adım 5).

### 2. Uygulamayı Play Console'da oluştur
- [ ] *Uygulama oluştur* → Ad: **WordRem AI**, varsayılan dil, Uygulama, Ücretsiz.
- [ ] Kategori: **Eğitim**. İletişim e-postası, gizlilik politikası:
      `https://api.wordremai.app/privacy`

### 3. Firebase'e Android uygulaması ekle (`google-services.json`)
- [ ] Firebase Console → `wordrem-ai` projesi → *Uygulama ekle → Android* → paket adı
      `com.twinflare.wordrem`.
- [ ] İndirilen `google-services.json` dosyasını **`android/app/`** içine koy (git'e girmez).
- Not: Dosya konunca Gradle eklentisi kendiliğinden açılır. Firebase Analytics olaylarının Android'e
  taşınması ayrı bir iş (iOS'taki `Track` olayları); bu sürümde analiz yok.

### 4. Yükleme anahtarı (keystore) — **yedeğini al, kaybedersen güncelleme yükleyemezsin**
> 30 Ekim: oluşturuldu → `android/wordrem-upload.jks` + şifreleri `android/secrets.properties`'te.
> Sana kalan: bu iki dosyayı güvenli bir yere yedekle. (Aşağıdaki komut yalnızca yeniden oluşturmak için.)

```bash
cd android
keytool -genkeypair -v -keystore wordrem-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```
- [ ] Şifreleri `secrets.properties`'e yaz (yukarıdaki şablon). `.jks` git'e girmez.
- [ ] `.jks` dosyasını ve şifreleri 1Password / iCloud Drive gibi güvenli bir yere yedekle.
- [ ] Play Console ilk yüklemede **Play Uygulama İmzalama**yı önerir → kabul et (Google asıl imza
      anahtarını saklar, senin `.jks` sadece yükleme anahtarı olur).

### 5. İlk yükleme + iç test
- [ ] `./gradlew bundleRelease` → `app/build/outputs/bundle/release/app-release.aab`
- [ ] Play Console → *Test → Dahili test* → yeni sürüm → `.aab` yükle → test kullanıcısı e-postalarını
      ekle → yayınla. Davet bağlantısıyla telefonuna Play'den kur.
- [ ] (Kişisel hesapsa) *Kapalı test* parkuru aç, **12+ kişi** ekle, 14 gün aktif tut.

### 6. Abonelikleri Play'de oluştur (ilk `.aab` yüklendikten sonra açılır)
Kimlikler iOS ile aynı olsun ki RevenueCat'te tek entitlement'a bağlansın:

| Ürün kimliği (Product ID) | Temel plan | Not |
|---|---|---|
| `wordrem_annual_subscription` | `annual` — 1 yıl, otomatik yenilenir | **7 gün ücretsiz deneme** teklifi ekle (yeni aboneler) |
| `wordrem_ai_monthly` | `monthly` — 1 ay | |
| `wordrem_weekly_subscription` | `weekly` — 1 hafta | İsteğe bağlı; aylık varken uygulama gizler |

- [ ] *Para kazanma → Abonelikler* → her biri için oluştur, fiyatları iOS'la aynı seviyede ayarla, **Etkinleştir**.

### 7. RevenueCat'i Google Play'e bağla
- [ ] RevenueCat → WordRem projesi → *Apps → + New → Google Play Store* → paket `com.twinflare.wordrem`.
- [ ] **Hizmet hesabı (service account) JSON**: RevenueCat'in rehberini izle
      (Google Cloud'da hizmet hesabı aç → Play Console *Kullanıcılar ve izinler*den finans izinlerini ver →
      JSON'u RevenueCat'e yükle). İzinlerin aktif olması 24–36 saat sürebilir.
- [ ] (Önerilir) *Real-time developer notifications*: RevenueCat'in verdiği Pub/Sub konusunu Play Console →
      *Para kazanma kurulumu*na gir.
- [ ] *Products* → Play aboneliklerini içe aktar → hepsini **`premium`** entitlement'ına bağla.
- [ ] *Offerings → default* → paketlere Play ürünlerini de ekle: `$rc_annual`, `$rc_monthly`, `$rc_weekly`.
- [ ] Android uygulamasının **Public SDK key**'ini (`goog_…`) `android/secrets.properties`'e yaz → yeniden derle.
- Ses sunucusu Pro'yu RevenueCat'e kullanıcı kimliğiyle sorduğu için Play aboneliği de otomatik tanınır.
  Sunucudaki bütçe hesabı (`APPLE_COMMISSION`) Google'ın %15'i için de uygundur, değişiklik gerekmez.
- Bilinen sınır: iOS'ta da hesap olmadığı için iPhone'da alınan abonelik Android'e **taşınmaz** (ve tersi).

### 8. Mağaza sayfası (Store listing)
- [ ] Ad, kısa ve tam açıklama (tr + en): hazır → `android/store/listing.md` — kopyala yapıştır.
- [ ] Uygulama simgesi 512×512: hazır → `android/store/icon-512.png`
- [ ] Öne çıkan görsel 1024×500: hazır → `android/store/tr/feature-graphic.png`, `android/store/en/feature-graphic.png`
- [ ] Telefon ekran görüntüleri: en az 2 (önerilen 4–8). Android telefondan alınmalı (iPhone çerçeveli
      App Store görselleri Play'de kullanılmamalı) — telefonu bağlayınca çekip hazırlarım.
- [ ] Her dil için (tr, en, de, fr, es, it, ru, zh) çeviri ekleyebilirsin.

### 9. Uygulama içeriği formları (Play Console → *Politika → Uygulama içeriği*)
- [ ] **Gizlilik politikası**: `https://api.wordremai.app/privacy`
- [ ] **Uygulama erişimi**: "Tüm işlevler kısıtlama olmadan kullanılabilir" (giriş yok).
- [ ] **Reklamlar**: Reklam yok.
- [ ] **İçerik derecelendirmesi** anketi (Eğitim; kullanıcılar arası iletişim yok; yapay zekâ sohbeti var).
- [ ] **Hedef kitle**: 13+ (ya da 18+). 13 altını seçme — Aileler politikası ek şartlar getirir.
- [ ] **Veri güvenliği** formu — dürüst doldur:
  - *Ses kayıtları*: toplanır, işlenmek için paylaşılır (Google Gemini / OpenAI yazıya çevirme ve sesli
    cevap), kullanıcı basılı tutunca gönderilir; uygulama saklamaz.
  - *Satın alma geçmişi*: RevenueCat / Google Play (abonelik doğrulama).
  - *Uygulama etkinliği / cihaz kimliği*: ücretsiz süre sayacı için rastgele cihaz kimliği (sunucu).
  - Veriler aktarımda şifrelenir (HTTPS/WSS). Hesap olmadığı için "hesap silme" bağlantısı gerekmez;
    "ilerlemeyi sıfırla" cihazdaki veriyi siler.
- [ ] **Finansal özellikler / Sağlık / Haber**: Hiçbiri.

### 10. Yayın
- [ ] Kapalı test süresi dolunca (kişisel hesap) *Üretim*e başvur → incelemeye gönder.
- [ ] Her yeni sürümde `android/app/build.gradle.kts` içinde `versionCode`'u 1 artır, `versionName`'i güncelle.

---

## Bu ilk sürümde olanlar
- Onboarding: hoş geldin → ana dil (8 dil, arayüz dili olur) → öğrenilecek dil → "sana nasıl hitap edelim" →
  Lupa ile canlı demo → ödeme ekranı.
- Lupa: Gemini Live sesi (sunucu kapatırsa / açılmazsa OpenAI Realtime'a düşer), bas-konuş, altyazı,
  ifade kartları, yazarak mesaj, iOS ile aynı talimatlar ve ders yönlendirmesi (parça → kendine uyarla →
  birleştir → canlandırma → bitiş). Hafıza (`remember_fact`), tekrar kelimeleri, dil değiştirme.
- Kelimeler: Lupa'nın kartları otomatik eklenir; kurs seviyelerinden kelime eklenebilir; iOS ile aynı SM-2 tekrar.
- Seri, profil (haftalık takvim, istatistik, dil değiştirme, geri yükleme, abonelik yönetimi, sıfırlama).
- RevenueCat + Google Play Billing, `premium` (ve eski `pro`) entitlement'ı.

- Günlük Lupa hatırlatması: alışkanlık saatinde (son açılışların medyanı, yoksa 19:30), o gün çalışılmadıysa;
  seri varsa "serini kurtar", yoksa sıradaki ders.

## Sonraya kalanlar
- iOS'taki ayrıntılı hatırlatma akışları (Pro daveti, haftalık özet, bildirimden kelime tekrarı), widget'lar, liderlik tablosu (Game Center karşılığı: Play Games).
- Firebase Analytics olayları, yarım kalan dersi sürdürme, birden çok öğrenme dili, desteler.
- iOS ile ortak hesap (Google/Apple ile giriş) — aboneliği platformlar arası taşımak için iki tarafta da gerekir.
