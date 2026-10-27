# WordRem sosyal medya — iç araç

Organik büyüme için TikTok, Instagram Reels ve X. Bu klasör içeriğin tek kaynağı: marka rehberi, senaryolar, stüdyo dosyaları ve paylaşım geçmişi.

| Dosya | Ne |
|---|---|
| `README.md` | Marka rehberi, hesap kurulumu, çekim akışı |
| `content-plan.md` | İlk 30 video: ilk saniye yazısı, çekim, açıklama |
| `studio/*.json` | Stüdyo modunun oynattığı konuşma senaryoları |
| `log.csv` | Paylaşılan her video ve sonuçları (ölçüm aşamasında eklenecek) |

## Kitle ve konum

- **İlk kitle:** İngilizce konuşmaktan çekinen, 18-35 yaş Türkler. Okulda yıllarca İngilizce gördü ama konuşamıyor.
- **Tek cümlelik vaat:** "Utanmadan, yargılanmadan İngilizce konuş. Lupa seni bekliyor."
- **Rakiplerden farkımız:** Duolingo test çözdürür, biz konuşturuyoruz. Kurslar pahalı ve randevulu, Lupa her an cebinde.
- **Dil:** Videolar Türkçe anlatım ve altyazıyla, konuşmalar İngilizce. İngilizce hesap sonra açılacak.

## Lupa'nın karakteri

- Sabırlı, sıcak, esprili; asla küçümsemez ve flört etmez.
- Hatayı yüzüne vurmaz, doğrusunu söyleyip devam eder. Videolarda öne çıkan şey bu: "Hata yapmak serbest."
- Adı her yerde **Lupa**. Kişi zamiriyle değil adıyla anılır ("Lupa düzeltti", "Lupa sordu").

## Görsel dil

- Uygulamanın kâğıt rengi arka planı ve turuncu vurgu rengi. Kapak görsellerinde aynı ikisi.
- İlk saniye yazısı: büyük, beyaz, siyah konturlu, ekranın üst üçte birinde. En fazla 7 kelime.
- Altyazı: kelime kelime yanan, ekranın ortasının altında; vurgu rengi turuncu.
- Son 1,5 saniye: uygulama ikonu ve "WordRem AI · App Store". Onay gelene kadar "Çok yakında".

## İçerik türleri

1. **Gerçek konuşma:** Stüdyo kaydı, Lupa'yla canlandırma (kafe, havalimanı, iş görüşmesi).
2. **Hata düzeltme:** Türklerin klasik hataları, Lupa düzeltir.
3. **Sınama:** Argo, seviye tahmini, zor sorular.
4. **Günün sorusu:** Widget'taki soru. Takipçiden yorumda cevap istenir.
5. **Geliştirici hikâyesi:** Ahmet'in kendi ağzından, uygulamayı nasıl yaptığı. X'te de yazılı hâli.
6. **Uygulama anları:** Widget, seri, ders sonu ekranı. Kısa ve görsel.

Kural: Sahte kullanıcı yorumu ya da var olmayan kişinin hikâyesi yok. Konuşmalar gerçek uygulama kaydı; öğrenci sesi senaryodan okunduğunda bu bir canlandırmadır, "kullanıcımız Ayşe" gibi sunulmaz.

## Hesap kurulumu (Ahmet)

- [ ] Kullanıcı adı üç platformda aynı: `@wordremai` (dolu ise `@wordrem.app`)
- [ ] Profil fotoğrafı: uygulama ikonu (`WordRemSwiftUI/Assets.xcassets/AppIcon.appiconset`)
- [ ] TikTok: işletme hesabı, kategori "Eğitim"
- [ ] Instagram: profesyonel hesap (içerik üreticisi), bir Facebook sayfasına bağlı (API için şart)
- [ ] X: profil + sabitlenmiş tanıtım paylaşımı
- [ ] İlk 2-3 gün sadece izle, beğen, yorum yap (dil öğrenme içerikleri)

**Bio (TikTok / Instagram):**
> Lupa ile konuşarak İngilizce öğren 🎙️
> Yapay zekâ öğretmenin cebinde, hata yapmak serbest.
> 👇 Çok yakında App Store'da

**Bio (X):**
> WordRem AI: Lupa'yla konuşarak dil öğren. Tek kişilik ekip, geliştirme sürecini burada paylaşıyorum. 🎙️🇹🇷

## Stüdyo ile çekim ve kurgu

Stüdyo modu sadece telefondaki geliştirici (Debug) sürümünde var, App Store sürümünde görünmez. Uygulama sahneyi oynatırken kendi ekranını sesiyle birlikte kaydeder; kayıt ve zaman çizelgesi Mac'e çekilip otomatik kurgulanır.

**Bir kerelik:** Ayarlar → Erişilebilirlik → Oku ve Konuş → Sesler → İngilizce → Ava → "Ava (Premium)" indir. Öğrenci sesi bununla okunur.

**Akış (Claude yürütür):**
1. `video/record.sh s01`: senaryoları telefona yükler, uygulamayı açar, sahneyi başlatır. Telefonda iOS "Ekranı Kaydet" izni sorar, **bir kez dokunulur**. Sahne bitince kayıt Mac'e (`inbox/`) çekilir, `video/edits/s01.json` hazırlanır.
2. Claude `edits/s01.json` içine ilk saniye yazısını, başlığı ve Lupa'nın cümlelerinin Türkçesini yazar (öğrencinin cümlelerinin Türkçesi kartlardan gelir).
3. `cd video && node render.mjs s01` → `video/out/s01.mp4` (1080×1920, 30 fps).

**Elle başlatmak istersen:** Profil → **Stüdyo: sosyal medya kaydı** → senaryo → "Ekranı Kaydet". Telefonu kilitsiz bırak, ekrana dokunma.

**Videoda olanlar:** ilk 2,4 saniyede büyük soru, telefon çerçevesinde gerçek kayıt, konuşmalar arasındaki bekleme anlarının kesilmesi, "Lupa"/"Sen" etiketi, Türkçe altyazı, öğrenci konuşurken karta yakınlaşma, kart gelince "ding", üstte ilerleme çubuğu, ikon ve App Store çağrısıyla kapanış. Şablon: `video/src/Conversation.tsx`. Canlı önizleme: `cd video && npm run studio`.

Senaryoyu değiştirmek ya da yenisini eklemek için `studio/` klasöründeki JSON'u düzenle, Claude telefona gönderir:

```json
{
  "id": "s01",
  "title": "Londra'da kahve",
  "mode": "freechat",
  "opener": "Lupa'nın açılış sorusu: sahneyi kurar",
  "note": "İsteğe bağlı: Lupa'ya bu kayda özel yönerge",
  "voice": "en-US",
  "rate": 0.48,
  "lines": ["@card", "@card", "@card"]
}
```

- `mode`: `freechat` (varsayılan), `goal <bölüm>/<hedef>` veya `demo`.
- `voice`: `en-US`, `en-GB` ya da cihazdaki bir sesin kimliği. `tr-TR` sesi İngilizce cümleyi Türk aksanıyla okur; deneysel.
- `@card`: o an ekrandaki kartı okur, seçenekli kartta ilk seçeneği. Canlandırmalarda bütün replikler `@card`: Lupa sahneyi götürür, kart ve okunan cümle her zaman aynı olur.
- `note`: Lupa'ya bu kayda özel yönerge. Boşsa canlandırma yönergesi geçerli: sahne boyunca sadece İngilizce, çeviri ve övgü yok, kısa ve doğal cümleler, beş tur kadar sonra Lupa sahneyi kapatır.
- Öğrenci veda edince ("have a great day", "bye", "thank you for your time"…) senaryo kendiliğinden biter.
- Serbest cümleler sadece hata ve soru videolarında (s04, s05, s06, s10, s13); orada kartla farklı olması zaten konunun parçası.
- Stüdyo çalışırken ekran kilitlenmez.

## Hashtag setleri

- **Genel:** `#ingilizce #ingilizceöğren #ingilizcekonuşma #yapayzeka #dilöğrenme`
- **Canlandırma:** `+ #yurtdışı #seyahat #ingilizcepratik`
- **Hata:** `+ #ingilizcehataları #gramer`
- **Hikâye:** `+ #girişimcilik #yazılım #indiedev`

Her videoda 4-6 hashtag; fazlası işe yaramıyor.

## Paylaşım temposu

- TikTok: her gün 1 video (ilk 30 gün), akşam 19:00-22:00.
- Instagram Reels: aynı video, TikTok logosu olmadan, aynı akşam.
- X: günde 1-2 kısa paylaşım, haftada bir geliştirme hikâyesi (thread).
