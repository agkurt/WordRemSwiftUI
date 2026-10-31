# Reel yönetmen brief'i

Claude bu videoların yönetmeni, kurgucusu, ses tasarımcısı ve render mühendisidir. Her reel bu brief'e göre yapılır; Ahmet'e göstermeden önce eleştiri döngüsünden geçer.

## Film tek cümlede

Gerçek bir Lupa dersi: izleyici 25-35 saniyede bir sahneyi baştan sona dinler, sonunda "ben de bunu söyleyebilirim" hisseder ve videoyu kaydeder.

## Referanslar

- `refs/` klasörü: beğenilen reel'ler (indirilmiş mp4). Claude önce saniyede 2 kare çıkarıp her planı tarif eder (kaç saniye, nasıl geçiş, yazı nerede), sonra üretir.
- Referanstan **dil bilgisi** alınır (tempo, kesim ritmi, yazı yerleşimi, geçişler); **içerik, karakter, logo** asla alınmaz.

## Görünüm

- Zemin koyu (`#14110F`), sıcak turuncu ve sarı ışıklar. Vurgu turuncu `#C2512F`, öğrenilen dil sarı `#FFD84D`, doğru cevap yeşil.
- Yazı: Montserrat 900, kalın siyah kontur; başlıkta Fraunces. Telefonda 360 px genişlikte okunmalı.
- Kamera: kayıt kartı her satırda hafif yaklaşır ve döner, kesimde kısa bir sıçrama.
- **Yasak:** ekranın ortasında tek başına yazı + gradyan, her şeyin yavaşça belirdiği sakin akış, stok müzik, sahte kullanıcı yorumu.

## Açıklama reel'i (Explainer)

Dış sesli, telefonsuz format (`video/GUIDE-explainer-reels.md`). Sıcak kâğıt zemin + nokta dokusu, mürekkep yazı, vurgu turuncu italik Fraunces. Üstte söylenen cümle (kelimeler söylendiği an aşağıdan belirir), altta cümlenin anlattığı kart: kanca (büyük sayı, kapak), ❌/✅ düzeltme (doğrusu söylendiği an belirir, yanlışın üstü çizilir), kapanış (ikon + CTA). Efekt: kart değişince whoosh, doğrusu gelince sparkle, kapanışta pop; hepsi sesten kısık. Müzik yok (karar Ahmet'te). Akış: `explain.mjs` → `preview.mjs` → `render.mjs` → `review.mjs`.

## Kurgu kuralları

- **Konuşma asla kesilmez.** Lupa'nın ve öğrencinin her cümlesi baştan sona duyulur. Kesimler sadece konuşmalar arasındaki sessizlikte olur (cümleden önce 0,2, sonra 0,35 sn pay). Video kısalacaksa cümle yarıdan değil, bütün olarak çıkar.
- **Lupa ilk cümlede doğrudan öğrenilen dildeki repliği söyler** (ör. "Good morning. What's the purpose of your visit?" yani …). "Seninle şunu çalışacağız" gibi giriş cümlesi yok: kesilemeyeceği için kancayı geciktirir. Senaryo notuna yazılır.
- Öğrenci sesi kurguda OpenAI sesiyle değişir (`voice.mjs`, anahtar `.env` → `OPENAI_API_KEY`); telefondaki Ava sesi susturulur. Her cümle bir kez üretilip `public/voice/` içinde saklanır.
- Lupa'nın sesi ile altyazı aynı anda ilerler: kelimeler sesin olduğu yerlere dağıtılır, susulan yerde altyazı durur.

## Vuruş planı

| Zaman | Ne olur |
|---|---|
| 0:00–0:02 | Kanca: büyük soru + Lupa'nın ilk cümlesi altyazıda. İlk kare kapak olur. |
| 0:02–son | Her 3-5 saniyede yeni bir ödül: kart flaşı, "Sıra sende", övgü + konfeti, sayaç dolması. |
| özet (3,4 sn) | Öğrencinin söylediği cümleler ve anlamları; "📌 Kaydet". |
| kapanış (2,6 sn) | İkon, "WordRem AI", App Store çağrısı. |

Hedef süre 25-35 sn. Sahne 2-3 tur.

## İş akışı ve onay kapıları

Her formatta render'dan önce `node preview.mjs <id>` (ana anlar, güvenli alan kırmızı); karelere bakılır, sorun varsa render edilmeden düzeltilir.


1. **Senaryo:** `studio/<id>.json` (sahne, dil yönü, kanca). Kanca ve sahne Ahmet'e tek satırla söylenir.
2. **Çekim:** `./record.sh <id>`; telefonda bir dokunuş. Kayıt `inbox/`.
3. **Kurgu:** `node prep.mjs <id>` → `edits/<id>.json`; Claude kancayı, anlamları ve öğrenilen dil işaretlerini (`*...*`) yazar.
4. **Render + eleştiri döngüsü** (aşağıda), puanların hepsi 8+ olana kadar.
5. **Teslim:** Ahmet'e video + kontakt sayfası; paylaşım panelinde açıklama.

## Eleştiri döngüsü (her videoda, en az 1 tur)

`node render.mjs <id> && node review.mjs <id>` → `review/<id>/`:

- `contact.png`: saniyede 2 kare, bütün akış
- `cut-*.png`: her kesimin etrafındaki 12 kare (sıçrama, takılma)
- `phone-*.png`: 360 px genişlikte kanca, her satır, özet, kapanış
- `safe.png`: aynı anlar, platform arayüzünün örttüğü bölgeler kırmızı
- `loop.png`: son kare + ilk kare (başa sararken sıçrama)
- `report.md`: **konuşma kesilmesi otomatik denetimi** (sorun varsa komut hata koduyla biter)

Claude kendi işine "gururlu yazar değil, acımasız bir reel yönetmeni" gözüyle bakar ve 1-10 puanlar:

kanca (ilk 2 sn) · telefonda okunurluk · hareket · çeşitlilik (3-5 sn'de yeni ödül) · kompozisyon · marka · ses senkronu

En büyük 3 sorunu zaman damgasıyla `review_log.md`'ye yazar, düzeltir, yeniden render eder. Konuşma kesilmesi sıfır olmadan video teslim edilmez.

## Teslimatlar

`out/<id>.mp4` · `review/<id>/contact.png` · `review/<id>/poster.png` · `publish/posts/<id>.json` (açıklama)
