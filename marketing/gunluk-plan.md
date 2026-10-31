# Günlük içerik planı: Instagram + TikTok (@wordremai)

**Tek hesap, herkese; ekrandaki yazılar İngilizce.** İçerik anlamlı A2–B1 İngilizce: öğrencilerin gerçekten yaptığı hatalar ve işe yarayan kalıplar. Türkçe içerik yok (platformun otomatik çevirisi var).

Her gün **1 ana paylaşım (reel ya da slayt) + 3 hikâye**; Bob klibi geldiğinde o gün akşama ikinci bir reel. Açıklama reel'i, slayt ve hikâyeyi Claude tek başına üretir, bu yüzden takvim Ahmet'e bağlı kalmadan en az 1 hafta ileriye dolu tutulur. Ahmet'in işi: Bob klipleri (Gemini), panelde onay, TikTok gelen kutusundaki taslakları paylaşmak, 13:30 anket hikâyesini elle atmak.

## Formatlar

| Format | Neden | Üretim |
|---|---|---|
| 🐜 **Bob in London** | Viral kanca: espri hatanın kendisinden, sonda düzeltme kartı | Ahmet, Gemini (her bölüm yeni sohbet), `bob/scenarios.md` |
| 🎙️ **Lupa sahnesi** | Ürünü gösterir: gerçek AI sohbeti, "ben de söyleyebilirim" hissi | Stüdyo kaydı, bir dokunuş |
| 📚 **Slayt** | Kaydedilir, paylaşılır; algoritmada uzun ömürlü | Claude, `slides/` |
| 🎬 **Açıklama reel'i** (yeni) | Sayılı kanca + dış ses; telefon/Gemini gerekmez | Claude, `explainers/`, `Explainer` |
| 📲 **Hikâye** | Takipçiyi her gün geri getirir, keşfete düşmez | Claude, `stories/` |

## Saatler (TR, UTC+3)

Hesap yeni (30 Ekim: 0 takipçi, reel başına ~110 erişim): algoritma bizi şimdilik takipçisiz kitleye gösteriyor, saatten çok düzen ve kanca belirleyici. Saatler 2026 araştırmalarına göre seçildi ve hedef kitle (Türkiye, Avrupa, Orta Doğu, Hindistan, Latin Amerika) için ortak pencereye oturtuldu:

| Ne | Saat | Neden |
|---|---|---|
| Slayt (carousel) | Hafta içi **12:30** | Besleme paylaşımları öğle arasında iyi (SocialPilot: 13–15; Avrupa 10:30–11:30, Hindistan 15:00) |
| Reel | Hafta içi **19:00** | Akşam penceresi (Iconosquare 18–21, Sociality akşamlar); Avrupa 17–18, Hindistan 21:30, Brezilya 13:00 |
| Reel | Cumartesi **12:30** | Hafta sonu gündüz (Hootsuite TikTok: Cmt 10–18, Buffer: en iyi gün Cumartesi) |
| Reel | Pazar **20:00** | Pazar gecesi en güçlü pencere (Sociality, 335 bin paylaşım: Pazar 20:00–24:00) |
| Hikâye: öğret | **08:30** | Sabah, hikâye şeridi yenilenirken; hikâye 24 saat kaldığı için saat daha az önemli |
| Hikâye: etkileşim | **13:30** | Öğle arası; Ahmet'e ntfy hatırlatır, elle paylaşılır |
| Hikâye: yönlendir | Ana paylaşımdan **30 dk sonra** | Paylaşım yayına girmeden gitmez |

TikTok taslakları Instagram'la aynı anda gelen kutuna düşer; Ahmet'in bildirimi görür görmez paylaşması en iyisi. Takipçi 100'ü geçince Instagram'ın `online_followers` verisiyle saatler hesabın kendi kitlesine göre yeniden ayarlanır (istatistik erişimi zaten açık).

## Haftalık döngü (30 Ekim'den: günde 2 paylaşım)

| Saat | Ne | Üretim |
|---|---|---|
| 12:30 | 🎬 Açıklama reel'i ya da 📚 slayt (sırayla) | Claude |
| 19:00 | 🐜 Bob, her gün (Pazar 20:00) | Ahmet klibi Gemini'de üretir (`bob/scenarios.md`, sıradaki bölüm), kurgu Claude |

Bob klibi o gün gelmezse 19:00 boş kalır; komik olmayan klip takvim dolsun diye atılmaz.

Kural: Her reel'in ilk 2 saniyesinde soru, sayı ya da şaşırtan an olur. Hikâyenin öğret karesi mümkünse günün paylaşımının konusuyla aynıdır.

## Her günün 3 hikâyesi

1. **08:30 Öğret** (otomatik): günün kalıbı, kısa anlamı, Lupa'nın notu.
2. **13:30 Etkileşim** (elle): anket, quiz ya da soru kutusu. API çıkartma ekleyemediği için ntfy görselle hatırlatır, Ahmet telefondan atar.
3. **Yönlendir** (otomatik, ana paylaşımdan 30 dk sonra; Bob olan günlerde Bob için ikinci bir yönlendirme karesi, karede `reel` alanı): kapak + "Watch it / Swipe through it on our profile 👆". Paylaşım yayına girmeden gitmez.

## Bu hafta: 30 Ekim – 6 Kasım 2026 (hepsi hazır ve bulutta zamanlı)

| Gün | Ana paylaşım | Hikâyeler (08:30 öğret · 13:30 etkileşim · yönlendir) | Bob klibi gelirse |
|---|---|---|---|
| Cum 30 | 📚 **sl01** "You're B1… but you still say these 😬" · 12:30 | no cap · quiz · 13:00 | 🐜 **ep11 "I have gas!"** (Ep. 2) · 20:00 ✅ zamanlı |
| Cmt 31 | 🎬 **ex02** "3 mistakes in your first English conversation" · 12:30 | Trick or treat · Halloween anketi · 13:00 · Bob 19:30 | 🐜 **ep12 "Can I have my kiss?"** (Ep. 3) · 19:00 ✅ zamanlı |
| Paz 1 | 🎬 **ex01** "4 phrases that make you sound rude" · 20:00 | I'm into · soru kutusu · 20:30 | |
| Pzt 2 | 📚 **sl02** "Make, do or take? 🤔" · 12:30 | Could I get the bill · quiz · 13:00 | 🐜 **ep09 "I'm so hot"** (Ep. 4) · 19:00 ✅ zamanlı |
| Sal 3 | 🎬 **ex03** "4 ways to stop saying very" · 19:00 | I agree · quiz · 19:30 | |
| Çar 4 | 📚 **sl03** "Same word… different meaning" (false friends) · 12:30 | dream holiday · soru kutusu · 13:00 · Bob 19:30 | 🐜 **ep13 "I like your pants!"** (Ep. 5) · 19:00 ✅ zamanlı |
| Per 5 | 🎬 **ex04** "3 things to say when you don't understand" · 19:00 | I didn't catch that · quiz · 19:30 | |
| Cum 6 | 📚 **sl04** "Bored or boring? 🥱" · 12:30 | boring/bored · quiz · 13:00 | 🐜 ep05 "sympathetic" · 19:00 |

Ahmet'ten: Bob ep03, ep02, ep05 (Gemini, üç ayrı yeni sohbet; prompt'lar `bob/scenarios.md`). Gelmezse takvimde boşluk kalmaz, Bob o günün ikinci reel'i olur.

## Sıradakiler (havuz)

- **Bob:** ep04 lend/borrow · ep07 spend the weekend · ep06 interested · ep08 for/since (`bob/scenarios.md`).
- **Slayt:** sl05 "Prepositions: in / on / at for time" · sl06 "Say vs tell vs speak vs talk" · sl07 "Polite requests at a hotel".
- **Lupa sahnesi:** iş görüşmesi "Tell me about yourself" · restoranda şikâyet · doktorda · yol sormak (`studio/s03, s07, s08, s12` İngilizce yazıyla yeniden).
- **Açıklama reel'i:** "Stop saying *I'm fine*" · "3 mistakes with *since* and *for*" · "4 phrases for your first day at work" · "5 words you're pronouncing wrong".

## Üretim akışı

1. **Senaryo:** Claude yazar, kanca tek satırla Ahmet'e söylenir.
2. **Ham malzeme:** Bob klibi (Ahmet, Gemini) ya da stüdyo kaydı (bir dokunuş) `inbox/`'a.
3. **Kurgu:** `prep.mjs` / Bob için `edits/<id>.json`; render öncesi önizleme kareleri.
4. **Render + `review.mjs`** (zorunlu): bütün puanlar 8+, konuşma kesilmesi sıfır, `review_log.md`'ye yazılır.
5. **Ahmet'e gösterim → "go" → panelde açıklama + zamanlama onayı** → bulut paylaşır.
6. **Ölçüm (kurulacak):** haftalık Instagram rakamları (izlenme, kaydetme, paylaşım, takip); en iyi giden format sonraki haftada artırılır.
