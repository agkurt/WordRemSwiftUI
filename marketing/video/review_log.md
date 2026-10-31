# Eleştiri kaydı

Her render'dan sonra: puanlar (1-10) ve en büyük 3 sorun, zaman damgasıyla. Kriterler `BRIEF.md` içinde.

## es01 · yayındaki sürüm (2026-10-28, temel ölçüm)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 6 | 7 | 5 | 4 | 6 | 7 | 4 |

1. **Konuşma kesiliyor (ses senkronu):** Lupa'nın ilk cümlesinin başı atılmış ("Let's practice…" duyulmuyor, altyazı "¡Hola!"dan başlıyor). 14,98 sn'de "Aquí tienes" sesin üstünden kesilmiş: Lupa etiketi var, yazı yok. 23,84 sn'de öğrencinin vedası yarıda bitiyor.
2. **Çeşitlilik:** 2,5–23,5 sn arası hep aynı kadraj; yeni görsel ödül sadece övgü çıkartmalarında. 8–12 sn arası 4 saniye hiçbir şey değişmiyor.
3. **Kanca:** İlk 2 saniyede kanca yazısı ile altyazı üst üste; göz ikisini birden okumaya çalışıyor.

Düzeltmeler (tr01'den itibaren): `prep.mjs` artık cümle kesmiyor, `review.mjs` kesimi otomatik yakalıyor; altyazı sesli bölümlere dağıtılıyor; sona özet sahnesi ve alt ilerleme çizgisi eklendi.

## tr01 · 1. tur (Ava sesi yerine OpenAI "cedar", 33,9 sn)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 6 | 8 | 7 | 6 | 7 | 8 | 9 |

1. **Kanca:** İlk İngilizce cümle 4,5. saniyede, Lupa'nın Türkçe girişinden sonra ("Ahmet, seninle pasaport kontrolü çalışacağız…"). Cümle kesilemez; sonraki senaryolarda Lupa doğrudan İngilizce cümleyle başlar (BRIEF.md).
2. **Çeşitlilik:** 4–10 sn arası 6 saniye yalnızca altyazı değişiyor. → Lupa öğrenilen dilde konuşurken üstte sarı ifade kartı.
3. **Özet:** Okunuyor ama küçük, alt ve üst boş. → Yazılar büyütüldü.

Konuşma kesilmesi: yok ✓ (otomatik denetim).

## tr01 · 2. tur (ifade kartı, büyük özet, tek iş parçacıklı render)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 7 | 9 | 8 | 8 | 8 | 8 | 9 |

1. **Kanca 7:** Lupa'nın Türkçe girişi kesilemediği için ilk İngilizce cümle 4,5. saniyede. Senaryo notu düzeltildi; bir sonraki çekimde Lupa doğrudan memurun sorusuyla başlayacak. Bu çekimde düzeltilemez.
2. **Render bozukluğu:** 2 eşzamanlı render'da 45. ve 186. kareler döşeme deseniyle bozuk çıktı. `review.mjs`'e bozuk kare denetimi eklendi; render tek iş parçacığına ve PNG ara karelere alındı. Bozuk kare: yok ✓
3. Lupa açılışta öğrenciye adıyla ("Ahmet") hitap ediyor; isimsiz mod bunu engellemedi. Senaryo notuna "isim kullanma" eklendi.

Konuşma kesilmesi: yok ✓

## bob-ep01 · Böcek Bob Londra'da 1 (Gemini videosu, 27,6 sn)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 9 | 8 | 9 | 8 | 8 | 8 | 9 |

1. Denetim ortam sesini (sokak, kafe) konuşma sanıp 4 kesimi işaretledi; konuşma yok (yazıya döküm). Eşik gürültü tabanına göre ayarlandı. Kalan tek uyarı videonun ilk karesi (otobüs sesi), konuşma değil.
2. Dans anında (19,5–24,5 sn) 5 saniye yeni bir şey yoktu → "Bob başardı! 🎉" çıkartması.
3. Düzeltme kartı 4 sn ekranda; Bob'un utandığı an zaten sessiz, kalabilir.

## ex01 · 1. tur (ilk açıklama reel'i, "4 phrases that make you sound rude", 36,1 sn)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 7 | 9 | 6 | 6 | 8 | 8 | 6 |

1. **Ses senkronu:** ✅ doğru cevap, kartın son cümlesi başlarken çıkıyor; ses henüz "Better:", "Try:", "Instead,", "Ask:" diyor (10,0 · 16,5 · 21,5 · 29,5 sn). Yanlışın üstü de daha söylenmeden çiziliyor (13,5 sn). → Doğrusu ilk vurgulu kelime söylenince, çizgi ilk cümlenin vurgulu kelimesinde ("direct", "child"…), yanlış satırı tırnaklı cümle başlarken.
2. **Çeşitlilik / kanca:** 0–3,4 sn kanca kartı dışında hiçbir şey değişmiyor; ilk cümle ekranda yazılmıyor. → İlk cümle de kartın altında kelime kelime yazılır.
3. **Hareket:** zemin ve kart duruyor. → Etkin kart hafifçe süzülür, vurgulu kelime söylenince küçük bir sıçrama yapar.

Konuşma kesilmesi ve bozuk kare: yok ✓

## ex01 · 2. tur (söylenmeden görünmez, kanca altyazısı, süzülen kart, ses +4,6 dB)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 8 | 9 | 8 | 8 | 8 | 8 | 9 |

1. Senkron düzeldi: yanlış satırı tırnaklı cümleyle, çizgi vurgulu kelimede, doğrusu ilk vurgulu kelimede geliyor (7,5 · 9,5 · 11,0 sn).
2. Her maddenin başında ~1 sn boş kart ("Number two:" denirken). Merak uyandırıyor, kalabilir; sonraki açıklama reel'lerinde "Number two:" kısaltılabilir.
3. Ses: TTS sahne kayıtlarından ~5 dB kısıktı (orta -26 dBFS) → dış ses 1,7 kat: orta -21,5, tepe -3,0 dBFS (tr01: -20,8).

Konuşma kesilmesi ve bozuk kare: yok ✓ · güvenli alan: taşma yok

## ex02 · ex03 · ex04 · 1. tur (ex01 2. turun düzeltmeleriyle; uzun kanca başlığı küçülüyor, altındaki cümle kartın tahmini boyuna göre yerleşiyor)

| Video | Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|---|
| ex02 · 3 mistakes in your first conversation · 30,4 sn | 8 | 9 | 8 | 8 | 8 | 8 | 9 |
| ex03 · 4 ways to stop saying very · 34,5 sn | 8 | 9 | 8 | 8 | 8 | 8 | 9 |
| ex04 · 3 things to say when you don't understand · 31,7 sn | 8 | 9 | 8 | 8 | 8 | 8 | 9 |

1. Önizlemede ex02/ex04'ün uzun kanca başlığı alttaki cümleyle çakışıyordu → başlık uzunluğa göre 88/80/72 px, cümle kartın tahmini yüksekliğinin altına. Render'da çakışma yok.
2. Her maddenin başında ~1 sn boş kart (ex01 ile aynı, kabul).
3. ex02'de TTS "Try: I agree" cümlesinde "Try"ı yuttu; Whisper yakaladı, yeniden üretildi.

Konuşma kesilmesi ve bozuk kare: üçünde de yok ✓

## bob-ep09 · "I'm so hot" (Gemini, yatay 16:9 klip, 12,2 sn)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 8 | 8 | 9 | 9 | 8 | 8 | 9 |

1. Gemini klibi yatay verdi (1280×720): Bob solda, teyze sağda. `Bob` kompozisyonuna `pan` eklendi: video 1320 px yüksekliğe büyür, alt/üst bantları bulanık kopyası doldurur, kamera konuşana kayar (Bob → teyze → numara verilirken ikisi → Bob).
2. Düzeltme kartı ekranın ortasında Bob'un donup kalan yüzünü (esprinin kendisi) örtüyordu → kart alt yarıya, karartma 0,55 → 0,3.
3. Altyazı ve kapanış düğmesi sağdaki düğme sütununa taşıyordu → altyazı sağdan 150 px içeride, düğme 40 px yazı.

Konuşma kesilmesi ve bozuk kare: yok ✓

## bob-ep11 · "I have gas!" (Gemini, yatay klip, 10,5 sn)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 8 | 8 | 9 | 9 | 8 | 8 | 9 |

1. Klipte konuşma 1,3–3,9 sn'de bitiyor, 10 sn'nin kalanı aksiyon ve Bob'un bakışı (Ahmet "çok boş" dedi) → baştan 0,9 sn, sondan 1,4 sn kesildi; kapıyı açıp gazeteyle havalandırma (espri) ve Bob'un donması kaldı.
2. Kanca yazısı kasiyerin burnunu kapattığı anın üstündeydi → `hookEnd` (bölüme göre kanca süresi) eklendi, 1,9 sn.
3. Klipteki kamera 2,3 sn'de kesme yapıyor: "gas!" derken Bob kadraj dışındaydı → kaydırma anahtar kareleri kesmeye göre ayarlandı (Bob + şaşkın kasiyer aynı karede).

Whisper "guests" duydu, gpt-4o-transcribe "gas" (doğrusu). Altyazı "gas!". Bob ep09 bu bölümden sonra çıktığı için "Ep. 3" olarak yeniden render edildi.

## bob-ep12 · "Can I have my kiss?" (Gemini, dikey klip, 11,2 sn)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 8 | 8 | 8 | 9 | 8 | 8 | 9 |

1. Konuşma 2,3 sn'de başlıyor → baştan 1,6 sn kesildi.
2. Espri ekranın iki ucunda: kapı görevlisinin dudak uzatması (üst) ve zilin arkasına saklanan Bob (alt). Kart `fix.at: "top"` ile üste alındı ve 7,6 sn'ye ertelendi: dudak uzatma 2,3 sn açıkta kalıyor.
3. Çığlık ("AAAAH!") altyazı olarak eklendi.

Konuşma kesilmesi ve bozuk kare: yok ✓ · Bob ep09 bu bölümden sonra çıkacağı için "Ep. 4" olarak yeniden render edilip buluta yüklendi.

## bob-ep13 · "I like your pants!" (Gemini, dikey klip, 11,8 sn)

| Kanca | Okunurluk | Hareket | Çeşitlilik | Kompozisyon | Marka | Ses senkronu |
|---|---|---|---|---|---|---|
| 8 | 8 | 8 | 8 | 8 | 8 | 9 |

1. Konuşma 0,8–5,8 sn; sonrasında bütün ofis dönüp bakıyor → 0,4–9,4 sn tutuldu.
2. Kart üstte (`at: "top"`), 7,3 sn'de: ofisin dönüp bakması 1,5 sn açıkta, Bob'un donmuş yüzü kart boyunca görünüyor.
3. Whisper "pants" kelimelerine sıfır süre verdi → bitişler sesten elle düzeltildi.

Konuşma kesilmesi ve bozuk kare: yok ✓
