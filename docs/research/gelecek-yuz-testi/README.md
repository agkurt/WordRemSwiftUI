# Gelecekteki Yüz: reklam testi kiti (2026-10-31)

**Amaç:** Uygulamayı yazmadan önce iki soruya cevap almak:
1. Bu fikir sosyal medyada kendiliğinden yayılıyor mu?
2. İnsanlar fiyatı gördükten sonra da "istiyorum" diyor mu?

**Ad (2026-10-31'de kesinleşti):** **Face Forecast**, yani "yüzünün hava durumu".
- **Mağaza başlığı:** `Face Forecast: Future Self AI`
- **Kısa açıklama:** `Your sleep, steps & screen time redraw your future face every morning.`
- **Hesaplar:** `@faceforecast`
- **Alan adı:** `faceforecast.app` / `.com`. DNS kaydı görünmüyor; satın almadan önce doğrula.
- Marka (trademark) araştırması yapılmadı.

**Önemli:** Bu test **@wordremai hesabında yapılmaz.** Yeni ve ayrı bir TikTok + Instagram hesabı açılır (ör. `@faceforecast`). WordRem'in kitlesi dil öğrenenler; bu içerik oraya uymaz, sonuçları da bozar.

---

## 1. Hook'lar (3 farklı açı)

Her hook ayrı bir reklam ve ayrı bir UTM ile ölçülür. Ekrandaki yazılar İngilizce.

| Kod | Açı | İlk 2 saniyede ekranda | Kime hitap ediyor |
|---|---|---|---|
| **H1** | Ekran süresi korkusu | **"My screen time was 9h 12m. This is what it did to my face at 50."** | 18–30, telefon bağımlılığından şikâyetçi olanlar |
| **H2** | İki gelecek | Bölünmüş ekran: **"Me at 50 if I keep sleeping 5 hours"** / **"Me at 50 if I sleep 8"** | Kendini geliştirmeye meraklı 22–35 |
| **H3** | Deney / meydan okuma | **"I let my phone age my face every morning based on my habits. Day 1."** | Seri içerik takipçileri, merak edenler |

Yedek hook'lar (ilk üçü tutmazsa):
- "POV: your phone sends you a picture of your future face every morning"
- "Stopped doomscrolling for 7 days. Watch my future face heal."

---

## 2. 7 günlük organik seri

Her video 20–30 saniye ve aynı iskeleti izler:
1. **0–2 sn:** kanca yazısı + gelecekteki yüz (en çarpıcı kare ilk karede)
2. **2–8 sn:** dünkü veri kartı (ekran süresi, uyku, adım). iPhone Ekran Süresi ve Sağlık ekran görüntüleri yeterli.
3. **8–18 sn:** bugünkü yüzün açılması (blur'dan net hale geçiş ya da kazıma efekti), yanında "dünden farkı"
4. **18–25 sn:** tek cümlelik ders ya da yarının hedefi
5. **Son 3 sn:** "Building this as an app. Link in bio for early access."

| Gün | Konu | Senaryo |
|---|---|---|
| 1 | Başlangıç (H3) | "Day 1. Phone age-my-face experiment." Bugünkü gerçek selfie, yanında 20 yıl sonraki yüz. Veri: gerçek ekran süren ve uykun. "Every morning my habits redraw this face. Let's see what happens." |
| 2 | Kötü gece | Gece geç saate kadar telefonda kal (ya da gerçek bir kötü geceyi kullan). Yüz kötüleşir: gözaltı, solgunluk. "2am scrolling. Future me is not happy." |
| 3 | İki gelecek (H2) | Bölünmüş ekran: "keep going like this" / "8h sleep + 8k steps". "Same face. Two futures. I get to pick." |
| 4 | Deney başlıyor | "No phone after 10pm for 3 days." Yatak odası dışında şarj eden telefon görüntüsü. Yüz hafifçe toparlanır. |
| 5 | Adım | 10.000 adım. Yüzün rengi ve duruşu düzelir. "Walked 10k steps. Future me got colour back." |
| 6 | Yorumlardan | Önceki yorumlardan biri seçilir: "You said I should try X. Here's what happened." Etkileşim döngüsü kurar. |
| 7 | Timelapse + çağrı (H1) | 7 günün yüzleri art arda, başı ve sonu yan yana. "Screen time 9h → 4h. This is the difference." Güçlü çağrı: "I'm turning this into an app. Join the waitlist, link in bio." |

**Altyazı (her videoda):** "AI visualisation for motivation, not a medical prediction." Paylaşırken platformun AI etiketi işaretlenir.

**Paylaşım:** TikTok + Instagram Reels + YouTube Shorts. Hafta içi akşam saatleri.

---

## 3. Yüz üretimi (Gemini aboneliğiyle, API ücreti yok)

Bob'da olduğu gibi Gemini Pro aboneliğinde, **tek bir sohbette** üret. Aynı sohbet, aynı referans fotoğraf yüzün kimliğini korur.

**Kurulum mesajı (bir kez):**
> I'm making a motivational series about how daily habits could affect my face over time. Here is my reference selfie. Keep my identity, face shape, eye colour, hair line and features exactly the same in every image. Every image must look like the same real person, photographed in the same soft daylight, same angle, neutral background, photorealistic, no text, no watermark.

**Ana kareler (kurulumdan sonra, bir kez):**
> Show me at age {yaş + 20}, healthy version: 8 hours of sleep, active, low screen time. Natural ageing only, bright skin, rested eyes, good posture.

> Show me at age {yaş + 20}, unhealthy version: 5 hours of sleep for years, 9+ hours of screen time a day, inactive. Dark under-eyes, dull and puffy skin, forward head posture, tired expression. Realistic, not a horror effect.

**Günlük kare:**
> Same person, age {yaş + 20}. Yesterday's data: sleep {x} hours, screen time {y} hours, steps {z}. Compared with the previous image, make the change small and believable: {daha iyi / daha kötü}, mainly {gözaltı / cilt parlaklığı / duruş}.

**Kurallar:**
- Değişiklikler küçük ve inandırıcı olmalı. Abartılı "korku filtresi" güveni yok eder.
- Son kareyi bir sonraki günün referansı olarak kullan.

---

## 4. Bekleme listesi sayfası

Dosya: `landing/index.html`. Tek dosya, dış bağımlılık yok.

**Yayına almak için:**
1. **Form:** Ücretsiz bir Tally formu aç (tally.so). Sorular:
   - E-posta (zorunlu)
   - "Which phone do you use?" → Android / iPhone
   - **Fiyat sorusu:** "At launch, which would you pick?"
     - £3.99/week with a 3-day free trial
     - £29.99/year with a 3-day free trial
     - Only if it's free
   - Gizli alanlar: `utm_source`, `utm_campaign`, `utm_content`
2. Formun adresini `index.html`'deki `FORM_URL` satırına yaz. Sayfa, gelen UTM parametrelerini forma otomatik aktarır.
3. `img/today.jpg` (bugünkü yüz) ve `img/better.jpg` (iyi gelecek) dosyalarını kendi ürettiğin görsellerle koy. Görsel yokken sayfa yer tutucu gösterir.
4. **Yayın:** Cloudflare Pages'e `landing/` klasörünü sürükle-bırak (ücretsiz), ya da istediğin bir alan adı. Deploy'u sen yaparsın.

**Bağlantılar (her kanal ve hook ayrı):**
- TikTok bio: `?utm_source=tiktok&utm_campaign=organic`
- Instagram bio: `?utm_source=instagram&utm_campaign=organic`
- Reddit gönderisi: `?utm_source=reddit&utm_campaign=organic&utm_content=<subreddit>`

---

## 5. Sıfır bütçeli dağıtım (ücretli reklam yok)

Para harcanmıyor. Ücretli reklamın vereceği sinyali şu ücretsiz kanallardan toplarız:

- **Üç platform aynı anda:** Her video TikTok, Instagram Reels ve YouTube Shorts'a gider. Yeni hesapların ilk videolarına algoritma deneme gösterimi verir; ilk sinyal oradan gelir.
- **Hook testi:** İlk 3 gün H1, H2 ve H3 ayrı videolar olarak yayınlanır. Hangisi daha çok izlenir ve kaydedilirse seri onunla devam eder. Ücretli A/B testinin ücretsiz hali bu.
- **Reddit (en güçlü ücretsiz kanal):**
  - Hedef topluluklar: r/nosurf, r/digitalminimalism, r/sleep, r/selfimprovement, r/getdisciplined.
  - Reklam dili yok. "Bir hafta boyunca ekran sürem gelecekteki yüzümü nasıl değiştirdi" diye deneyi anlatan bir gönderi, görseller ve sonunda tek bir link.
  - Önce her topluluğun self-promo kuralını oku. Bazılarında link sadece yorumda serbest.
- **Yorumlara cevap videoyla:** "app?" diye soranlara 6. günde videoyla cevap verilir (TikTok'un "yorumu videoyla yanıtla" özelliği). Bu, ücretsiz erişimi en çok artıran şey.
- **İsteğe bağlı, sonra:** Organik sonuçlar "belirsiz" çıkarsa ve sen istersen, en iyi videoya £10–20'lik TikTok Promote. Şart değil.

---

## 6. Karar eşikleri

Bu eşikler benim önerim; sektör standardı değil. Testten önce birlikte netleştirelim.

| Metrik | Nereden | **Devam** | Belirsiz | **Bırak** |
|---|---|---|---|---|
| Organik: en iyi videonun izlenmesi (7 gün) | TikTok / IG istatistikleri | ≥ 20K | 3–20K | < 3K (hepsi) |
| Organik: "app/link?" yorumu | Yorumlar | ≥ 30 | 10–30 | < 10 |
| Organik: kaydetme + paylaşım / izlenme | TikTok / IG istatistikleri | ≥ %3 | %1–3 | < %1 |
| Reddit: en iyi gönderinin oyu | Reddit | ≥ 200 | 50–200 | < 50 (hepsi) |
| Sayfa → form doldurma | Tally / Cloudflare ziyaret sayısı | ≥ %20 | %10–20 | < %10 |
| Toplam kayıt (10 gün) | Tally | ≥ 150 | 50–150 | < 50 |
| **Fiyat sorusunda ücretli seçenek** (haftalık + yıllık) | Tally | **≥ %35** | %20–35 | < %20 |
| Android oranı | Tally | Bilgi amaçlı: Android önce mi iOS önce mi kararı için | | |

**Karar kuralı:**
- **Fiyat sorusu en önemli eşik.** Viral izlenme ama ödeme isteği düşükse ürün eğlenceli bir filtre olarak kalır ve para getirmez.
- En kazançlı hook, uygulamanın ilk ekranı ve mağaza görselleri olur.
- Testin bırakması gereken çıktılar:
  - en iyi hook
  - hangi kanalın kayıt getirdiği (UTM)
  - Android/iPhone oranı
  - fiyat tercihi

---

## Sırayla yapılacaklar

1. Yeni TikTok ve Instagram hesabı (sen).
2. Gemini'de referans selfie ve ana kareler (sen, 15 dk).
3. Tally formu, sayfanın yayına alınması (sen, 20 dk).
4. Gün 1–7 videoları. İstersen kurguyu Remotion hattında ayrı bir kompozisyonla ben hazırlarım. Görseller ve veri ekran görüntüleri sende.
5. 4. ya da 5. günde Reddit gönderileri (deneyin ilk sonuçlarıyla, en iyi giden hook'un görselleriyle).
6. 10. gün sonuçlar bu tabloya göre değerlendirilir. Toplam maliyet: £0.
