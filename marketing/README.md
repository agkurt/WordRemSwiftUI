# WordRem sosyal medya — iç araç

Organik büyüme için Instagram ve TikTok, tek hesap: `@wordremai`. Bu klasör içeriğin tek kaynağı: marka rehberi, senaryolar, stüdyo dosyaları, kurgu ve paylaşım. Claude için kurallar ve yapı: `CLAUDE.md`. Haftalık plan: `gunluk-plan.md`.

| Dosya | Ne |
|---|---|
| `CLAUDE.md` | Yapı, kurallar, paylaşım akışı (önce bunu oku) |
| `gunluk-plan.md` | Haftalık döngü ve bu haftanın takvimi |
| `studio/*.json` | Stüdyo modunun oynattığı Lupa sahneleri |
| `bob/` | "Bob in London" bölümlerinin Gemini prompt'ları |
| `explainers/*.json` | Dış sesli açıklama reel'lerinin senaryoları |
| `slides/`, `stories/` | Kaydırmalı gönderiler ve günlük hikâye kareleri |
| `video/` | Remotion kurgu projesi (`BRIEF.md`, `GUIDE-explainer-reels.md`) |
| `publish/`, `cloud/` | Onay paneli ve bulut zamanlayıcısı |
| `content-plan.md` | Eski (Türkçe dönem) fikir listesi; sadece fikir havuzu |

## Kitle ve konum

- **Kitle:** Dünyanın her yerinden A2–B1 seviyesinde İngilizce öğrenen, konuşmaktan çekinen yetişkinler. Okulda İngilizce gördü ama konuşurken donuyor.
- **Dil:** Ekrandaki bütün yazılar İngilizce. Türkçe içerik yok; platformların otomatik çevirisi gerisini yapar.
- **Tek cümlelik vaat:** "Speak without fear. Lupa is waiting."
- **Rakiplerden farkımız:** Duolingo test çözdürür, biz konuşturuyoruz. Kurslar pahalı ve randevulu, Lupa her an cebinde.

## Lupa'nın karakteri

- Sabırlı, sıcak, esprili; asla küçümsemez ve flört etmez.
- Hatayı yüzüne vurmaz, doğrusunu söyleyip devam eder. Videolarda öne çıkan şey bu: "Mistakes are welcome."
- Adı her yerde **Lupa**. Kişi zamiriyle değil adıyla anılır ("Lupa corrected it", "Lupa asked").

## Görsel dil

- Uygulamanın kâğıt rengi (`#F6F2EA`), koyu zemin (`#14110F`), turuncu vurgu (`#C2512F`), sarı (`#FFD84D`). Ayrıntı: `video/BRIEF.md`.
- İlk saniye yazısı: büyük, kalın, en fazla 7 kelime. İlk kare kapak olur.
- Yazılar ortadaki güvenli alanda: Instagram'ın sağ düğmeleri ve alttaki açıklama alanı boş kalır.
- Kapanış: uygulama ikonu, "WordRem AI" ve "Coming soon on the App Store" (onay gelince "Download on the App Store").

## İçerik türleri

1. **Bob in London:** Gemini'de üretilen karınca vlog'u; gerçek bir öğrenci hatası komik bir yanlış anlaşılmaya yol açar, sonda düzeltme kartı.
2. **Lupa sahnesi:** Stüdyo kaydı, Lupa'yla canlandırma (otel, iş görüşmesi, kafe).
3. **Açıklama reel'i:** Sayılı kanca, dış ses, her maddede ❌/✅ kartı.
4. **Slayt:** 5 hata + tek satırlık kural, kaydetmelik.
5. **Hikâye:** Günün kalıbı, anket/quiz, o günün paylaşımına yönlendirme.

Kural: Sahte kullanıcı yorumu ya da var olmayan kişinin hikâyesi yok. Öğrenci sesi senaryodan okunduğunda bu bir canlandırmadır, "our user Anna" gibi sunulmaz.

**Bio (Instagram / TikTok):**
> Learn English by talking with Lupa 🎙️
> Your AI tutor. Mistakes are welcome.
> 👇 Coming soon on the App Store

## Stüdyo ile çekim ve kurgu

Stüdyo modu sadece telefondaki geliştirici (Debug) sürümünde var, App Store sürümünde görünmez. Uygulama sahneyi oynatırken kendi ekranını sesiyle birlikte kaydeder; kayıt ve zaman çizelgesi Mac'e çekilip otomatik kurgulanır. Öğrencinin sesi kurguda OpenAI sesiyle değiştirilir (`video/voice.mjs`), telefondaki ses susturulur.

**Akış (Claude yürütür):**
1. `video/record.sh <id>`: senaryoları telefona yükler, uygulamayı açar, sahneyi başlatır. Telefonda iOS "Ekranı Kaydet" izni sorar, **bir kez dokunulur**. Sahne bitince kayıt Mac'e (`inbox/`) çekilir.
2. `cd video && node prep.mjs <id>` → `edits/<id>.json`; Claude kancayı ve Lupa'nın öğrettiği cümlelerin anlamlarını yazar.
3. `node preview.mjs <id>` (render öncesi kareler) → `node render.mjs <id>` → `node review.mjs <id>` (zorunlu, `video/BRIEF.md`).

**Elle başlatmak istersen:** Profil → **Stüdyo: sosyal medya kaydı** → senaryo → "Ekranı Kaydet". Telefonu kilitsiz bırak, ekrana dokunma.

Şablon: `video/src/Reel.tsx`. Canlı önizleme: `cd video && npm run studio`.

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

- **Genel:** `#learnenglish #englishtips #speakenglish #esl`
- **Hata / gramer:** `+ #englishgrammar #englishmistakes`
- **Seyahat / sahne:** `+ #travelenglish #englishconversation`
- **Bob:** `+ #aivideo #london`

Her paylaşımda 4-6 hashtag; fazlası işe yaramıyor.

## Paylaşım temposu

Günde 1 ana paylaşım (reel 20:00, slayt 19:00, TR saati) + 3 hikâye (09:00, 13:00, 20:00). Ayrıntı: `gunluk-plan.md`.

## Paylaşım paneli

`caffeinate -i node publish/server.mjs` → http://localhost:4747 (`caffeinate` Mac'in uykuya geçip zamanlanmış paylaşımı kaçırmasını önler). Hazır videolar (`video/out`) listelenir; açıklama düzenlenir, her paylaşım panelde tıklamayla başlar.

- **Reel zamanlama:** Kartta tarih/saat seçip "Bu saatte paylaşılsın". Saati gelince Instagram'da Reels olarak yayınlanır, ardından TikTok gelen kutuna taslak gider; Mac bildirimi gelir ve TikTok açıklaması panoya kopyalanır (aynı Apple hesabındaki iPhone'da yapıştırılır). TikTok'ta taslağa dokunup "Paylaş" denir: TikTok kendi hesabına paylaşan iç araçlara doğrudan paylaşım izni vermiyor.
- **Hikâyeler:** `stories/<tarih>.json` → `cd video && node stories.mjs <tarih>` üç kareyi üretir. Panelde "Saatinde paylaşılsın" onaylanınca öğret karesi 09:00'da, yönlendir karesi 20:00'de (o günün reel'i yayındaysa) Instagram'a gider; etkileşim karesi için 13:00'te Mac bildirimi gelir, anket çıkartması API'den eklenemediği için telefondan paylaşılır. Saatler karede `"at": "SS:DD"` ile değişir.

- **Instagram:** "Instagram'da paylaş" Reels olarak yayınlar. Instagram videoyu herkese açık bir adresten çektiği için paylaşım süresince geçici bir Cloudflare tüneli açılır; tünelden yalnızca o videonun tek seferlik adresi erişilebilir, panel ve API kapalıdır.
- **TikTok:** "TikTok'a taslak gönder" videoyu TikTok gelen kutusuna yükler; ses seçip paylaşmayı TikTok uygulamasında yaparsın.
- **Anahtarlar:** `.env.example` → `.env` (repoya gönderilmez). TikTok oturumu `publish/tokens.json` içinde (repoya gönderilmez).
- Açıklamalar `publish/posts/<id>.json` içinde saklanır.
- **Bulut:** `.env`'de `CLOUD_URL` ve `CLOUD_TOKEN` doluyken onaylanan işleri Mac yerine bulut zamanlayıcısı (`cloud/`, https://publish.wordremai.app) paylaşır; Mac kapalı olabilir. Bildirimler (TikTok taslağı açıklaması, 13:00 anket görseli) telefona ntfy ile gelir.
