-- ============================================================
-- Update all sentences to be longer and more meaningful
-- Short 4-6 word sentences → full 12-20 word sentences
-- All 6 languages: EN, DE, ES, IT, RU, FR
-- ============================================================

-- ============================================================
-- ENGLISH (course: a1b2c3d4) — difficulty 1
-- ============================================================
UPDATE sentences SET
  target_text = 'I always drink at least one cup of hot coffee every morning before I leave for work.',
  native_text = 'Her sabah işe gitmeden önce en az bir fincan sıcak kahve içiyorum.'
WHERE id = '59507b1e-afbb-4bee-a5ac-4b4f83bde30f';

UPDATE sentences SET
  target_text = 'She likes to read an interesting book for at least half an hour every night before she falls asleep.',
  native_text = 'Her gece uyumadan önce en az yarım saat boyunca ilginç bir kitap okumayı seviyor.'
WHERE id = '2d65fa33-56e8-47f8-acf4-b74a52694344';

UPDATE sentences SET
  target_text = 'We have been living in this big and lively city together with our family for more than five years.',
  native_text = 'Ailemizle birlikte bu büyük ve canlı şehirde beş yılı aşkın süredir yaşıyoruz.'
WHERE id = 'c3ed4c82-43a7-420c-a65b-c8f952ce8dba';

UPDATE sentences SET
  target_text = 'He takes the school bus every morning and usually arrives at school well before eight o clock.',
  native_text = 'Her sabah okul servisine biniyor ve genellikle saat sekizden çok önce okula varıyor.'
WHERE id = '5d11f679-a9b6-4576-b47b-fd1b1f514b3e';

UPDATE sentences SET
  target_text = 'The weather outside is extremely cold today, so you should definitely wear a warm and heavy coat.',
  native_text = 'Bugün dışarısı son derece soğuk, bu yüzden kesinlikle sıcak ve kalın bir palto giymelisin.'
WHERE id = '8b2f1805-d3e4-4f87-88f8-97f704ae05a6';

UPDATE sentences SET
  target_text = 'I love eating fresh fruits and vegetables every single day because they keep me strong and healthy.',
  native_text = 'Güçlü ve sağlıklı kalmak için her gün taze meyve ve sebze yemeyi çok seviyorum.'
WHERE id = 'ba8bdb8e-b548-40e3-9b48-a224e3cd64ee';

UPDATE sentences SET
  target_text = 'Every weekend they get together with their closest friends and play football in the park for two hours.',
  native_text = 'Her hafta sonu en yakın arkadaşlarıyla buluşarak parkta iki saat boyunca futbol oynuyorlar.'
WHERE id = '8faf8356-b589-4646-b66b-167cb09da1ac';

UPDATE sentences SET
  target_text = 'My mother loves cooking and always prepares a delicious and healthy dinner for the whole family every evening.',
  native_text = 'Annem yemek yapmayı seviyor ve her akşam tüm aile için lezzetli ve sağlıklı bir akşam yemeği hazırlıyor.'
WHERE id = '7852f75f-318b-4b55-a8b0-64533c056cfb';

-- ============================================================
-- ENGLISH (course: a1b2c3d4) — difficulty 2
-- ============================================================
UPDATE sentences SET
  target_text = 'I need to buy a return train ticket for my important business trip to the capital city next weekend.',
  native_text = 'Gelecek hafta sonu başkente yapacağım önemli iş seyahati için gidiş-dönüş tren bileti almam gerekiyor.'
WHERE id = 'db8de49f-1c56-405f-893c-3036d8f77da5';

UPDATE sentences SET
  target_text = 'She suddenly realized she had forgotten her passport at home just a few minutes before boarding the plane.',
  native_text = 'Uçağa binmeden yalnızca birkaç dakika önce pasaportunu evde unuttuğunu aniden fark etti.'
WHERE id = '92db1100-8491-4a94-b155-d165e86a6163';

UPDATE sentences SET
  target_text = 'We are looking for a comfortable and affordable hotel that is located very close to the international airport.',
  native_text = 'Uluslararası havalimanına çok yakın konumda, rahat ve uygun fiyatlı bir otel arıyoruz.'
WHERE id = 'ee646669-8db7-42d0-920e-5e94d708c2f1';

UPDATE sentences SET
  target_text = 'He usually prefers to work from home on Fridays in order to avoid the heavy traffic and long commute.',
  native_text = 'Yoğun trafikten ve uzun yolculuktan kaçınmak için Cuma günleri genellikle evden çalışmayı tercih ediyor.'
WHERE id = 'f91f6d31-d1ff-4a0b-abb5-e7a215eb1f14';

UPDATE sentences SET
  target_text = 'The very important team meeting starts at exactly nine o clock in the morning, so please do not be late.',
  native_text = 'Son derece önemli takım toplantısı sabah tam saat dokuzda başlıyor, bu yüzden lütfen geç kalmayın.'
WHERE id = '49442a40-cc10-4d42-a4db-93bbf431f6f9';

UPDATE sentences SET
  target_text = 'She speaks three different languages completely fluently and is now enrolled in a course to learn a fourth one.',
  native_text = 'Üç farklı dili tamamen akıcı bir şekilde konuşuyor ve şu anda dördüncü bir dil öğrenmek için kursa gidiyor.'
WHERE id = '54c73295-6991-4000-8eea-374e796f5b6d';

UPDATE sentences SET
  target_text = 'I have been attending English classes at a language school for over two years and my level is improving rapidly.',
  native_text = 'İki yılı aşkın süredir bir dil okulunda İngilizce derslerine katılıyorum ve seviyem hızla yükseliyor.'
WHERE id = 'd64292f4-d6d7-4f07-bb95-b733f7c707a2';

-- ============================================================
-- ENGLISH (course: a1b2c3d4) — difficulty 3
-- ============================================================
UPDATE sentences SET
  target_text = 'Despite the heavy rain and strong winds, we still decided to go hiking in the mountains because we had been planning this trip for several weeks.',
  native_text = 'Şiddetli yağmur ve güçlü rüzgara rağmen, bu geziye haftalardır hazırlandığımız için dağda yürüyüşe gitmeye karar verdik.'
WHERE id = '64e67e3c-bbc1-4ea0-8308-3ec8a940a5ac';

UPDATE sentences SET
  target_text = 'The government announced a series of new and controversial economic policies yesterday that are expected to significantly affect the daily lives of millions of citizens across the country.',
  native_text = 'Hükümet dün, ülke genelinde milyonlarca vatandaşın günlük yaşamını önemli ölçüde etkilemesi beklenen bir dizi tartışmalı yeni ekonomik politika açıkladı.'
WHERE id = '7223d3e8-a0da-4e55-a5ef-bf781f95a909';

UPDATE sentences SET
  target_text = 'After three years of dedicated research and countless hours of hard work, she has finally and successfully completed her master thesis on environmental science.',
  native_text = 'Üç yıllık özverili araştırma ve sayısız saatlik çalışmanın ardından, çevre bilimi üzerine yüksek lisans tezini nihayet başarıyla tamamladı.'
WHERE id = '60ae7258-f3ca-4ad1-9bd3-411ca684bb75';

UPDATE sentences SET
  target_text = 'It is absolutely essential for both governments and ordinary citizens around the world to take immediate and decisive action to protect the natural environment for future generations.',
  native_text = 'Hem hükümetlerin hem de dünya genelindeki sıradan vatandaşların gelecek nesiller için doğal çevreyi korumak amacıyla hemen ve kararlı bir şekilde harekete geçmesi son derece önemlidir.'
WHERE id = '838ea6f0-2720-4f14-9d9b-7ab00641021f';

UPDATE sentences SET
  target_text = 'After years of consistently hard work and outstanding performance, he was finally promoted to a senior management position at the company last month.',
  native_text = 'Yıllarca süregelen çalışkanlığı ve üstün performansının ardından, geçen ay nihayet şirkette üst düzey bir yönetim pozisyonuna terfi etti.'
WHERE id = 'e6cdf933-011d-4686-a210-24055c145357';


-- ============================================================
-- GERMAN (course: de000001) — difficulty 1
-- ============================================================
UPDATE sentences SET
  target_text = 'Ich trinke jeden Morgen mindestens eine Tasse heißen Kaffee, bevor ich zur Arbeit gehe.',
  native_text = 'Her sabah işe gitmeden önce en az bir fincan sıcak kahve içiyorum.'
WHERE id = '2f42e864-4d5b-4dea-b49c-ebf61ec96939';

UPDATE sentences SET
  target_text = 'Sie liest jeden Abend vor dem Schlafen mindestens eine halbe Stunde lang ein interessantes Buch.',
  native_text = 'Her gece uyumadan önce en az yarım saat boyunca ilginç bir kitap okuyor.'
WHERE id = '64fb8740-9e67-45b3-b21e-9612928379cc';

UPDATE sentences SET
  target_text = 'Wir wohnen schon seit mehr als fünf Jahren mit unserer Familie in dieser großen und lebhaften Stadt.',
  native_text = 'Ailemizle birlikte bu büyük ve canlı şehirde beş yılı aşkın süredir yaşıyoruz.'
WHERE id = 'b452bf73-4cec-446a-8044-ad542ff0530b';

UPDATE sentences SET
  target_text = 'Er fährt jeden Morgen mit dem Schulbus und kommt in der Regel gut vor acht Uhr in der Schule an.',
  native_text = 'Her sabah okul servisiyle gidiyor ve genellikle saat sekizden önce okula varıyor.'
WHERE id = '7d44aaea-1d8e-404a-9569-a5bde44ffc57';

UPDATE sentences SET
  target_text = 'Das Wetter draußen ist heute extrem kalt, deshalb solltest du unbedingt einen warmen und dicken Mantel anziehen.',
  native_text = 'Bugün dışarısı son derece soğuk, bu yüzden kesinlikle sıcak ve kalın bir palto giymelisin.'
WHERE id = '40772bb7-c436-4600-aa51-0d626a40e3fb';

UPDATE sentences SET
  target_text = 'Die Kinder spielen nach der Schule fast jeden Tag fröhlich und ausgelassen zusammen im Park.',
  native_text = 'Çocuklar okuldan sonra neredeyse her gün parkta neşeyle ve coşkuyla birlikte oynuyor.'
WHERE id = 'e74685f6-5f99-48cc-8ca1-ffe3f4462eb3';

UPDATE sentences SET
  target_text = 'Meine Mutter liebt es zu kochen und bereitet jeden Abend ein köstliches und gesundes Abendessen für die ganze Familie vor.',
  native_text = 'Annem yemek yapmayı seviyor ve her akşam tüm aile için lezzetli ve sağlıklı bir akşam yemeği hazırlıyor.'
WHERE id = '771a76b9-5bb0-4c0c-97c6-6086d32409ac';

-- ============================================================
-- GERMAN (course: de000001) — difficulty 2
-- ============================================================
UPDATE sentences SET
  target_text = 'Ich muss für meine wichtige Geschäftsreise in die Hauptstadt nächstes Wochenende eine Hin- und Rückfahrkarte kaufen.',
  native_text = 'Gelecek hafta sonu başkente yapacağım önemli iş seyahati için gidiş-dönüş bilet almam gerekiyor.'
WHERE id = 'cacafb9b-1fc9-4003-9f86-9192d4b57959';

UPDATE sentences SET
  target_text = 'Sie bemerkte erst wenige Minuten vor dem Einsteigen ins Flugzeug, dass sie ihren Pass zu Hause vergessen hatte.',
  native_text = 'Uçağa binmeden yalnızca birkaç dakika önce pasaportunu evde unuttuğunu fark etti.'
WHERE id = '4ebd96d6-0063-4070-a723-b9fb9115839c';

UPDATE sentences SET
  target_text = 'Wir suchen ein komfortables und günstiges Hotel, das sich in unmittelbarer Nähe des internationalen Flughafens befindet.',
  native_text = 'Uluslararası havalimanına çok yakın konumda, rahat ve uygun fiyatlı bir otel arıyoruz.'
WHERE id = '633f247b-0785-4619-b34f-bdb1e528d5cf';

UPDATE sentences SET
  target_text = 'Das wichtige Teammeeting beginnt um Punkt neun Uhr morgens, daher bitten wir alle Teilnehmer, pünktlich zu erscheinen.',
  native_text = 'Önemli takım toplantısı sabah tam saat dokuzda başlıyor, bu yüzden tüm katılımcıları zamanında gelmelerini rica ediyoruz.'
WHERE id = '28755b21-7a89-4705-b93f-87d4dcc5f7ee';

UPDATE sentences SET
  target_text = 'Er bevorzugt es meistens, freitags von zu Hause aus zu arbeiten, um den starken Verkehr und den langen Weg ins Büro zu vermeiden.',
  native_text = 'Yoğun trafikten ve ofise uzun yolculuktan kaçınmak için genellikle Cuma günleri evden çalışmayı tercih ediyor.'
WHERE id = 'b6138183-1bb7-4286-acbf-3890cf322a77';

UPDATE sentences SET
  target_text = 'Ich lerne jetzt seit genau einem Jahr intensiv Deutsch und mache seitdem sehr große und schnelle Fortschritte.',
  native_text = 'Bir yıldır yoğun bir şekilde Almanca öğreniyorum ve o zamandan beri çok büyük ve hızlı ilerleme kaydediyorum.'
WHERE id = '7cef487f-68ad-4dc4-ae92-4416ce955d15';

-- ============================================================
-- GERMAN (course: de000001) — difficulty 3
-- ============================================================
UPDATE sentences SET
  target_text = 'Trotz des starken Regens und der heftigen Winde haben wir uns dennoch entschlossen, in den Bergen wandern zu gehen, da wir diese Reise seit mehreren Wochen geplant hatten.',
  native_text = 'Şiddetli yağmur ve güçlü rüzgara rağmen, bu geziye haftalardır hazırlandığımız için dağda yürüyüşe gitmeye karar verdik.'
WHERE id = 'e96cf08b-5358-417a-8ee7-b63bf40f91c2';

UPDATE sentences SET
  target_text = 'Die Regierung hat gestern eine Reihe neuer und umstrittener Wirtschaftsmaßnahmen angekündigt, die das tägliche Leben von Millionen von Bürgern im ganzen Land erheblich beeinflussen sollen.',
  native_text = 'Hükümet dün, ülke genelinde milyonlarca vatandaşın günlük yaşamını önemli ölçüde etkilemesi beklenen bir dizi tartışmalı yeni ekonomik tedbir açıkladı.'
WHERE id = '4c3a9ad4-6210-4d87-9541-c981ca313de3';

UPDATE sentences SET
  target_text = 'Es ist für Regierungen und gewöhnliche Bürger auf der ganzen Welt absolut notwendig, sofortige und entschlossene Maßnahmen zum Schutz der natürlichen Umwelt für künftige Generationen zu ergreifen.',
  native_text = 'Hem hükümetlerin hem de dünya genelindeki sıradan vatandaşların gelecek nesiller için doğal çevreyi korumak amacıyla hemen ve kararlı bir şekilde harekete geçmesi son derece önemlidir.'
WHERE id = '95cfbdb4-6186-46e4-8073-2964b2b9580a';


-- ============================================================
-- SPANISH (course: e5000001) — difficulty 1
-- ============================================================
UPDATE sentences SET
  target_text = 'Yo siempre bebo al menos una taza de café caliente cada mañana antes de salir a trabajar.',
  native_text = 'Her sabah işe çıkmadan önce en az bir fincan sıcak kahve içiyorum.'
WHERE id = '7a706e7d-b240-4bc1-b155-f9358241b8a5';

UPDATE sentences SET
  target_text = 'Ella suele leer un libro interesante durante al menos media hora todas las noches antes de dormir.',
  native_text = 'Her gece uyumadan önce en az yarım saat boyunca ilginç bir kitap okumayı seviyor.'
WHERE id = 'aacc8c29-ad85-4adb-9434-4707fee30e2e';

UPDATE sentences SET
  target_text = 'Nosotros llevamos más de cinco años viviendo juntos con nuestra familia en esta gran y animada ciudad.',
  native_text = 'Ailemizle birlikte bu büyük ve canlı şehirde beş yılı aşkın süredir yaşıyoruz.'
WHERE id = 'fa161edb-9444-418a-b744-165d99cc625f';

UPDATE sentences SET
  target_text = 'Él toma el autobús escolar cada mañana y normalmente llega al colegio bastante antes de las ocho.',
  native_text = 'Her sabah okul servisine biniyor ve genellikle saat sekizden önce okula varıyor.'
WHERE id = 'b6b26c23-6801-4da6-ad0c-18dabf46bf96';

UPDATE sentences SET
  target_text = 'Hoy hace un frío extremo afuera, así que deberías ponerte sin falta un abrigo grueso y abrigador.',
  native_text = 'Bugün dışarısı son derece soğuk, bu yüzden kesinlikle sıcak ve kalın bir palto giymelisin.'
WHERE id = '3b9dee1b-f3a4-4b06-9927-62a5d55aa5dc';

UPDATE sentences SET
  target_text = 'Los niños juegan contentos y llenos de energía juntos en el parque casi todos los días después del colegio.',
  native_text = 'Çocuklar okuldan sonra neredeyse her gün parkta neşeyle ve enerjik bir şekilde birlikte oynuyor.'
WHERE id = '9b261cda-9ce6-4f27-96ec-3e0a92686368';

UPDATE sentences SET
  target_text = 'Mi madre adora cocinar y siempre prepara una cena deliciosa y nutritiva para toda la familia cada noche.',
  native_text = 'Annem yemek yapmayı seviyor ve her akşam tüm aile için lezzetli ve besleyici bir akşam yemeği hazırlıyor.'
WHERE id = '9cf47933-30bb-4d53-a78b-2f654b37038a';

-- ============================================================
-- SPANISH (course: e5000001) — difficulty 2
-- ============================================================
UPDATE sentences SET
  target_text = 'Necesito comprar un billete de tren de ida y vuelta para mi importante viaje de negocios a la capital el próximo fin de semana.',
  native_text = 'Gelecek hafta sonu başkente yapacağım önemli iş seyahati için gidiş-dönüş tren bileti almam gerekiyor.'
WHERE id = '675a59d4-78a7-4315-bd36-d78b9eb8ce0b';

UPDATE sentences SET
  target_text = 'Ella se dio cuenta de que había olvidado su pasaporte en casa tan solo unos minutos antes de subir al avión.',
  native_text = 'Uçağa binmeden yalnızca birkaç dakika önce pasaportunu evde unuttuğunu fark etti.'
WHERE id = '7e030101-71b7-4caa-aea5-cfbee3e9f115';

UPDATE sentences SET
  target_text = 'Estamos buscando un hotel cómodo y asequible que esté ubicado muy cerca del aeropuerto internacional de la ciudad.',
  native_text = 'Uluslararası havalimanına çok yakın konumda, rahat ve uygun fiyatlı bir otel arıyoruz.'
WHERE id = '2e1a62e2-5fe4-46d5-a841-b41e60b70898';

UPDATE sentences SET
  target_text = 'La importantísima reunión del equipo empieza exactamente a las nueve de la mañana, así que por favor no lleguen tarde.',
  native_text = 'Çok önemli takım toplantısı tam sabah saat dokuzda başlıyor, bu yüzden lütfen geç kalmayın.'
WHERE id = '4cc2899c-d0c6-4e39-8e30-fed79c1d5584';

UPDATE sentences SET
  target_text = 'Él generalmente prefiere trabajar desde casa los viernes para evitar el tráfico intenso y el largo trayecto a la oficina.',
  native_text = 'Yoğun trafikten ve ofise uzun yolculuktan kaçınmak için genellikle Cuma günleri evden çalışmayı tercih ediyor.'
WHERE id = '1841e48f-af01-46f2-b5a2-58fec6ab707f';

UPDATE sentences SET
  target_text = 'Llevo exactamente un año estudiando español de forma intensiva y desde entonces he progresado muchísimo y muy rápido.',
  native_text = 'Bir yıldır yoğun bir şekilde İspanyolca öğreniyorum ve o zamandan beri çok büyük ve hızlı ilerleme kaydettim.'
WHERE id = '6d64c104-f347-4697-88c0-254b4e50668c';

-- ============================================================
-- SPANISH (course: e5000001) — difficulty 3
-- ============================================================
UPDATE sentences SET
  target_text = 'A pesar de la lluvia intensa y los fuertes vientos, decidimos igualmente ir de excursión a las montañas porque llevábamos semanas planeando este viaje.',
  native_text = 'Şiddetli yağmur ve güçlü rüzgara rağmen, bu geziye haftalardır hazırlandığımız için dağa gezi yapmaya gitmeye karar verdik.'
WHERE id = '075f3e57-76fa-49a7-a4f7-7982b8e0853b';

UPDATE sentences SET
  target_text = 'El gobierno anunció ayer una serie de nuevas y polémicas medidas económicas que se espera que afecten significativamente la vida cotidiana de millones de ciudadanos en todo el país.',
  native_text = 'Hükümet dün, ülke genelinde milyonlarca vatandaşın günlük yaşamını önemli ölçüde etkilemesi beklenen bir dizi tartışmalı yeni ekonomik tedbir açıkladı.'
WHERE id = '2b0b728a-6cfe-4b51-8f93-a336b62cdd80';

UPDATE sentences SET
  target_text = 'Es absolutamente fundamental que tanto los gobiernos como los ciudadanos de todo el mundo tomen medidas inmediatas y decisivas para proteger el medio ambiente natural para las generaciones futuras.',
  native_text = 'Hem hükümetlerin hem de dünya genelindeki vatandaşların gelecek nesiller için doğal çevreyi korumak amacıyla hemen ve kararlı bir şekilde harekete geçmesi son derece önemlidir.'
WHERE id = '9fc5e7a5-53c6-4efb-b079-6dc075db28ba';


-- ============================================================
-- ITALIAN (course: 17000001) — difficulty 1
-- ============================================================
UPDATE sentences SET
  target_text = 'Ogni mattina bevo almeno una tazza di caffè caldo prima di uscire di casa per andare al lavoro.',
  native_text = 'Her sabah işe gitmeden önce en az bir fincan sıcak kahve içiyorum.'
WHERE id = 'a733eda2-fc37-4dc1-abde-ded612946b85';

UPDATE sentences SET
  target_text = 'Lei ama leggere un libro interessante per almeno mezz ora ogni sera prima di addormentarsi.',
  native_text = 'Her gece uyumadan önce en az yarım saat boyunca ilginç bir kitap okumayı seviyor.'
WHERE id = '794c0eff-da87-464a-90db-53055df5941f';

UPDATE sentences SET
  target_text = 'Viviamo insieme alla nostra famiglia in questa grande e vivace città da più di cinque anni.',
  native_text = 'Ailemizle birlikte bu büyük ve canlı şehirde beş yılı aşkın süredir yaşıyoruz.'
WHERE id = 'e00d91f1-4a43-403c-8f05-8e79a4ec931e';

UPDATE sentences SET
  target_text = 'Lui prende l autobus scolastico ogni mattina e di solito arriva a scuola ben prima delle otto.',
  native_text = 'Her sabah okul servisine biniyor ve genellikle saat sekizden önce okula varıyor.'
WHERE id = '7c4caec2-023d-4bac-a5a9-122a6437f709';

UPDATE sentences SET
  target_text = 'Oggi fuori fa un freddo estremo, quindi dovresti assolutamente indossare un cappotto pesante e caldo.',
  native_text = 'Bugün dışarısı son derece soğuk, bu yüzden kesinlikle kalın ve sıcak bir palto giymelisin.'
WHERE id = 'fce4786d-0d29-4740-b68a-60b9110d1125';

-- ============================================================
-- ITALIAN (course: 17000001) — difficulty 2
-- ============================================================
UPDATE sentences SET
  target_text = 'Devo comprare un biglietto di andata e ritorno per il mio importante viaggio di lavoro nella capitale il prossimo fine settimana.',
  native_text = 'Gelecek hafta sonu başkente yapacağım önemli iş seyahati için gidiş-dönüş bilet almam gerekiyor.'
WHERE id = '6e538671-3568-4591-aaea-464bc5335578';

UPDATE sentences SET
  target_text = 'Si è resa conto di aver dimenticato il passaporto a casa solo pochi minuti prima di salire sull aereo.',
  native_text = 'Uçağa binmeden yalnızca birkaç dakika önce pasaportunu evde unuttuğunu fark etti.'
WHERE id = 'fb1e8df7-8d7e-45a1-a7cf-f93adb09c720';

UPDATE sentences SET
  target_text = 'Stiamo cercando un hotel confortevole e conveniente che si trovi molto vicino all aeroporto internazionale della città.',
  native_text = 'Şehrin uluslararası havalimanına çok yakın konumda, rahat ve uygun fiyatlı bir otel arıyoruz.'
WHERE id = '4cd1085b-8995-4d5d-ab5b-cd83577541ca';


-- ============================================================
-- RUSSIAN (course: 04000001) — difficulty 1
-- ============================================================
UPDATE sentences SET
  target_text = 'Я всегда выпиваю как минимум одну чашку горячего кофе каждое утро, прежде чем уйти на работу.',
  native_text = 'Her sabah işe gitmeden önce en az bir fincan sıcak kahve içiyorum.'
WHERE id = 'add30b32-3892-44ff-bab3-7dfda46bafeb';

UPDATE sentences SET
  target_text = 'Она любит читать интересную книгу не менее получаса каждый вечер перед тем, как лечь спать.',
  native_text = 'Her gece uyumadan önce en az yarım saat boyunca ilginç bir kitap okumayı seviyor.'
WHERE id = '1a9910c0-1d39-4fa5-81c1-9dc2830e7f83';

UPDATE sentences SET
  target_text = 'Мы живём вместе с семьёй в этом большом и оживлённом городе уже более пяти лет.',
  native_text = 'Ailemizle birlikte bu büyük ve canlı şehirde beş yılı aşkın süredir yaşıyoruz.'
WHERE id = 'a5f8fa21-9955-4995-83f0-0b181a53f80c';

UPDATE sentences SET
  target_text = 'Он каждое утро садится на школьный автобус и обычно приезжает в школу задолго до восьми часов.',
  native_text = 'Her sabah okul servisine biniyor ve genellikle saat sekizden çok önce okula varıyor.'
WHERE id = '5bb1d1ae-19ec-4253-82fb-6b7d8c9cb3af';

UPDATE sentences SET
  target_text = 'Сегодня на улице стоит очень сильный мороз, поэтому тебе обязательно нужно надеть тёплое и тяжёлое пальто.',
  native_text = 'Bugün dışarısı son derece soğuk, bu yüzden kesinlikle sıcak ve kalın bir palto giymelisin.'
WHERE id = '46f29b59-3bea-4eb7-a1d9-e8c9fa09eb33';

-- ============================================================
-- RUSSIAN (course: 04000001) — difficulty 2
-- ============================================================
UPDATE sentences SET
  target_text = 'Мне нужно купить билет туда и обратно для моей важной деловой поездки в столицу на следующих выходных.',
  native_text = 'Gelecek hafta sonu başkente yapacağım önemli iş seyahati için gidiş-dönüş bilet almam gerekiyor.'
WHERE id = 'd1526d29-dd1b-473a-a81e-a3cc3865e056';

UPDATE sentences SET
  target_text = 'Важное командное совещание начинается ровно в девять часов утра, поэтому, пожалуйста, не опаздывайте.',
  native_text = 'Önemli takım toplantısı sabah tam saat dokuzda başlıyor, bu yüzden lütfen geç kalmayın.'
WHERE id = 'a1622c83-da01-4c4c-b3d4-eaca36b02a68';

UPDATE sentences SET
  target_text = 'Я учу русский язык уже ровно год в интенсивном режиме и с тех пор делаю очень большие и быстрые успехи.',
  native_text = 'Bir yıldır yoğun bir şekilde Rusça öğreniyorum ve o zamandan beri çok büyük ve hızlı ilerleme kaydediyorum.'
WHERE id = 'a30d24ff-d6e9-4109-9f41-576dc00150d5';


-- ============================================================
-- FRENCH (course: f0000001) — difficulty 1
-- ============================================================
UPDATE sentences SET
  target_text = 'Je mange une pomme fraîche et bois une tasse de café chaud chaque matin avant de partir travailler.',
  native_text = 'Her sabah işe gitmeden önce taze bir elma yiyor ve bir fincan sıcak kahve içiyorum.'
WHERE id = '36fbd544-cb49-4f21-98a1-970a6dd6bbe9';

UPDATE sentences SET
  target_text = 'Elle adore écouter de la musique et lit un livre intéressant pendant au moins une demi-heure avant de dormir.',
  native_text = 'Müzik dinlemeyi seviyor ve her gece uyumadan önce en az yarım saat boyunca ilginç bir kitap okuyor.'
WHERE id = 'dfb0b1dc-0cc5-4d5a-95ec-c1b72de23d41';

UPDATE sentences SET
  target_text = 'Nous habitons dans cette grande et belle maison avec toute notre famille depuis maintenant plus de cinq ans.',
  native_text = 'Ailemizin tamamıyla birlikte bu büyük ve güzel evde beş yılı aşkın süredir yaşıyoruz.'
WHERE id = '6f4144df-df20-4dd8-b184-929e2755d61b';

UPDATE sentences SET
  target_text = 'Il parle le français très couramment et apprend actuellement une nouvelle langue étrangère dans une école de langues.',
  native_text = 'Fransızcayı çok akıcı bir şekilde konuşuyor ve şu anda bir dil okulunda yeni bir yabancı dil öğreniyor.'
WHERE id = '7e38879f-63e8-4be7-aa00-7b990f440aee';

UPDATE sentences SET
  target_text = 'Excusez-moi, je voudrais commander un grand café et un croissant frais, s il vous plaît.',
  native_text = 'Affedersiniz, lütfen büyük bir kahve ve taze bir kruvasan söylemek istiyorum.'
WHERE id = 'd76d8dbf-1d0b-4a52-ba7a-81a3204d250e';

UPDATE sentences SET
  target_text = 'Les enfants jouent joyeusement ensemble dans le parc presque tous les jours après leur journée d école.',
  native_text = 'Çocuklar okuldan sonra neredeyse her gün parkta neşeyle birlikte oynuyor.'
WHERE id = '8518775e-168f-4c86-a945-f1f427b35377';

UPDATE sentences SET
  target_text = 'Ma mère adore cuisiner et prépare toujours un dîner délicieux et équilibré pour toute la famille ce soir.',
  native_text = 'Annem yemek yapmayı seviyor ve bu akşam tüm aile için lezzetli ve dengeli bir akşam yemeği hazırlıyor.'
WHERE id = '18603880-acbd-46f3-8a44-23928f91185e';

-- ============================================================
-- FRENCH (course: f0000001) — difficulty 2
-- ============================================================
UPDATE sentences SET
  target_text = 'Je dois acheter un billet de train aller-retour pour mon important voyage d affaires dans la capitale le week-end prochain.',
  native_text = 'Gelecek hafta sonu başkente yapacağım önemli iş seyahati için gidiş-dönüş tren bileti almam gerekiyor.'
WHERE id = 'eb683a77-8238-4725-a939-cab748682fc4';

UPDATE sentences SET
  target_text = 'Elle s est rendu compte qu elle avait oublié son passeport à la maison juste quelques minutes avant d embarquer.',
  native_text = 'Uçağa binmeden yalnızca birkaç dakika önce pasaportunu evde unuttuğunu fark etti.'
WHERE id = '835faaa1-599e-4210-b5a4-7844d2dd82e7';

UPDATE sentences SET
  target_text = 'Nous cherchons un hôtel confortable et abordable situé très près de la gare centrale et du centre-ville.',
  native_text = 'Merkezi garın ve şehir merkezinin çok yakınında konumlanan, rahat ve uygun fiyatlı bir otel arıyoruz.'
WHERE id = '7c14950d-4f7a-46f6-a464-b1dd4213c697';

UPDATE sentences SET
  target_text = 'La très importante réunion d équipe commence exactement à neuf heures du matin, veuillez donc ne pas être en retard.',
  native_text = 'Çok önemli takım toplantısı sabah tam saat dokuzda başlıyor, bu yüzden lütfen geç kalmayın.'
WHERE id = 'a3a6c8fa-9bb4-4ea0-9a1c-d9a17c810db5';

UPDATE sentences SET
  target_text = 'Il préfère généralement travailler depuis chez lui le vendredi afin d éviter les embouteillages et le long trajet au bureau.',
  native_text = 'Trafik sıkışıklığından ve ofise uzun yolculuktan kaçınmak için genellikle Cuma günleri evden çalışmayı tercih ediyor.'
WHERE id = '8ef7011e-b518-44fd-b3a7-b8635e58fcc9';

UPDATE sentences SET
  target_text = 'J apprends le français de manière intensive depuis exactement un an et j ai fait d énormes progrès depuis lors.',
  native_text = 'Bir yıldır yoğun bir şekilde Fransızca öğreniyorum ve o zamandan beri çok büyük ilerleme kaydettim.'
WHERE id = 'afbad2a9-faf2-4472-845d-07e0a22f95a9';

-- ============================================================
-- FRENCH (course: f0000001) — difficulty 3
-- ============================================================
UPDATE sentences SET
  target_text = 'Malgré la pluie battante et les vents violents, nous avons quand même décidé de partir en randonnée car nous planifiions ce voyage depuis plusieurs semaines.',
  native_text = 'Şiddetli yağmur ve güçlü rüzgara rağmen, bu geziye haftalardır hazırlandığımız için yürüyüşe çıkmaya karar verdik.'
WHERE id = '55a19e6c-3ca9-42c6-a554-f6b24ac0ab6f';

UPDATE sentences SET
  target_text = 'Le gouvernement a annoncé hier une série de nouvelles mesures économiques controversées qui devraient affecter considérablement la vie quotidienne de millions de citoyens dans tout le pays.',
  native_text = 'Hükümet dün, ülke genelinde milyonlarca vatandaşın günlük yaşamını önemli ölçüde etkilemesi beklenen bir dizi tartışmalı yeni ekonomik tedbir açıkladı.'
WHERE id = '699a3080-3983-4e7e-8302-56bea4a05270';

UPDATE sentences SET
  target_text = 'Il est absolument essentiel que les gouvernements et les citoyens ordinaires du monde entier prennent des mesures immédiates et décisives pour protéger l environnement naturel pour les générations futures.',
  native_text = 'Hem hükümetlerin hem de dünya genelindeki sıradan vatandaşların gelecek nesiller için doğal çevreyi korumak amacıyla hemen ve kararlı bir şekilde harekete geçmesi son derece önemlidir.'
WHERE id = '59b16195-02ab-46d4-baba-9d37728e1e31';
