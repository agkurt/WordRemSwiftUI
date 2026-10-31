# Dar ve tutkulu topluluklar için niş uygulama fikirleri (v6, 2026-10-31)

Bu belge sadece fikir araştırması. Kod yazılmadı, hesap açılmadı. Pazar odağı UK + global.

## Bu turun kuralı

Kitlesel tüketici uygulaması yok. Seçtiğim her niş şu özellikleri taşıyor:

1. **Küçük ama para harcayan bir topluluk.** Pilot, denizci, tercüman, tırmanıcı gibi.
2. **Somut kanıt.** Mevcut uygulamanın kötü yorumları ya da ödenen yüksek ücretler.
3. **Oyun gibi pratik.** Yapay zekâ, rakip ya da hakem rolünde.

Play verileri UK mağazasından 2026-10-31'de çekildi.

---

## 1. Pilotlar için yapay zekâ kule simülatörü (ATC telsiz pratiği)

- **Kitle:**
  - ABD'de **370.286 aktif öğrenci pilot** var (FAA, 2025). Bu sayı 2020'de 222.629'du.
  - UK'de PPL öğrencileri telsiz sınavı FRTOL'a giriyor. Dünyanın geri kalanında ICAO kurallarıyla eğitim alanlar var.
  - En korkulan konu telsiz konuşması. Uçuş saati çok pahalı olduğu için insanlar yerde pratik yapmak istiyor.
- **Kanıt:**
  - **ARSim (PlaneEnglish): 100K+ kurulum, 2,8 puan.** Yorumlar: "ses tanıma çok hatalı", "iptal ettim, yine de 95 $ çektiler", "lisansımı aktive etmiyor".
  - **Comms: AI Pilot Training: 10K+ kurulum, 4,4 puan.** Ama yorumlar: "net konuşmamı anlamıyor", "gerçek ATC'ye hiç benzemiyor, kötü alışkanlık kazandırır".
  - UK'ye özel G-UDRT 1K+ kurulumda.
  - Pilotlar bu iş için 95 $ ödüyor ve ürünler kötü.
- **Oyun:**
  - Gerçek bir havalimanında, örneğin Biggin Hill veya Elstree, gerçek frekans ve prosedürlerle uçuş senaryoları.
  - Yapay zekâ kule, yaklaşma ve diğer trafik rolünü oynar. Önce cevabın kontrol edilir (readback), sonra sıra sana gelir.
  - Puanlar: doğru frazeoloji, çağrı işareti, kısa ve net konuşma.
  - Seviyeler: devreler, kontrollü hava sahası, acil durum (MAYDAY / PAN), yabancı aksanlı kule.
  - Kurallar seçilebilir: UK (CAP 413), FAA veya ICAO.
- **Neden biz:** WordRem'in gerçek zamanlı ses altyapısı (konuşma girişi, ses çıkışı, katı kurallara göre değerlendirme) bu iş için birebir uygun. Rakiplerin zayıf noktası tam olarak ses tanıma ve gerçekçilik.
- **Gelir:** Aylık 15–25 $ ya da "sınav paketi". Bu kitle pahalı uçuş saatine kıyasla bunu ucuz bulur.
- **Süre:** 4–6 hafta. Frazeolojinin doğruluğu için bir pilot veya eğitmen danışman şart.
- **Ek modül:** **Denizciler için VHF/SRC telsiz pratiği.** Aynı motor kullanılır.
  - UK'de tekne VHF telsizi kullanmak için SRC belgesi gerekiyor.
  - Lider uygulama VHF Trainer Lite 50K+ kurulumlu ama **2016'dan beri güncellenmiyor**.
  - Ek iş yaklaşık 2 hafta.

## 2. Tercüman adayları için pratik simülatörü

- **Kitle:** Mahkeme, polis ve NHS için tercümanlık sınavlarına (UK'de DPSI, CIOL) hazırlananlar ve topluluk tercümanları. Global olarak tercümanlık öğrencileri.
- **Kanıt:**
  - Play'deki tek ciddi araç Interpretrain (5K+). "Interpreter Practice Generator" ise 2022'den beri güncellenmiyor.
  - Gerisi tercüman bulma uygulamaları.
  - Sınav ve kurs ücretleri yüksek, pratik materyali kıt.
- **Oyun:**
  - Yapay zekâ iki dilde gerçekçi bir sahne kurar ve konuşmacıları seslendirir. Örnek: polis ifadesi, doktor-hasta görüşmesi, kira mahkemesi.
  - Sen ardıl çeviri yaparsın. Sistem eksik bilgiyi, yanlış terimi ve hızı puanlar.
  - Alan sözlükleri ve "boss" seviyeleri var: hızlı konuşan avukat, aksanlı hasta, duygusal tanık.
- **Gelir:** Aylık abonelik ya da sınav paketi. Dil çifti başına içerik.
- **Süre:** 4 hafta. Ses altyapısı hazır; iş, sahne üretimi ve değerlendirme mantığında.
- **Risk:** Pazar küçük. Önce en kalabalık dil çiftleriyle başlanmalı (İngilizce ile Lehçe, Rumence, Arapça, Urduca).

## 3. Ev tırmanma duvarı ve board koçu

- **Kitle:** Evinde veya garajında tırmanma duvarı (home wall) olanlar ve board üzerinde antrenman yapan tırmanıcılar. Küçük ama çok tutkulu ve harcama yapan bir kitle.
- **Kanıt:**
  - **Kilter Board'un resmî uygulaması: 50K+ kurulum, 1,8 puan.** Yorumlar: "açılmıyor", "giriş yapamıyorum", "arama dayanılmaz yavaş".
  - **Vertical-Life: 100K+ kurulum, 2,4 puan.** Yorumlar: "çevrimdışı çalışmıyor", "rotayı kaydedemiyorum".
  - Özel duvarlar için Stōkt var (100K+, 4,0) ama rotaları elle çiziyorsun.
- **Oyun:**
  - Duvarının fotoğrafını çekersin. Yapay zekâ tutamakları bulur.
  - "40 derece eğimde V4, kroşe ağırlıklı" dersin, sistem otomatik derecelendirilmiş bir problem üretir.
  - Arkadaşlarla merdiven ligi, haftalık meydan okumalar.
  - Antrenman programı, kendi duvarındaki problemlerden oluşur.
- **Gelir:** Aylık ya da yıllık abonelik. Bu kitle antrenman uygulamalarına ödüyor (Crimpd 100K+, 4,7).
- **Süre:** 4–5 hafta. En zor kısım fotoğraftan tutamak tespiti; Gemini'nin görüntü yeteneğiyle hızlıca test edilebilir.
- **Risk:** Kilter, Tension gibi ticari board'lara bağlanmak lisans ve kullanım şartları yüzünden riskli. Önce sadece ev duvarlarıyla başlanmalı.

## 4. Tip 1 diyabetli çocuklar için karbonhidrat tahmin oyunu

- **Kitle:** Tip 1 diyabetli çocuklar ve aileleri.
  - Her öğünde karbonhidrat sayılıyor ve insülin dozu buna göre ayarlanıyor.
  - Çocuğun bu beceriyi zamanla kendisinin kazanması gerekiyor.
- **Kanıt:**
  - UK'de Carbs & Cals uygulaması 100K+ kurulumla bu ihtiyacın büyüklüğünü gösteriyor.
  - Carbetic (3D karbonhidrat sayacı) 10K+ ve 4,8.
  - Ama hiçbiri çocuğa yönelik bir **beceri oyunu** değil. Hepsi yetişkinlere hesap aracı.
- **Oyun:**
  - Gerçek yemeğin fotoğrafı çekilir.
  - Çocuk önce **tahmin eder**: "bu tabak kaç gram karbonhidrat?". Sonra yapay zekâ ve besin veritabanının tahmini gösterilir.
  - Tahmin isabeti puanlanır, seviye atlanır, rozetler kazanılır.
  - Diyabet hemşiresi ve aile ilerlemeyi görür.
- **Gelir:** Aile aboneliği. Diyabet vakıfları ve NHS diyabet ekipleriyle iş birliği ve dağıtım.
- **Süre:** 3–4 hafta.
- **Risk:** Tıbbi. Uygulama doz önermemeli, sadece "tahmin becerisi" eğitmeli; açık bir uyarı şart. Çocuk verisi için Play'in Aile politikası geçerli.

---

## Önerim

**1 (pilot telsiz simülatörü)** açık ara önde:
- Kitle büyük (yalnızca ABD'de 370 bin öğrenci pilot) ve çok para harcıyor.
- Mevcut ürünler kötü: 2,8 puan, ses tanıma şikâyetleri, iade kavgaları.
- **Elimizdeki en güçlü varlık olan gerçek zamanlı ses altyapısı tam olarak bu ürünün eksik parçası.**
- Denizci VHF modülüyle ikinci bir pazar aynı motorla açılır.

Doğrulama için ilk adım: Bir öğrenci pilot ya da uçuş eğitmeniyle 2 senaryo (Elstree devresi ve kontrollü hava sahasından geçiş) DEBUG sürücüsüyle denenir. Ses tanıma ve frazeoloji puanlaması gerçekten rakiplerden iyi mi, o anlaşılır. Sonra r/flying ve r/flighttraining'de bekleme listesi açılır.

---

## Elenenler (bu tur)
- **Dart:** DartCounter 1M+ ve 4,8; kamerayla otomatik skor tutan Autodarts da var.
- **Bilardo ve snooker antrenmanı:** Cueist 4,9 puanla güçlü.
- **Hakem eğitimi:** RefereeWise var ve talep sinyali zayıf.
- **Ehliyet tehlike algısı testi:** Video üretmek gerekiyor, resmî uygulama var.
- **CPR eğitimi:** Laerdal'ın donanıma bağlı uygulaması var; telefonla bağımsız sürüm için talep belirsiz.
- **Hemşirelik ilaç hesapları:** Talep küçük ve dağınık.

---

## Kaynaklar
- Play mağaza sayfaları (GB, 2026-10-31): `https://play.google.com/store/apps/details?id=<paket>`
  - ARSim `llc.planeenglish.planeenglish`
  - Comms `com.comms.comms`
  - G-UDRT `com.Gudrt.GUDRT`
  - VHF Trainer Lite `com.adveniosoftware.vhftrainerlite`
  - VHF Simulator `com.vhf_simulatorq`
  - Interpretrain `com.interpretain`
  - Interpreter Practice Generator `com.interpretrain.ipg`
  - Kilter Board `com.kiltergrips.kilter_board_app`
  - Vertical-Life `info.verticallife`
  - Stōkt `com.getstokt.stokt`
  - Crimpd `com.crimpd.ui`
  - Carbs & Cals `com.chello.carbsandcals`
  - Carbetic `app.carbetic.android`
- FAA öğrenci pilot sayısı (2025): https://afm.aero/faa-2025-data-shows-us-student-pilot-population-hits-370286-as-women-pilots-surpass-100000-for-first-time
- FAA pilot nüfusu: https://avweb.com/aviation-news/faa-pilot-population-climbs-again-in-2025/
