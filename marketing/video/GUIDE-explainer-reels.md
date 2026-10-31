# Rehber: "Claude ile animasyonlu açıklama reel'i" → bizim pipeline

Kaynak: @aygramm.ai'nin 11 sayfalık başlangıç rehberi (PDF, Ahmet'in Downloads klasöründe). Rehber HyperFrames (web sayfasını kare kare videoya çeviren açık kaynak araç) kullanıyor; biz aynı işi Remotion ile yapıyoruz. Araç değiştirmiyoruz, taktikleri alıyoruz.

## Rehberin özü (kısa)

- **Akış:** Fikir → senaryo → prompt → önizleme → MP4. Kurgu programı yok; video kodla yazılır, Claude yazar, insan onaylar.
- **Her şey sese bağlı:** Önce dış ses metni yazılır; sahneler, yazılar ve efektler sesin zamanlamasını takip eder.
- **Senaryo formülü:** sayılı kanca ("Bu 7 şey…") → ters köşe ("7. madde bu videoyu yaptı") → maddeler (ad + tek kısa satır) → çağrı ("Yoruma ANAHTAR yaz, sana … göndereyim"). ~130 kelime ≈ 45–55 sn, cümle başına tek fikir. Claude'dan 3 kanca seçeneği istenir. Metin sesli okunarak kontrol edilir, kısaltmalar söylendiği gibi yazılır.
- **Görünüm:** sıcak kâğıt zemin, üstte söylenen cümle; her kelime **söylendiği an** yumuşakça belirir; cümle başına tek anahtar kelime vurgu renginde italik serif; altta cümlenin anlattığını gösteren hareketli bir kart (uygulama penceresi, kontrol listesi, telefon, sayaç). Yazılar karenin ortadaki %80'inde.
- **Maskot (isteğe bağlı):** köşede, her cümlede poz değiştiren kendi karakterin. Başkasının maskotu/stili birebir kopyalanmaz.
- **Ses:** cümle cümle üretilip birleştirilir; sadece gerçek sessizlik kısaltılır (tek uzun kaydı kesmek kelime sonlarını yer). Ücretsiz yerleşik ses ya da ElevenLabs.
- **Müzik/efekt:** Pixabay (Content ID kayıtlı parçalar hariç), Openverse (CC0, "NonCommercial" değil). Karışım: ses en yüksek, efekt ortada, müzik en altta ve konuşurken kısılır (ducking). Her efekt ekranda görünen bir şeye denk gelir.
- **Süreç:** önce plan + birkaç önizleme karesi, düzeltmeler normal cümlelerle, MP4 en son ("render" denince). Kapak en iyi kareden.
- **Sık hatalar:** müzik yüksek · kelime söylenmeden görünüyor · tek uzun ses kaydını kesmek · yazı kenarda (Instagram düğmeleri örter) · erken render · birinin stilini birebir kopyalamak.
- **İpucu:** her videonun sonunda "öğrendiklerimizi kaydet": bir sonraki video ses, renk ve karışımı hazır bilir.

## Taktik → bizde durum

| Taktik | Durum | Not |
|---|---|---|
| Kodla video, Claude yönetir, insan onaylar | ✅ Var | Remotion (`video/src`), `render.mjs`; Ahmet sadece onaylar |
| Senaryo önce, her şey sese bağlı | ✅ Var (stüdyo/Bob) | Sahne reel'lerinde ses = gerçek kayıt; altyazı sesli bölümlere dağılıyor (`segs`) |
| Kelime söylendiği an belirir | ✅ Var | `Reel.tsx` `tokens()` + `voicedAt()`, Bob'da kelime zamanları |
| Cümle başına tek vurgulu kelime | 🟡 Kısmen | Öğrenilen dil `*yıldız*` ile sarı; serif italik vurgu yok. Açıklama reel'inde Fraunces italik + turuncu kullan |
| Cümle başına hareketli kart (sayaç, liste, telefon) | 🟡 Kısmen | Sahne reel'inde ifade kartı, Bob'da düzeltme kartı. Dış sesli açıklama formatı **yok** → eklenecek |
| Sayılı kanca + ters köşe + madde + çağrı | ➕ Eklenecek | Kancalarımız soru biçiminde. Açıklama reel'i ve slaytlarda sayılı kanca ("4 phrases that make you sound rude") |
| ~130 kelime / 45–55 sn | ❌ Uymuyor (olduğu gibi) | Bizim hedef 15–35 sn. Açıklama reel'inde ~80–90 kelime ≈ 30–35 sn |
| Cümle cümle ses, sadece sessizlik kısalt | ✅ Var | Öğrenci sesi satır satır (`voice.mjs`), `prep.mjs` sadece sessizliği keser, `review.mjs` konuşma kesilmesini yakalar |
| Ücretli ses (ElevenLabs) | ❌ Gerek yok | OpenAI `gpt-4o-mini-tts` zaten var, çok ucuz; açıklama reel'inin dış sesi de bununla |
| Efektler görünen şeye denk | ✅ Var | `Sfx`: kart gelince pop, doğru cevapta sparkle, geçişte whoosh |
| Müzik altta, konuşurken kısılır | ❓ Ahmet'e sorulacak | BRIEF stok müziği yasaklıyor. TikTok'ta ses taslakta Ahmet tarafından seçiliyor. Açıklama reel'i için Pixabay'den Content ID'siz, çok kısık bir zemin denenebilir |
| Önce önizleme kareleri, sonra render | ➕ Eklenecek | Şu an tam render → `review.mjs`. Render öncesi `remotion still` ile kanca/satır/özet kareleri: Mac daha az yorulur, düzeltme hızlı |
| Yazılar ortadaki %80'de | 🟡 Kısmen | Hikâyelerde üst 250/alt 340 px boş. Reel'de otomatik güvenli alan denetimi yok → `review.mjs` telefon karelerine güvenli alan çizgisi |
| Kapak en iyi kareden | 🟡 Kısmen | Kapak = ilk kare (kanca karesi bilerek tasarlandı). Instagram `thumb_offset` kullanılmıyor; Bob gibi ilk karesi zayıf videolarda eklenebilir (bulut worker'ı, deploy Ahmet'te) |
| Başkasını birebir kopyalama, kendi maskotun | ✅ Var | BRIEF: referanstan sadece dil bilgisi alınır. Kendi karakterlerimiz Lupa ve Bob |
| Köşede maskot | ➕ Eklenebilir | Açıklama reel'inde köşede Bob (Gemini kapak karesinden kesilmiş görsel), dudak senkronu yok |
| "Yoruma ANAHTAR yaz, göndereyim" | ➕ Sonra | Hediye (ör. "50 travel phrases" PDF) ve DM'i elle ya da Instagram yorum-özel-yanıt API'siyle göndermek gerekir. Hediye hazır olana kadar çağrı "Kaydet 📌 / yoruma cevabını yaz" |
| "Öğrendiklerini kaydet" | ✅ Var | `marketing/CLAUDE.md`, `BRIEF.md`, `review_log.md` |

## Ne yapacağız (30 Ekim 2026: 1–4 yapıldı)

1. ✅ **Yeni format: açıklama reel'i (`Explainer`).** Telefon kaydı ya da Gemini gerekmez; tamamen Claude üretir. Senaryo `explainers/<id>.json` (cümleler + her cümlenin kartı), dış ses cümle cümle OpenAI TTS, kelimeler söylendikçe belirir, cümle başına bir vurgu, altta kart (❌/✅ cümle, sayaç, sohbet balonu). Koyu zemin + turuncu/sarı (marka) korunur; kâğıt zemin denenebilir.
2. ✅ **Render öncesi önizleme kapısı:** `preview.mjs <id>`: 5–8 kare (kanca, her madde, kapanış) → Claude bakar, gerekirse Ahmet'e gösterir → sonra render → `review.mjs` (değişmedi, zorunlu).
3. ✅ **Güvenli alan denetimi:** `review.mjs` telefon karelerine Instagram arayüzü bölgelerini (sağ düğme sütunu, alt açıklama) yarı saydam çizer; yazı oraya taşıyorsa puan düşer.
4. ✅ **Sayılı kancalar** açıklama reel'i ve slaytlarda; sahne reel'lerinde soru kancası kalır.
5. Müzik ve "yorum anahtarı" kararları Ahmet'in.
