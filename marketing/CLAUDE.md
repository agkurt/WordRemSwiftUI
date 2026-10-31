# marketing/

WordRem AI'ın sosyal medyası (İngilizce ve dil öğrenme uygulaması, sesli öğretmen **Lupa**). Uygulama App Store incelemesinde: çağrılar "Coming soon on the App Store". Onay gelince bütün CTA'lar "Download on the App Store" olur ve yeniden render edilir.

Ahmet'le Türkçe konuş ("kanka" tonu). Maliyet en az olsun; işi mümkün olduğunca Claude yapsın.

## Yön (29 Ekim 2026'dan beri)

- **Tek hesap:** Instagram + TikTok `@wordremai`, herkese hitap eder. **Ekrandaki yazılar İngilizce**; çeviriyi platformların otomatik çevirisi yapar. Türkçe içerik yok.
- **İçerik anlamlı A2–B1 İngilizce:** öğrencilerin gerçekten yaptığı hatalar, işe yarayan kalıplar. Ucuz espri yok; espri hatanın kendisinden doğar.
- `README.md`'nin "Kitle", "Dil", "Hashtag", "X" ve Ava sesi bölümleri **eski** (Türkçe dönem). Geçerli olan bu dosya ve `gunluk-plan.md`.

## Formatlar

| Format | Nasıl üretilir | Süre | Kompozisyon |
|---|---|---|---|
| **Lupa sahnesi** | Uygulamanın DEBUG Stüdyo modu telefonda sahneyi oynatıp kaydeder (`studio/<id>.json`, `video/record.sh <id>`), Ahmet bir kez "Ekranı Kaydet"e dokunur | 21–34 sn, 3 tur | `Reel` |
| **Bob in London** | Ahmet Gemini Pro aboneliğinde üretir, **her bölüm yeni sohbet**, prompt'lar `bob/scenarios.md`. Klip `inbox/bob/` | 14–18 sn, az yazı | `Bob` |
| **Slayt (carousel)** | `slides/<id>.json` → `node slides.mjs <id>` (TikTok 9:16 + IG 4:5) | 7 kare | `Slide` |
| **Hikâye** | `stories/<tarih>.json` → `node stories.mjs <tarih>` | günde 3 kare | `Story` |
| **Açıklama reel'i** | Tamamen Claude: senaryo `explainers/<id>.json` → `node explain.mjs <id>` (dış ses cümle cümle OpenAI TTS, kelime zamanları Whisper) | 30–36 sn | `Explainer` |

## Klasörler

- `studio/*.json`: stüdyo senaryoları. Yeni senaryo `native: "en"` (izleyici İngilizce konuşur). `s01–s13` Türkçe başlıklı eski dönem; İngilizce yazı ile yeniden kullanılabilir.
- `inbox/`: telefondan/Gemini'den gelen ham kayıt (git'e girmez).
- `video/`: Remotion projesi.
  - `prep.mjs <id> [--skip a-b]` → `edits/<id>.json` (kesimler, satırlar, öğrenci sesi OpenAI'dan)
  - `explain.mjs <id> [--voices a,b]` → açıklama reel'inin `edits/<id>.json`'u; `--voices` ilk cümleyi birkaç sesle `out/voices/`'a yazar (Ahmet seçer). TTS kelime yutarsa Whisper yakalar, 3 kez yeniden üretir, olmazsa durur: cümleyi yeniden yaz ("Say:" gibi başlangıçları TTS talimat sanabiliyor)
  - `preview.mjs <id> [saniye…]` → `preview/<id>/sheet.png`: render öncesi ana anlar, arayüz bölgeleri kırmızı
  - `voice.mjs`: öğrenci sesi `gpt-4o-mini-tts`, ses `cedar`; anahtar `marketing/.env` → `OPENAI_API_KEY`; önbellek `public/voice/`
  - `render.mjs <id> [kompozisyon]` → `out/<id>.mp4` (tek iş parçacığı, PNG ara kare; kompozisyon kurgu dosyasından seçilir)
  - `review.mjs <id>` → `review/<id>/` (contact, cut-*, phone-*, safe, loop, poster, report.md)
  - `stories.mjs`, `slides.mjs`; `src/`: `Reel`, `Bob`, `Explainer`, `Story`, `Slides`, `Sheet` (review/preview ızgarası, `safe` ile arayüz bölgeleri), `Conversation` (sade, eski), `types.ts` (`UI` metinleri, süreler, `SAFE` bölgeleri)
  - `BRIEF.md`: yönetmen brief'i (görünüm, kurgu kuralları, vuruş planı). `review_log.md`: her render'ın puanları.
- `explainers/*.json`: açıklama reel'i senaryoları. Her `beat` bir kart (`hook`, `fix`, `cta`) ve o kartta söylenen cümleler (`say`); `*yıldızlı*` kelime turuncu italik. Sayılar yazıyla ("four"), cümle başına tek fikir, ~80–90 kelime. Açıklama metni `caption`.
- `bob/`: `ep01.md` (yayında), `scenarios.md` (ep02–ep08 prompt'ları ve önerilen sıra).
- `publish/`: onay paneli. `caffeinate -i node publish/server.mjs` → http://localhost:4747. Açıklamalar `posts/<id>.json`, hikâye kayıtları `publish/stories/`.
- `cloud/`: Cloudflare Worker zamanlayıcısı `wordrem-social` (https://publish.wordremai.app). 5 dakikada bir cron, durum KV'de. Panel onaylı işi ve dosyayı buluta yazar; Mac kapalıyken de paylaşır.

## Paylaşım akışı

- **Reel:** saati gelince Instagram Graph API ile Reels olarak yayınlanır, sonra TikTok'a gider.
- **TikTok sadece gelen kutusu taslağı** kabul ediyor: video ve fotoğraflı gönderiler Ahmet'in TikTok **Inbox**'ına düşer (profil taslaklarına değil). ntfy telefona açıklamayla bildirim atar; Ahmet ses seçip paylaşır.
- **Saatler:** `gunluk-plan.md` → "Saatler" (slayt 12:30, reel hafta içi 19:00, Cmt 12:30, Paz 20:00).
- **Hikâyeler:** 08:30 öğret (otomatik), 13:30 anket/quiz (API çıkartma ekleyemez: ntfy görselle hatırlatır, **Ahmet elle paylaşır**), yönlendir günün paylaşımından 30 dk sonra (otomatik; `stories/<tarih>.json` → `reel` alanı reel ya da slayt kimliği, yayına girmeden gitmez).
- **Takvim en az 1 hafta ileriye dolu tutulur:** açıklama reel'i, slayt ve hikâyeyi Claude tek başına üretir; Bob ve Lupa sahnesi ek reel olarak eklenir.
- **İstatistik:** Instagram token'ı istatistik okuyabiliyor (`/{media-id}/insights`: reach, views, saved, shares; `online_followers`). Haftalık ölçüm buradan.
- **Slayt:** IG carousel otomatik, TikTok fotoğraf taslağı gelen kutusuna.
- **TikTok sonucu:** worker taslağın durumunu her turda sorar; "TikTok taslağı hazır" bildirimi ancak taslak gelen kutusuna düşünce gelir, düşmezse sebebiyle hata bildirimi gelir. Slayt görselleri TikTok onları çekene kadar bulutta tutulur. Taslak profildeki Taslaklar'a değil, TikTok **Gelen Kutusu'na bildirim** olarak düşer; Ahmet'e "bulamıyorum" derse önce oraya ve hangi hesapta olduğuna baktır (30 Ekim'de ikisi de oradaydı).
- **TikTok'u yeniden göndermek:** `node publish/resend-tiktok.mjs <id>` (Instagram'a dokunmaz, `tiktokOnly` iş).
- Bulut işlerini görmek: `publish/cloud.mjs` → `jobs()` (salt okunur).

## Kurallar

- **Konuşma asla cümle ortasından kesilmez** (Lupa, öğrenci, Bob, dış ses). Kısaltmak gerekirse bütün cümle çıkar.
- **Her render'dan sonra `node review.mjs <id>` zorunlu.** `review/<id>/` karelerine kendin bak, `review_log.md`'ye 7 puanı ve en büyük 3 sorunu yaz, düzelt. Ahmet'e göstermeden önce bütün puanlar 8+ ve konuşma kesilmesi sıfır.
- **Render'dan önce `node preview.mjs <id>`:** kapak, her satır/cümle, kapanış tek ızgarada. Render yavaş, düzeltme hızlı; Mac'i yorma.
- **Güvenli alan** (`types.ts` → `SAFE`): üst 220, alt 420 piksel ve 900. pikselden aşağıda sağdaki 140 piksel boş kalır. `preview` ve `review` karelerinde kırmızı görünür; yazı kırmızıya taşmaz. (Bob ep01'in altyazısı sağ sütuna taşıyor: sonraki bölümlerde daralt.)
- **Her kelime söylendiği an belirir**, önce değil. Cümle başına tek vurgu.
- **Ses karışımı:** konuşma en yüksek, efekt ortada, (varsa) müzik en altta ve konuşurken kısık. Her efekt ekranda bir şeye denk gelir. Stok müzik şimdilik yok (BRIEF); TikTok'ta sesi Ahmet seçer.
- Videoya "AI generated" yazısı konmaz; Ahmet paylaşırken platformun AI etiketini işaretler.
- Sahte kullanıcı yorumu, var olmayan kişi hikâyesi yok. Canlandırma canlandırma olarak sunulur.
- Referans reel'lerden sadece dil bilgisi (tempo, yerleşim, geçiş) alınır; stil/maskot birebir kopyalanmaz.
- **Ahmet "go" demeden render, paylaşım ya da zamanlama yok.** Panelde onay her zaman Ahmet'in.
- `.env` ve `publish/tokens.json` içeriği asla yazdırılmaz.
- `wrangler deploy` Claude çalıştıramaz; worker değişince Ahmet deploy eder.
- Mac'i simülatörle yorma. Tarayıcı gerekirse Ahmet'in **kişisel** Chrome'u (iş profili değil).
- Uygulama kodu ve `server/voice-worker` başka oturumların; burada dokunulmaz.
- Paralı API yerine abonelikle yapılabilen yol seçilir (Bob = Gemini aboneliği).

## Rehberden öğrenilenler (`video/GUIDE-explainer-reels.md`)

- Her şey sese bağlı: önce metin/ses, sonra görüntü.
- Sayılı kanca ("4 phrases that make you sound rude") açıklama reel'i ve slaytlarda; sahne reel'inde soru kancası.
- Ses cümle cümle üretilir; birleştirmede sadece gerçek sessizlik kısalır.
- Kapak ilk kare (kanca karesi bunun için tasarlanır); zayıfsa Instagram `thumb_offset` ile en iyi kare.
- Her işin sonunda öğrenileni buraya, `BRIEF.md`'ye ya da `review_log.md`'ye yaz.
