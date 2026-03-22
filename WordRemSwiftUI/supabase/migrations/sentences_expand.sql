-- ============================================================
-- sentences_expand.sql
-- Adds ~40 new sentences per language across 6 courses.
-- Topics: family, food, health, hobbies, travel, work,
--         shopping, home, school, technology, social.
-- Difficulty:
--   1 = A1/A2  (beginner / elementary)
--   2 = B1     (intermediate)
--   3 = B2/C1  (upper-intermediate / advanced)
-- order_index starts at 500 to avoid conflicts with existing seed.
-- ============================================================

-- ═══════════════════════════════════════════════════
-- TR → EN  (Turkish speakers learning English)
-- ═══════════════════════════════════════════════════
DO $$
DECLARE v_cid UUID;
BEGIN
  SELECT id INTO v_cid FROM courses
  WHERE native_lang_id=(SELECT id FROM languages WHERE code='TR' LIMIT 1)
    AND target_lang_id=(SELECT id FROM languages WHERE code='EN' LIMIT 1)
    AND is_active=TRUE LIMIT 1;
  IF v_cid IS NULL THEN RETURN; END IF;

  INSERT INTO sentences(course_id,target_text,native_text,key_word,key_word_native,difficulty,order_index) VALUES
  -- ── Difficulty 1 · A1/A2 ──────────────────────────────────────
  (v_cid,'My sister likes listening to music.','Kız kardeşim müzik dinlemeyi seviyor.','sister','kız kardeş',1,500),
  (v_cid,'The cat is sleeping on the sofa.','Kedi kanepede uyuyor.','sleeping','uyuyor',1,510),
  (v_cid,'I brush my teeth twice a day.','Günde iki kez dişlerimi fırçalarım.','brush','fırçalamak',1,520),
  (v_cid,'He is a doctor at the hospital.','O hastanede doktordur.','doctor','doktor',1,530),
  (v_cid,'I need a new pair of shoes.','Yeni bir çift ayakkabıya ihtiyacım var.','shoes','ayakkabı',1,540),
  (v_cid,'My favorite season is summer.','En sevdiğim mevsim yazdır.','summer','yaz',1,550),
  (v_cid,'He plays guitar in his free time.','Boş zamanlarında gitar çalar.','guitar','gitar',1,560),
  (v_cid,'I want to learn how to cook.','Yemek yapmayı öğrenmek istiyorum.','cook','yemek pişirmek',1,570),
  (v_cid,'The dog is running in the garden.','Köpek bahçede koşuyor.','garden','bahçe',1,580),
  (v_cid,'The children are very happy today.','Çocuklar bugün çok mutlu.','happy','mutlu',1,590),
  (v_cid,'My father is a teacher.','Babam öğretmendir.','teacher','öğretmen',1,600),
  (v_cid,'We watch movies on Sundays.','Pazar günleri film izliyoruz.','watch','izlemek',1,610),
  (v_cid,'I usually sleep for eight hours.','Genellikle sekiz saat uyurum.','sleep','uyumak',1,620),
  (v_cid,'She drinks orange juice in the morning.','Sabahları portakal suyu içiyor.','juice','meyve suyu',1,630),
  (v_cid,'The library closes at nine in the evening.','Kütüphane akşam dokuzda kapanır.','library','kütüphane',1,640),
  (v_cid,'My mother makes breakfast every morning.','Annem her sabah kahvaltı hazırlar.','breakfast','kahvaltı',1,650),
  (v_cid,'He rides his bicycle to school.','O okula bisikletiyle gider.','bicycle','bisiklet',1,660),
  (v_cid,'She always wears a red hat.','O her zaman kırmızı bir şapka takar.','hat','şapka',1,670),
  (v_cid,'The supermarket is near my house.','Süpermarket evimin yakınında.','near','yakın',1,680),
  -- ── Difficulty 2 · B1 ─────────────────────────────────────────
  (v_cid,'Could you show me the way to the train station?','Lütfen bana tren istasyonuna giden yolu gösterebilir misiniz?','station','istasyon',2,690),
  (v_cid,'I have a headache and need some medicine.','Başım ağrıyor ve biraz ilaca ihtiyacım var.','headache','baş ağrısı',2,700),
  (v_cid,'She reserved a table for two at the restaurant.','Restoranda iki kişilik masa rezervasyonu yaptı.','reserved','rezervasyon yaptı',2,710),
  (v_cid,'We are planning a trip to Europe next summer.','Gelecek yaz Avrupa ya bir gezi planlıyoruz.','planning','planlıyoruz',2,720),
  (v_cid,'The price of this jacket is too expensive for me.','Bu ceketin fiyatı benim için çok pahalı.','expensive','pahalı',2,730),
  (v_cid,'She has been living in London for five years.','Beş yıldır Londra da yaşıyor.','living','yaşıyor',2,740),
  (v_cid,'Can I try this shirt in a different size?','Bu gömleği farklı bir bedende deneyebilir miyim?','size','beden',2,750),
  (v_cid,'He always checks his email in the morning.','Her sabah e-postalarını kontrol eder.','email','e-posta',2,760),
  (v_cid,'I forgot my wallet at home this morning.','Bu sabah cüzdanımı evde unuttum.','wallet','cüzdan',2,770),
  (v_cid,'They invited us to their wedding next month.','Bizi gelecek ay düğünlerine davet ettiler.','wedding','düğün',2,780),
  (v_cid,'The bus was late because of the heavy traffic.','Otobüs yoğun trafik nedeniyle geç kaldı.','traffic','trafik',2,790),
  (v_cid,'She bought a new laptop for her studies.','Dersleri için yeni bir dizüstü bilgisayar satın aldı.','laptop','dizüstü bilgisayar',2,800),
  (v_cid,'We should arrive at the airport two hours early.','Havalimanına iki saat erken gelmeliyiz.','airport','havalimanı',2,810),
  (v_cid,'He is saving money to buy a new car.','Yeni bir araba almak için para biriktiriyor.','saving','biriktiriyor',2,820),
  (v_cid,'She called the doctor to make an appointment.','Randevu almak için doktoru aradı.','appointment','randevu',2,830),
  -- ── Difficulty 3 · B2/C1 ──────────────────────────────────────
  (v_cid,'The exhibition attracted thousands of visitors from around the world.','Sergi dünya genelinden binlerce ziyaretçi çekti.','exhibition','sergi',3,840),
  (v_cid,'We should consider all options before making a final decision.','Nihai bir karar vermeden önce tüm seçenekleri değerlendirmeliyiz.','consider','değerlendirmek',3,850),
  (v_cid,'It is important to maintain a healthy work-life balance.','Sağlıklı bir iş-yaşam dengesi sürdürmek önemlidir.','balance','denge',3,860),
  (v_cid,'The new regulations will come into effect at the beginning of next year.','Yeni düzenlemeler gelecek yılın başında yürürlüğe girecek.','regulations','düzenlemeler',3,870),
  (v_cid,'The company decided to expand its operations to new markets.','Şirket faaliyetlerini yeni pazarlara genişletmeye karar verdi.','expand','genişletmek',3,880),
  (v_cid,'She was awarded a scholarship to study at a prestigious university.','Prestijli bir üniversitede okumak için burs aldı.','scholarship','burs',3,890),
  (v_cid,'The negotiations between the two countries lasted for several months.','İki ülke arasındaki müzakereler birkaç ay sürdü.','negotiations','müzakereler',3,900),
  (v_cid,'Unless we take action immediately, the situation will get worse.','Hemen harekete geçmezsek durum daha da kötüleşecek.','immediately','hemen',3,910),
  (v_cid,'Despite economic difficulties, the startup managed to secure new funding.','Ekonomik zorluklara rağmen startup yeni finansman sağlamayı başardı.','Despite','rağmen',3,920),
  (v_cid,'Rising sea levels are threatening coastal communities worldwide.','Yükselen deniz seviyeleri dünya genelinde kıyı topluluklarını tehdit ediyor.','threatening','tehdit eden',3,930)
  ON CONFLICT DO NOTHING;
END $$;

-- ═══════════════════════════════════════════════════
-- TR → FR  (Turkish speakers learning French)
-- ═══════════════════════════════════════════════════
DO $$
DECLARE v_cid UUID;
BEGIN
  SELECT id INTO v_cid FROM courses
  WHERE native_lang_id=(SELECT id FROM languages WHERE code='TR' LIMIT 1)
    AND target_lang_id=(SELECT id FROM languages WHERE code='FR' LIMIT 1)
    AND is_active=TRUE LIMIT 1;
  IF v_cid IS NULL THEN RETURN; END IF;

  INSERT INTO sentences(course_id,target_text,native_text,key_word,key_word_native,difficulty,order_index) VALUES
  -- ── Difficulty 1 ──────────────────────────────────────────────
  (v_cid,'Ma sœur aime écouter de la musique.','Kız kardeşim müzik dinlemeyi seviyor.','sœur','kız kardeş',1,500),
  (v_cid,'Le chat dort sur le canapé.','Kedi kanepede uyuyor.','dort','uyuyor',1,510),
  (v_cid,'Je me brosse les dents deux fois par jour.','Günde iki kez dişlerimi fırçalarım.','dents','diş',1,520),
  (v_cid,'Il est médecin à l hôpital.','O hastanede doktordur.','médecin','doktor',1,530),
  (v_cid,'J ai besoin d une nouvelle paire de chaussures.','Yeni bir çift ayakkabıya ihtiyacım var.','chaussures','ayakkabı',1,540),
  (v_cid,'Ma saison préférée est l été.','En sevdiğim mevsim yazdır.','été','yaz',1,550),
  (v_cid,'Il joue de la guitare pendant son temps libre.','Boş zamanlarında gitar çalar.','guitare','gitar',1,560),
  (v_cid,'Je veux apprendre à cuisiner.','Yemek yapmayı öğrenmek istiyorum.','cuisiner','yemek pişirmek',1,570),
  (v_cid,'Le chien court dans le jardin.','Köpek bahçede koşuyor.','jardin','bahçe',1,580),
  (v_cid,'Les enfants sont très heureux aujourd hui.','Çocuklar bugün çok mutlu.','heureux','mutlu',1,590),
  (v_cid,'Mon père est professeur.','Babam öğretmendir.','professeur','öğretmen',1,600),
  (v_cid,'Nous regardons des films le dimanche.','Pazar günleri film izliyoruz.','regardons','izliyoruz',1,610),
  (v_cid,'Ma mère prépare le petit-déjeuner chaque matin.','Annem her sabah kahvaltı hazırlar.','petit-déjeuner','kahvaltı',1,620),
  (v_cid,'Il va à l école à vélo.','O okula bisikletiyle gider.','vélo','bisiklet',1,630),
  (v_cid,'Le supermarché est près de chez moi.','Süpermarket evimin yakınında.','près','yakın',1,640),
  -- ── Difficulty 2 ──────────────────────────────────────────────
  (v_cid,'Pourriez-vous m indiquer le chemin pour la gare?','Lütfen bana istasyona giden yolu gösterebilir misiniz?','gare','istasyon',2,650),
  (v_cid,'J ai mal à la tête et j ai besoin de médicaments.','Başım ağrıyor ve ilaca ihtiyacım var.','médicaments','ilaç',2,660),
  (v_cid,'Elle a réservé une table pour deux au restaurant.','Restoranda iki kişilik masa rezervasyonu yaptı.','réservé','rezervasyon yaptı',2,670),
  (v_cid,'Nous planifions un voyage en Espagne l été prochain.','Gelecek yaz İspanya ya bir gezi planlıyoruz.','voyage','gezi',2,680),
  (v_cid,'Le prix de ce manteau est trop cher pour moi.','Bu paltonun fiyatı benim için çok pahalı.','cher','pahalı',2,690),
  (v_cid,'Elle vit à Paris depuis cinq ans.','Beş yıldır Paris te yaşıyor.','vit','yaşıyor',2,700),
  (v_cid,'Puis-je essayer ce pantalon dans une autre taille?','Bu pantolonu farklı bir bedende deneyebilir miyim?','taille','beden',2,710),
  (v_cid,'J ai oublié mon portefeuille à la maison ce matin.','Bu sabah cüzdanımı evde unuttum.','portefeuille','cüzdan',2,720),
  (v_cid,'Ils nous ont invités à leur mariage le mois prochain.','Bizi gelecek ay düğünlerine davet ettiler.','mariage','düğün',2,730),
  (v_cid,'Le bus était en retard à cause des embouteillages.','Otobüs trafik tıkanıklığı nedeniyle geç kaldı.','retard','gecikme',2,740),
  (v_cid,'Elle a acheté un nouvel ordinateur pour ses études.','Dersleri için yeni bir bilgisayar satın aldı.','ordinateur','bilgisayar',2,750),
  (v_cid,'Il économise de l argent pour acheter une voiture.','Araba almak için para biriktiriyor.','économise','biriktiriyor',2,760),
  (v_cid,'Nous devons arriver à l aéroport deux heures à l avance.','Havalimanına iki saat erken gelmeliyiz.','aéroport','havalimanı',2,770),
  (v_cid,'Elle a pris rendez-vous chez le médecin.','Doktora randevu aldı.','rendez-vous','randevu',2,780),
  -- ── Difficulty 3 ──────────────────────────────────────────────
  (v_cid,'Il est essentiel de prendre soin de sa santé mentale.','Ruh sağlığına dikkat etmek çok önemlidir.','mentale','zihinsel',3,790),
  (v_cid,'Nous devons envisager toutes les possibilités avant de prendre une décision.','Karar vermeden önce tüm olasılıkları değerlendirmeliyiz.','envisager','değerlendirmek',3,800),
  (v_cid,'Les nouvelles réglementations entreront en vigueur l année prochaine.','Yeni düzenlemeler gelecek yıl yürürlüğe girecek.','réglementations','düzenlemeler',3,810),
  (v_cid,'L entreprise a décidé d élargir ses activités à de nouveaux marchés.','Şirket faaliyetlerini yeni pazarlara genişletmeye karar verdi.','élargir','genişletmek',3,820),
  (v_cid,'Elle a obtenu une bourse pour étudier dans une université prestigieuse.','Prestijli bir üniversitede okumak için burs aldı.','bourse','burs',3,830),
  (v_cid,'Les négociations entre les deux pays ont duré plusieurs mois.','İki ülke arasındaki müzakereler birkaç ay sürdü.','négociations','müzakereler',3,840),
  (v_cid,'Malgré les difficultés économiques, l entreprise a réussi à trouver de nouveaux financements.','Ekonomik zorluklara rağmen şirket yeni finansman bulmayı başardı.','difficultés','zorluklar',3,850),
  (v_cid,'La montée du niveau des mers menace les zones côtières.','Deniz seviyesinin yükselmesi kıyı bölgelerini tehdit ediyor.','menace','tehdit ediyor',3,860),
  (v_cid,'À moins d agir immédiatement, la situation va se détériorer.','Hemen harekete geçmezsek durum daha da kötüleşecek.','immédiatement','hemen',3,870)
  ON CONFLICT DO NOTHING;
END $$;

-- ═══════════════════════════════════════════════════
-- TR → DE  (Turkish speakers learning German)
-- ═══════════════════════════════════════════════════
DO $$
DECLARE v_cid UUID;
BEGIN
  SELECT id INTO v_cid FROM courses
  WHERE native_lang_id=(SELECT id FROM languages WHERE code='TR' LIMIT 1)
    AND target_lang_id=(SELECT id FROM languages WHERE code='DE' LIMIT 1)
    AND is_active=TRUE LIMIT 1;
  IF v_cid IS NULL THEN RETURN; END IF;

  INSERT INTO sentences(course_id,target_text,native_text,key_word,key_word_native,difficulty,order_index) VALUES
  -- ── Difficulty 1 ──────────────────────────────────────────────
  (v_cid,'Meine Schwester hört gern Musik.','Kız kardeşim müzik dinlemeyi seviyor.','Schwester','kız kardeş',1,500),
  (v_cid,'Die Katze schläft auf dem Sofa.','Kedi kanepede uyuyor.','schläft','uyuyor',1,510),
  (v_cid,'Ich putze mir zweimal täglich die Zähne.','Günde iki kez dişlerimi fırçalarım.','Zähne','diş',1,520),
  (v_cid,'Er ist Arzt im Krankenhaus.','O hastanede doktordur.','Arzt','doktor',1,530),
  (v_cid,'Ich brauche ein neues Paar Schuhe.','Yeni bir çift ayakkabıya ihtiyacım var.','Schuhe','ayakkabı',1,540),
  (v_cid,'Meine Lieblingsjahreszeit ist der Sommer.','En sevdiğim mevsim yazdır.','Sommer','yaz',1,550),
  (v_cid,'Er spielt in seiner Freizeit Gitarre.','Boş zamanlarında gitar çalar.','Gitarre','gitar',1,560),
  (v_cid,'Ich möchte kochen lernen.','Yemek yapmayı öğrenmek istiyorum.','kochen','yemek pişirmek',1,570),
  (v_cid,'Der Hund läuft im Garten.','Köpek bahçede koşuyor.','Garten','bahçe',1,580),
  (v_cid,'Die Kinder sind heute sehr glücklich.','Çocuklar bugün çok mutlu.','glücklich','mutlu',1,590),
  (v_cid,'Mein Vater ist Lehrer.','Babam öğretmendir.','Lehrer','öğretmen',1,600),
  (v_cid,'Wir schauen sonntags Filme.','Pazar günleri film izliyoruz.','Filme','film',1,610),
  (v_cid,'Meine Mutter macht jeden Morgen Frühstück.','Annem her sabah kahvaltı hazırlar.','Frühstück','kahvaltı',1,620),
  (v_cid,'Er fährt mit dem Fahrrad zur Schule.','O okula bisikletiyle gider.','Fahrrad','bisiklet',1,630),
  (v_cid,'Der Supermarkt ist in der Nähe meines Hauses.','Süpermarket evimin yakınında.','Nähe','yakın',1,640),
  -- ── Difficulty 2 ──────────────────────────────────────────────
  (v_cid,'Können Sie mir den Weg zum Bahnhof zeigen?','Lütfen bana istasyona giden yolu gösterebilir misiniz?','Bahnhof','istasyon',2,650),
  (v_cid,'Ich habe Kopfschmerzen und brauche Medikamente.','Başım ağrıyor ve ilaca ihtiyacım var.','Kopfschmerzen','baş ağrısı',2,660),
  (v_cid,'Sie hat einen Tisch für zwei im Restaurant reserviert.','Restoranda iki kişilik masa rezervasyonu yaptı.','reserviert','rezerve etti',2,670),
  (v_cid,'Wir planen eine Reise nach Spanien nächsten Sommer.','Gelecek yaz İspanya ya bir gezi planlıyoruz.','Reise','gezi',2,680),
  (v_cid,'Der Preis dieser Jacke ist zu teuer für mich.','Bu ceketin fiyatı benim için çok pahalı.','teuer','pahalı',2,690),
  (v_cid,'Sie lebt seit fünf Jahren in Berlin.','Beş yıldır Berlin de yaşıyor.','lebt','yaşıyor',2,700),
  (v_cid,'Kann ich dieses Hemd in einer anderen Größe anprobieren?','Bu gömleği farklı bir bedende deneyebilir miyim?','Größe','beden',2,710),
  (v_cid,'Heute Morgen habe ich mein Portemonnaie zu Hause vergessen.','Bu sabah cüzdanımı evde unuttum.','Portemonnaie','cüzdan',2,720),
  (v_cid,'Sie haben uns zu ihrer Hochzeit nächsten Monat eingeladen.','Bizi gelecek ay düğünlerine davet ettiler.','Hochzeit','düğün',2,730),
  (v_cid,'Der Bus kam wegen des starken Verkehrs zu spät.','Otobüs yoğun trafik nedeniyle geç kaldı.','Verkehrs','trafik',2,740),
  (v_cid,'Sie hat einen neuen Laptop für ihr Studium gekauft.','Dersleri için yeni bir dizüstü bilgisayar satın aldı.','Laptop','dizüstü',2,750),
  (v_cid,'Er spart Geld für ein neues Auto.','Yeni bir araba için para biriktiriyor.','spart','biriktiriyor',2,760),
  (v_cid,'Wir sollten zwei Stunden früher am Flughafen sein.','Havalimanına iki saat erken gelmeliyiz.','Flughafen','havalimanı',2,770),
  (v_cid,'Sie hat beim Arzt einen Termin vereinbart.','Doktora randevu aldı.','Termin','randevu',2,780),
  -- ── Difficulty 3 ──────────────────────────────────────────────
  (v_cid,'Es ist wichtig, auf seine psychische Gesundheit zu achten.','Ruh sağlığına dikkat etmek önemlidir.','Gesundheit','sağlık',3,790),
  (v_cid,'Wir sollten alle Möglichkeiten bedenken, bevor wir eine Entscheidung treffen.','Karar vermeden önce tüm olasılıkları değerlendirmeliyiz.','Entscheidung','karar',3,800),
  (v_cid,'Die neuen Vorschriften treten Anfang nächsten Jahres in Kraft.','Yeni düzenlemeler gelecek yılın başında yürürlüğe girecek.','Vorschriften','düzenlemeler',3,810),
  (v_cid,'Das Unternehmen beschloss, seine Aktivitäten auf neue Märkte auszuweiten.','Şirket faaliyetlerini yeni pazarlara genişletmeye karar verdi.','auszuweiten','genişletmek',3,820),
  (v_cid,'Sie erhielt ein Stipendium für ein Studium an einer renommierten Universität.','Prestijli bir üniversitede okumak için burs aldı.','Stipendium','burs',3,830),
  (v_cid,'Die Verhandlungen zwischen den beiden Ländern dauerten mehrere Monate.','İki ülke arasındaki müzakereler birkaç ay sürdü.','Verhandlungen','müzakereler',3,840),
  (v_cid,'Trotz wirtschaftlicher Schwierigkeiten gelang es dem Unternehmen, neue Finanzierung zu sichern.','Ekonomik zorluklara rağmen şirket yeni finansman sağlamayı başardı.','Schwierigkeiten','zorluklar',3,850),
  (v_cid,'Der steigende Meeresspiegel bedroht Küstengemeinden weltweit.','Yükselen deniz seviyeleri dünya genelinde kıyı topluluklarını tehdit ediyor.','bedroht','tehdit ediyor',3,860),
  (v_cid,'Wenn wir nicht sofort handeln, wird sich die Situation verschlechtern.','Hemen harekete geçmezsek durum daha da kötüleşecek.','sofort','hemen',3,870)
  ON CONFLICT DO NOTHING;
END $$;

-- ═══════════════════════════════════════════════════
-- TR → ES  (Turkish speakers learning Spanish)
-- ═══════════════════════════════════════════════════
DO $$
DECLARE v_cid UUID;
BEGIN
  SELECT id INTO v_cid FROM courses
  WHERE native_lang_id=(SELECT id FROM languages WHERE code='TR' LIMIT 1)
    AND target_lang_id=(SELECT id FROM languages WHERE code='ES' LIMIT 1)
    AND is_active=TRUE LIMIT 1;
  IF v_cid IS NULL THEN RETURN; END IF;

  INSERT INTO sentences(course_id,target_text,native_text,key_word,key_word_native,difficulty,order_index) VALUES
  -- ── Difficulty 1 ──────────────────────────────────────────────
  (v_cid,'A mi hermana le gusta escuchar música.','Kız kardeşim müzik dinlemeyi seviyor.','hermana','kız kardeş',1,500),
  (v_cid,'El gato está durmiendo en el sofá.','Kedi kanepede uyuyor.','durmiendo','uyuyor',1,510),
  (v_cid,'Me cepillo los dientes dos veces al día.','Günde iki kez dişlerimi fırçalarım.','dientes','diş',1,520),
  (v_cid,'Él es médico en el hospital.','O hastanede doktordur.','médico','doktor',1,530),
  (v_cid,'Necesito un par de zapatos nuevos.','Yeni bir çift ayakkabıya ihtiyacım var.','zapatos','ayakkabı',1,540),
  (v_cid,'Mi estación favorita es el verano.','En sevdiğim mevsim yazdır.','verano','yaz',1,550),
  (v_cid,'Él toca la guitarra en su tiempo libre.','Boş zamanlarında gitar çalar.','guitarra','gitar',1,560),
  (v_cid,'Quiero aprender a cocinar.','Yemek yapmayı öğrenmek istiyorum.','cocinar','yemek pişirmek',1,570),
  (v_cid,'El perro corre en el jardín.','Köpek bahçede koşuyor.','jardín','bahçe',1,580),
  (v_cid,'Los niños están muy contentos hoy.','Çocuklar bugün çok mutlu.','contentos','mutlu',1,590),
  (v_cid,'Mi padre es maestro.','Babam öğretmendir.','maestro','öğretmen',1,600),
  (v_cid,'Vemos películas los domingos.','Pazar günleri film izliyoruz.','películas','film',1,610),
  (v_cid,'Mi madre prepara el desayuno cada mañana.','Annem her sabah kahvaltı hazırlar.','desayuno','kahvaltı',1,620),
  (v_cid,'Él va al colegio en bicicleta.','O okula bisikletiyle gider.','bicicleta','bisiklet',1,630),
  (v_cid,'El supermercado está cerca de mi casa.','Süpermarket evimin yakınında.','cerca','yakın',1,640),
  -- ── Difficulty 2 ──────────────────────────────────────────────
  (v_cid,'Puede indicarme cómo llegar a la estación?','Lütfen bana istasyona giden yolu gösterebilir misiniz?','estación','istasyon',2,650),
  (v_cid,'Tengo dolor de cabeza y necesito medicamentos.','Başım ağrıyor ve ilaca ihtiyacım var.','medicamentos','ilaç',2,660),
  (v_cid,'Ella hizo una reserva para dos en el restaurante.','Restoranda iki kişilik masa rezervasyonu yaptı.','reserva','rezervasyon',2,670),
  (v_cid,'Estamos planeando un viaje a Francia el próximo verano.','Gelecek yaz Fransa ya bir gezi planlıyoruz.','viaje','gezi',2,680),
  (v_cid,'El precio de esta chaqueta es demasiado caro para mí.','Bu ceketin fiyatı benim için çok pahalı.','caro','pahalı',2,690),
  (v_cid,'Ella lleva cinco años viviendo en Madrid.','Beş yıldır Madrid de yaşıyor.','viviendo','yaşıyor',2,700),
  (v_cid,'Puedo probarme esta camisa en otra talla?','Bu gömleği farklı bir bedende deneyebilir miyim?','talla','beden',2,710),
  (v_cid,'Esta mañana olvidé mi cartera en casa.','Bu sabah cüzdanımı evde unuttum.','cartera','cüzdan',2,720),
  (v_cid,'Nos invitaron a su boda el mes que viene.','Bizi gelecek ay düğünlerine davet ettiler.','boda','düğün',2,730),
  (v_cid,'El autobús llegó tarde por el tráfico.','Otobüs trafik nedeniyle geç kaldı.','tráfico','trafik',2,740),
  (v_cid,'Ella compró un ordenador nuevo para sus estudios.','Dersleri için yeni bir bilgisayar satın aldı.','ordenador','bilgisayar',2,750),
  (v_cid,'Él está ahorrando dinero para comprar un coche nuevo.','Yeni bir araba almak için para biriktiriyor.','ahorrando','biriktiriyor',2,760),
  (v_cid,'Tenemos que llegar al aeropuerto con dos horas de antelación.','Havalimanına iki saat erken gelmeliyiz.','aeropuerto','havalimanı',2,770),
  (v_cid,'Ella concertó una cita con el médico.','Doktora randevu aldı.','cita','randevu',2,780),
  -- ── Difficulty 3 ──────────────────────────────────────────────
  (v_cid,'Es fundamental cuidar la salud mental.','Ruh sağlığına dikkat etmek çok önemlidir.','mental','zihinsel',3,790),
  (v_cid,'Debemos considerar todas las opciones antes de tomar una decisión final.','Nihai karar vermeden önce tüm seçenekleri değerlendirmeliyiz.','decisión','karar',3,800),
  (v_cid,'Las nuevas regulaciones entrarán en vigor a principios del próximo año.','Yeni düzenlemeler gelecek yılın başında yürürlüğe girecek.','regulaciones','düzenlemeler',3,810),
  (v_cid,'La empresa decidió expandir sus operaciones a nuevos mercados.','Şirket faaliyetlerini yeni pazarlara genişletmeye karar verdi.','expandir','genişletmek',3,820),
  (v_cid,'Le concedieron una beca para estudiar en una universidad de prestigio.','Prestijli bir üniversitede okumak için burs verildi.','beca','burs',3,830),
  (v_cid,'Las negociaciones entre los dos países duraron varios meses.','İki ülke arasındaki müzakereler birkaç ay sürdü.','negociaciones','müzakereler',3,840),
  (v_cid,'A pesar de las dificultades económicas, la empresa logró asegurar nueva financiación.','Ekonomik zorluklara rağmen şirket yeni finansman sağlamayı başardı.','dificultades','zorluklar',3,850),
  (v_cid,'El aumento del nivel del mar amenaza a las comunidades costeras.','Deniz seviyesinin yükselmesi kıyı topluluklarını tehdit ediyor.','amenaza','tehdit ediyor',3,860),
  (v_cid,'Si no actuamos de inmediato, la situación empeorará.','Hemen harekete geçmezsek durum daha da kötüleşecek.','inmediato','hemen',3,870)
  ON CONFLICT DO NOTHING;
END $$;

-- ═══════════════════════════════════════════════════
-- TR → IT  (Turkish speakers learning Italian)
-- ═══════════════════════════════════════════════════
DO $$
DECLARE v_cid UUID;
BEGIN
  SELECT id INTO v_cid FROM courses
  WHERE native_lang_id=(SELECT id FROM languages WHERE code='TR' LIMIT 1)
    AND target_lang_id=(SELECT id FROM languages WHERE code='IT' LIMIT 1)
    AND is_active=TRUE LIMIT 1;
  IF v_cid IS NULL THEN RETURN; END IF;

  INSERT INTO sentences(course_id,target_text,native_text,key_word,key_word_native,difficulty,order_index) VALUES
  -- ── Difficulty 1 ──────────────────────────────────────────────
  (v_cid,'Mia sorella ama ascoltare musica.','Kız kardeşim müzik dinlemeyi seviyor.','sorella','kız kardeş',1,500),
  (v_cid,'Il gatto dorme sul divano.','Kedi kanepede uyuyor.','dorme','uyuyor',1,510),
  (v_cid,'Mi lavo i denti due volte al giorno.','Günde iki kez dişlerimi fırçalarım.','denti','diş',1,520),
  (v_cid,'È medico in ospedale.','O hastanede doktordur.','medico','doktor',1,530),
  (v_cid,'Ho bisogno di un nuovo paio di scarpe.','Yeni bir çift ayakkabıya ihtiyacım var.','scarpe','ayakkabı',1,540),
  (v_cid,'La mia stagione preferita è l estate.','En sevdiğim mevsim yazdır.','estate','yaz',1,550),
  (v_cid,'Suona la chitarra nel tempo libero.','Boş zamanlarında gitar çalar.','chitarra','gitar',1,560),
  (v_cid,'Il cane corre in giardino.','Köpek bahçede koşuyor.','giardino','bahçe',1,570),
  (v_cid,'I bambini sono molto felici oggi.','Çocuklar bugün çok mutlu.','felici','mutlu',1,580),
  (v_cid,'Mio padre è insegnante.','Babam öğretmendir.','insegnante','öğretmen',1,590),
  (v_cid,'Mia madre prepara la colazione ogni mattina.','Annem her sabah kahvaltı hazırlar.','colazione','kahvaltı',1,600),
  (v_cid,'Lui va a scuola in bicicletta.','O okula bisikletiyle gider.','bicicletta','bisiklet',1,610),
  (v_cid,'Il supermercato è vicino a casa mia.','Süpermarket evimin yakınında.','vicino','yakın',1,620),
  -- ── Difficulty 2 ──────────────────────────────────────────────
  (v_cid,'Può indicarmi la strada per la stazione?','Lütfen bana istasyona giden yolu gösterebilir misiniz?','stazione','istasyon',2,630),
  (v_cid,'Ho mal di testa e ho bisogno di medicine.','Başım ağrıyor ve ilaca ihtiyacım var.','medicine','ilaç',2,640),
  (v_cid,'Ha prenotato un tavolo per due al ristorante.','Restoranda iki kişilik masa ayırttırdı.','prenotato','rezervasyon yaptı',2,650),
  (v_cid,'Stiamo pianificando un viaggio in Spagna la prossima estate.','Gelecek yaz İspanya ya bir gezi planlıyoruz.','viaggio','gezi',2,660),
  (v_cid,'Il prezzo di questo cappotto è troppo caro per me.','Bu paltonun fiyatı benim için çok pahalı.','caro','pahalı',2,670),
  (v_cid,'Vive a Roma da cinque anni.','Beş yıldır Roma da yaşıyor.','vive','yaşıyor',2,680),
  (v_cid,'Posso provare questa camicia in una taglia diversa?','Bu gömleği farklı bir bedende deneyebilir miyim?','taglia','beden',2,690),
  (v_cid,'Stamattina ho dimenticato il portafoglio a casa.','Bu sabah cüzdanımı evde unuttum.','portafoglio','cüzdan',2,700),
  (v_cid,'Ci hanno invitato al loro matrimonio il mese prossimo.','Bizi gelecek ay düğünlerine davet ettiler.','matrimonio','düğün',2,710),
  (v_cid,'L autobus era in ritardo a causa del traffico.','Otobüs trafik nedeniyle geç kaldı.','traffico','trafik',2,720),
  (v_cid,'Ha comprato un nuovo computer per i suoi studi.','Dersleri için yeni bir bilgisayar satın aldı.','computer','bilgisayar',2,730),
  (v_cid,'Sta risparmiando soldi per comprare una macchina nuova.','Yeni bir araba almak için para biriktiriyor.','risparmiando','biriktiriyor',2,740),
  (v_cid,'Dobbiamo arrivare all aeroporto con due ore di anticipo.','Havalimanına iki saat erken gelmeliyiz.','aeroporto','havalimanı',2,750),
  (v_cid,'Ha preso un appuntamento dal medico.','Doktora randevu aldı.','appuntamento','randevu',2,760),
  -- ── Difficulty 3 ──────────────────────────────────────────────
  (v_cid,'È fondamentale prendersi cura della salute mentale.','Ruh sağlığına dikkat etmek çok önemlidir.','mentale','zihinsel',3,770),
  (v_cid,'Dobbiamo considerare tutte le opzioni prima di prendere una decisione definitiva.','Nihai karar vermeden önce tüm seçenekleri değerlendirmeliyiz.','considerare','değerlendirmek',3,780),
  (v_cid,'I nuovi regolamenti entreranno in vigore all inizio del prossimo anno.','Yeni düzenlemeler gelecek yılın başında yürürlüğe girecek.','regolamenti','düzenlemeler',3,790),
  (v_cid,'L azienda ha deciso di espandere le sue attività in nuovi mercati.','Şirket faaliyetlerini yeni pazarlara genişletmeye karar verdi.','espandere','genişletmek',3,800),
  (v_cid,'Le è stata concessa una borsa di studio per un università prestigiosa.','Prestijli bir üniversitede okumak için burs verildi.','borsa','burs',3,810),
  (v_cid,'I negoziati tra i due paesi sono durati diversi mesi.','İki ülke arasındaki müzakereler birkaç ay sürdü.','negoziati','müzakereler',3,820),
  (v_cid,'Se non agiamo subito, la situazione peggiorerà.','Hemen harekete geçmezsek durum daha da kötüleşecek.','subito','hemen',3,830)
  ON CONFLICT DO NOTHING;
END $$;

-- ═══════════════════════════════════════════════════
-- TR → RU  (Turkish speakers learning Russian)
-- ═══════════════════════════════════════════════════
DO $$
DECLARE v_cid UUID;
BEGIN
  SELECT id INTO v_cid FROM courses
  WHERE native_lang_id=(SELECT id FROM languages WHERE code='TR' LIMIT 1)
    AND target_lang_id=(SELECT id FROM languages WHERE code='RU' LIMIT 1)
    AND is_active=TRUE LIMIT 1;
  IF v_cid IS NULL THEN RETURN; END IF;

  INSERT INTO sentences(course_id,target_text,native_text,key_word,key_word_native,difficulty,order_index) VALUES
  -- ── Difficulty 1 ──────────────────────────────────────────────
  (v_cid,'Моя сестра любит слушать музыку.','Kız kardeşim müzik dinlemeyi seviyor.','сестра','kız kardeş',1,500),
  (v_cid,'Кошка спит на диване.','Kedi kanepede uyuyor.','спит','uyuyor',1,510),
  (v_cid,'Я чищу зубы дважды в день.','Günde iki kez dişlerimi fırçalarım.','зубы','diş',1,520),
  (v_cid,'Он работает врачом в больнице.','O hastanede doktordur.','врачом','doktor',1,530),
  (v_cid,'Мне нужна новая пара обуви.','Yeni bir çift ayakkabıya ihtiyacım var.','обуви','ayakkabı',1,540),
  (v_cid,'Моё любимое время года — лето.','En sevdiğim mevsim yazdır.','лето','yaz',1,550),
  (v_cid,'Он играет на гитаре в свободное время.','Boş zamanlarında gitar çalar.','гитаре','gitar',1,560),
  (v_cid,'Собака бегает в саду.','Köpek bahçede koşuyor.','саду','bahçe',1,570),
  (v_cid,'Дети сегодня очень счастливы.','Çocuklar bugün çok mutlu.','счастливы','mutlu',1,580),
  (v_cid,'Мой отец — учитель.','Babam öğretmendir.','учитель','öğretmen',1,590),
  (v_cid,'Мама каждое утро готовит завтрак.','Annem her sabah kahvaltı hazırlar.','завтрак','kahvaltı',1,600),
  (v_cid,'Он едет в школу на велосипеде.','O okula bisikletiyle gider.','велосипеде','bisiklet',1,610),
  (v_cid,'Супермаркет находится рядом с моим домом.','Süpermarket evimin yakınında.','рядом','yakın',1,620),
  -- ── Difficulty 2 ──────────────────────────────────────────────
  (v_cid,'Не могли бы вы показать мне дорогу до вокзала?','Lütfen bana istasyona giden yolu gösterebilir misiniz?','вокзала','istasyon',2,630),
  (v_cid,'У меня болит голова, мне нужны лекарства.','Başım ağrıyor ve ilaca ihtiyacım var.','лекарства','ilaç',2,640),
  (v_cid,'Она забронировала столик на двоих в ресторане.','Restoranda iki kişilik masa ayırttırdı.','забронировала','rezerve etti',2,650),
  (v_cid,'Мы планируем поездку в Испанию следующим летом.','Gelecek yaz İspanya ya bir gezi planlıyoruz.','поездку','gezi',2,660),
  (v_cid,'Цена этой куртки слишком высока для меня.','Bu ceketin fiyatı benim için çok yüksek.','Цена','fiyat',2,670),
  (v_cid,'Она живёт в Москве уже пять лет.','Beş yıldır Moskova da yaşıyor.','живёт','yaşıyor',2,680),
  (v_cid,'Можно примерить эту рубашку другого размера?','Bu gömleği farklı bir bedende deneyebilir miyim?','размера','beden',2,690),
  (v_cid,'Сегодня утром я забыл кошелёк дома.','Bu sabah cüzdanımı evde unuttum.','кошелёк','cüzdan',2,700),
  (v_cid,'Они пригласили нас на свадьбу в следующем месяце.','Bizi gelecek ay düğünlerine davet ettiler.','свадьбу','düğün',2,710),
  (v_cid,'Автобус опоздал из-за пробок.','Otobüs trafik tıkanıklığı nedeniyle geç kaldı.','пробок','trafik',2,720),
  (v_cid,'Она купила новый ноутбук для учёбы.','Dersleri için yeni bir dizüstü bilgisayar satın aldı.','ноутбук','dizüstü',2,730),
  (v_cid,'Он копит деньги на новую машину.','Yeni bir araba almak için para biriktiriyor.','копит','biriktiriyor',2,740),
  (v_cid,'Нам нужно приехать в аэропорт на два часа раньше.','Havalimanına iki saat erken gelmeliyiz.','аэропорт','havalimanı',2,750),
  (v_cid,'Она записалась на приём к врачу.','Doktora randevu aldı.','приём','randevu',2,760),
  -- ── Difficulty 3 ──────────────────────────────────────────────
  (v_cid,'Важно заботиться о своём психическом здоровье.','Ruh sağlığına dikkat etmek önemlidir.','здоровье','sağlık',3,770),
  (v_cid,'Мы должны рассмотреть все варианты перед принятием окончательного решения.','Nihai karar vermeden önce tüm seçenekleri değerlendirmeliyiz.','рассмотреть','değerlendirmek',3,780),
  (v_cid,'Новые правила вступят в силу в начале следующего года.','Yeni düzenlemeler gelecek yılın başında yürürlüğe girecek.','правила','düzenlemeler',3,790),
  (v_cid,'Компания решила расширить свою деятельность на новые рынки.','Şirket faaliyetlerini yeni pazarlara genişletmeye karar verdi.','расширить','genişletmek',3,800),
  (v_cid,'Ей дали стипендию для обучения в престижном университете.','Prestijli bir üniversitede okumak için burs verildi.','стипендию','burs',3,810),
  (v_cid,'Переговоры между двумя странами длились несколько месяцев.','İki ülke arasındaki müzakereler birkaç ay sürdü.','Переговоры','müzakereler',3,820),
  (v_cid,'Если мы не примем меры немедленно, ситуация ухудшится.','Hemen harekete geçmezsek durum daha da kötüleşecek.','немедленно','hemen',3,830)
  ON CONFLICT DO NOTHING;
END $$;
