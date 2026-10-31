# Sitenin metinleri. Her sayfa: yol, dil, başlık, açıklama, H1, giriş, bölümler, SSS.
# Yeni sayfa eklemek için PAGES'e bir sözlük ekle ve `python3 web/build.py` çalıştır.

APP_URL = "https://apps.apple.com/app/id6474321549"
APP_ID = "6474321549"
# Uygulama App Store'a çıkınca True yap ve yeniden yayınla: butonlar ve QR (/app) doğrudan indirmeye döner.
# False iken butonlar "yakında" der, QR'ı okutan da "yakında" sayfasını görür (basılı QR'lar çıkışta kendiliğinden çalışır).
LIVE = False
SITE = "https://wordremai.app"
# GA4 web akışının ölçüm kimliği (G-XXXXXXX). Boşsa sitede takip kodu çıkmaz.
GA_ID = "G-FLKXCM0JHB"

# Dile göre ortak arayüz metinleri
UI = {
    "tr": {
        "cta": "App Store'dan indir", "cta_sub": "iPhone ve iPad için ücretsiz indir",
        "qr": "Telefonunun kamerasıyla okut, uygulamaya git", "how": "Nasıl çalışır?", "faq": "Sık sorulan sorular",
        "langs": "8 dil", "more": "Daha fazlası", "privacy": "Gizlilik", "terms": "Kullanım Şartları",
        "steps": [("Bas ve konuş", "Butona basılı tut, cümleni sesli söyle. Öğretmenin Lupa seni dinler ve sesli cevap verir."),
                  ("Anında geri bildirim", "Telaffuzunu ve cümleni nazikçe düzeltir; söyleyeceğin cümle fosforlu kalemle sayfada."),
                  ("Defterine yazılır", "Her sohbet defterinde bir sayfa olur. Kelimeye dokun, işaretle; anlamıyla tekrar listene düşsün.")],
        "eyebrow": "Lupa · yapay zekâ öğretmenin", "hero_alt": "WordRem AI ders sayfası: Lupa soru sorar, söylenecek cümle işaretli", "sticky": "doğru!",
        "gallery": "Uygulamanın içinden", "gallery_sub": "Her ders çizgili bir defter sayfasına yazılır.",
        "lang_names": "İngilizce, İspanyolca, Almanca, Fransızca, İtalyanca, Rusça, Çince ve Türkçe",
    },
    "en": {
        "cta": "Download on the App Store", "cta_sub": "Free to download for iPhone and iPad",
        "qr": "Scan with your phone camera to get the app", "how": "How it works", "faq": "FAQ",
        "langs": "8 languages", "more": "More", "privacy": "Privacy", "terms": "Terms",
        "steps": [("Hold and speak", "Hold the button and say it out loud. Lupa, your AI tutor, listens and answers by voice."),
                  ("Instant feedback", "Gentle corrections on pronunciation and grammar; the line to say is highlighted on the page."),
                  ("Written into your notebook", "Every chat becomes a page. Tap any word to mark it and it joins your reviews with its meaning.")],
        "eyebrow": "Lupa · your AI tutor", "hero_alt": "WordRem AI lesson page: Lupa asks, the line to say is highlighted", "sticky": "correct!",
        "gallery": "Inside the app", "gallery_sub": "Every lesson is written on a ruled notebook page.",
        "lang_names": "English, Spanish, German, French, Italian, Russian, Chinese and Turkish",
    },
    "de": {
        "cta": "Im App Store laden", "cta_sub": "Kostenlos für iPhone und iPad",
        "qr": "Mit der Handykamera scannen und die App laden", "how": "So funktioniert's", "faq": "Häufige Fragen",
        "langs": "8 Sprachen", "more": "Mehr", "privacy": "Datenschutz", "terms": "Nutzungsbedingungen",
        "steps": [("Halten und sprechen", "Halte die Taste gedrückt und sprich laut. Lupa, dein KI-Tutor, hört zu und antwortet."),
                  ("Sofort Feedback", "Freundliche Korrekturen zu Aussprache und Grammatik; der Satz zum Nachsprechen ist auf der Seite markiert."),
                  ("In dein Heft geschrieben", "Jedes Gespräch wird zu einer Seite. Tippe ein Wort an – es landet mit Bedeutung in deinen Wiederholungen.")],
        "eyebrow": "Lupa · dein KI-Tutor", "hero_alt": "WordRem AI Lektionsseite: Lupa fragt, der Satz zum Sagen ist markiert", "sticky": "richtig!",
        "gallery": "Ein Blick in die App", "gallery_sub": "Jede Lektion wird auf eine linierte Heftseite geschrieben.",
        "lang_names": "Englisch, Spanisch, Deutsch, Französisch, Italienisch, Russisch, Chinesisch und Türkisch",
    },
    "fr": {
        "cta": "Télécharger dans l'App Store", "cta_sub": "Gratuit sur iPhone et iPad",
        "qr": "Scanne avec l'appareil photo pour ouvrir l'app", "how": "Comment ça marche", "faq": "Questions fréquentes",
        "langs": "8 langues", "more": "Plus", "privacy": "Confidentialité", "terms": "Conditions",
        "steps": [("Appuie et parle", "Maintiens le bouton et parle à voix haute. Lupa, ton tuteur IA, écoute et te répond."),
                  ("Correction immédiate", "Des corrections bienveillantes ; la phrase à dire est surlignée sur la page."),
                  ("Écrit dans ton carnet", "Chaque conversation devient une page. Touche un mot pour le surligner : il rejoint tes révisions avec sa signification.")],
        "eyebrow": "Lupa · ton tuteur IA", "hero_alt": "Page de leçon WordRem AI : Lupa pose une question, la phrase à dire est surlignée", "sticky": "correct !",
        "gallery": "Dans l'app", "gallery_sub": "Chaque leçon s'écrit sur une page de carnet lignée.",
        "lang_names": "anglais, espagnol, allemand, français, italien, russe, chinois et turc",
    },
    "es": {
        "cta": "Descargar en el App Store", "cta_sub": "Gratis para iPhone y iPad",
        "qr": "Escanea con la cámara del móvil para abrir la app", "how": "Cómo funciona", "faq": "Preguntas frecuentes",
        "langs": "8 idiomas", "more": "Más", "privacy": "Privacidad", "terms": "Términos",
        "steps": [("Mantén y habla", "Mantén pulsado el botón y habla en voz alta. Lupa, tu tutor de IA, escucha y responde."),
                  ("Corrección al instante", "Correcciones amables; la frase que debes decir aparece marcada en la página."),
                  ("Escrito en tu cuaderno", "Cada conversación se convierte en una página. Toca una palabra para marcarla y pasa a tus repasos con su significado.")],
        "eyebrow": "Lupa · tu tutor de IA", "hero_alt": "Página de lección de WordRem AI: Lupa pregunta y la frase que debes decir está marcada", "sticky": "¡correcto!",
        "gallery": "Por dentro", "gallery_sub": "Cada lección se escribe en una página de cuaderno rayada.",
        "lang_names": "inglés, español, alemán, francés, italiano, ruso, chino y turco",
    },
    "it": {
        "cta": "Scarica su App Store", "cta_sub": "Gratis per iPhone e iPad",
        "qr": "Inquadra con la fotocamera per aprire l'app", "how": "Come funziona", "faq": "Domande frequenti",
        "langs": "8 lingue", "more": "Altro", "privacy": "Privacy", "terms": "Termini",
        "steps": [("Tieni premuto e parla", "Tieni premuto il pulsante e parla ad alta voce. Lupa, il tuo tutor IA, ascolta e risponde."),
                  ("Correzioni immediate", "Correzioni gentili; la frase da dire è evidenziata sulla pagina."),
                  ("Scritto nel tuo quaderno", "Ogni conversazione diventa una pagina. Tocca una parola per evidenziarla: entra nei ripassi con il suo significato.")],
        "eyebrow": "Lupa · il tuo tutor IA", "hero_alt": "Pagina di lezione di WordRem AI: Lupa fa una domanda, la frase da dire è evidenziata", "sticky": "giusto!",
        "gallery": "Dentro l'app", "gallery_sub": "Ogni lezione viene scritta su una pagina a righe del quaderno.",
        "lang_names": "inglese, spagnolo, tedesco, francese, italiano, russo, cinese e turco",
    },
    "ru": {
        "cta": "Загрузить в App Store", "cta_sub": "Бесплатно для iPhone и iPad",
        "qr": "Наведите камеру телефона, чтобы открыть приложение", "how": "Как это работает", "faq": "Частые вопросы",
        "langs": "8 языков", "more": "Ещё", "privacy": "Конфиденциальность", "terms": "Условия",
        "steps": [("Нажми и говори", "Удерживай кнопку и говори вслух. Лупа, ИИ-репетитор, слушает и отвечает голосом."),
                  ("Мгновенная обратная связь", "Мягкие исправления; фраза, которую нужно сказать, выделена на странице."),
                  ("Записано в тетрадь", "Каждый разговор становится страницей. Нажми на слово — оно попадёт в повторение вместе со значением.")],
        "eyebrow": "Лупа · ваш ИИ-репетитор", "hero_alt": "Страница урока WordRem AI: Лупа задаёт вопрос, нужная фраза выделена", "sticky": "верно!",
        "gallery": "Внутри приложения", "gallery_sub": "Каждый урок записывается на разлинованную страницу тетради.",
        "lang_names": "английский, испанский, немецкий, французский, итальянский, русский, китайский и турецкий",
    },
}

PAGES = [
    # ---------------- Türkçe ----------------
    {
        "path": "/tr/", "lang": "tr", "group": "home", "shots": "tr",
        "title": "WordRem AI: Yapay Zeka ile İngilizce Konuşma Uygulaması",
        "desc": "Yapay zeka öğretmeninle sesli konuşarak İngilizce ve 7 dil daha öğren. Telaffuz düzeltme, gerçek hayat dersleri, rol oyunları. iPhone için ücretsiz indir.",
        "h1": "Yapay zeka ile İngilizce konuş, ilk günden",
        "lead": "Öğretmenin Lupa seninle gerçekten konuşur, her dersi de senin defterine yazar. Butona bas, sesli söyle, anında nazik geri bildirim al. Test çözmek yok, gerçek sohbet var.",
        "sections": [
            ("Neden WordRem AI?", [
                "Çoğu dil uygulaması kelime ezberletir. Konuşmaya gelince donup kalırsın. WordRem AI'da her ders konuşarak geçer: öğretmenin soru sorar, sen cevap verirsin, o seni düzeltir.",
                "Hiç İngilizce bilmiyorsan sorun değil. Başlangıçta öğretmenin Türkçe açıklar, söylemen gereken her cümle çevirisi ve sesiyle ekrana kart olarak gelir.",
                "Utanma, yargılanma yok. Aynı cümleyi istediğin kadar tekrar edebilir, beğenmediğin soruyu geçebilir, konuyu değiştirebilirsin.",
            ]),
            ("Neler var?", [
                "• Kafe, havalimanı, tanışma, iş gibi gerçek hayat anlarına göre kısa sesli dersler",
                "• Seninle birlikte ilerleyen, adım adım bir konuşma planı",
                "• İstediğin konuda serbest sohbet: rol yap, soru sor, gününü anlat",
                "• Konuşma defterin: her sohbet tarihli bir sayfa olur, sonra sayfa sayfa çevirirsin",
                "• Sayfadaki kelimeye dokun, işaretle; anlamıyla birlikte tekrar listene düşer",
                "• Her ders bir mühürle ve öğrendiğin yeni ifadelerle (sesleriyle) biter",
                "• Seviyeni A1–C1 arasında seç, Lupa'nın konuşma hızını ayarla",
                "• 8 dil, her dilin defteri ve ilerlemesi ayrı",
            ]),
        ],
        "faq": [
            ("Yapay zeka ile İngilizce konuşma nasıl çalışır?", "Butona basılı tutup İngilizce konuşursun. Yapay zeka öğretmenin seni dinler, sesli cevap verir, hatalarını düzeltir ve doğru cümleyi kart olarak gösterir. Tıpkı özel ders gibi."),
            ("WordRem AI ücretsiz mi?", "İndirmesi ücretsiz ve ilk konuşmanı ücretsiz deneyebilirsin. WordRem AI Pro aboneliği konuşma planının tamamını ve her ay bol konuşma süresi açar."),
            ("Hiç İngilizce bilmiyorum, kullanabilir miyim?", "Evet. Başlangıç seviyesinde öğretmenin Türkçe açıklar ve her cümleyi çevirisiyle verir. İlk merhabandan başlarsın."),
            ("Telaffuzumu düzeltir mi?", "Evet. Söylediğini dinler, yanlış ya da eksik kısmı nazikçe söyler ve doğrusunu tekrar ettirir."),
            ("Hangi dilleri öğrenebilirim?", "İngilizce, İspanyolca, Almanca, Fransızca, İtalyanca, Rusça, Çince ve Türkçe."),
            ("Android'de var mı?", "Şu an iPhone ve iPad için App Store'da."),
        ],
        "links": ["/tr/yapay-zeka-ile-ingilizce-konusma/", "/tr/ingilizce-konusma-pratigi/", "/tr/ingilizce-telaffuz/"],
    },
    {
        "path": "/tr/yapay-zeka-ile-ingilizce-konusma/", "lang": "tr", "group": "ai-tutor", "shots": "tr",
        "title": "Yapay Zeka ile İngilizce Konuşma: Sesli AI Öğretmen | WordRem AI",
        "desc": "Yapay zeka ile İngilizce konuşma pratiği yap: sesli AI öğretmen seni dinler, cevap verir, telaffuzunu düzeltir. Başlangıç seviyesi için Türkçe açıklamalı.",
        "h1": "Yapay zeka ile İngilizce konuşma",
        "lead": "İngilizce konuşmayı öğrenmenin en hızlı yolu konuşmak. Ama karşında her gün seninle sabırla konuşacak biri yoksa? WordRem AI'ın sesli yapay zeka öğretmeni tam olarak bunun için var.",
        "sections": [
            ("Sesli AI öğretmen ne yapar?", [
                "Seninle yazışmaz, konuşur. Sen sesli söylersin, o sesli cevap verir. Cümlende hata varsa nazikçe düzeltir, doğru hâlini ekranda kart olarak gösterir ve sana tekrar ettirir.",
                "Seni tanır: adını, işini, sevdiklerini sorar ve dersi senin hayatına göre kurar. \"I like music\" yerine kendi hobini söylemeyi öğrenirsin.",
            ]),
            ("Kimler için?", [
                "• Okulda yıllarca İngilizce görüp hâlâ konuşamayanlar",
                "• İş görüşmesine, yurt dışı seyahatine ya da sınavın konuşma bölümüne hazırlananlar",
                "• Özel ders ücretine bütçesi yetmeyen ama her gün pratik yapmak isteyenler",
                "• Yanlış söylerim diye konuşmaktan çekinenler",
            ]),
            ("Bir ders nasıl geçer?", [
                "1. Öğretmenin selam verir ve sana bir soru sorar. 2. Sen cevap verirsin; bilmediğin kelimeyi Türkçe sorabilirsin. 3. Her yeni ifade kart olarak gelir, sesini dinleyip söylersin. 4. Ders, öğretmenin karşı tarafı oynadığı kısa bir rol oyunuyla biter: garson, gümrük memuru, yeni bir arkadaş.",
            ]),
        ],
        "faq": [
            ("Yapay zeka ile İngilizce konuşmak gerçekten işe yarar mı?", "Konuşma becerisi ancak konuşarak gelişir. Yapay zeka öğretmeni her an hazır, sabırlı ve seni yargılamadığı için çok daha fazla konuşma pratiği yaparsın."),
            ("ChatGPT'den farkı ne?", "WordRem AI bir dil öğretmeni olarak tasarlandı: seviyene göre plan, kartlarla yeni ifadeler, telaffuz geri bildirimi, rol oyunları ve unuttuğun ifadeleri geri getiren tekrarlar."),
            ("Ücretsiz deneyebilir miyim?", "Evet, uygulamayı ücretsiz indirip ilk konuşmanı ücretsiz yapabilirsin."),
        ],
        "links": ["/tr/", "/tr/ingilizce-konusma-pratigi/", "/tr/ingilizce-telaffuz/"],
    },
    {
        "path": "/tr/ingilizce-konusma-pratigi/", "lang": "tr", "group": "practice", "shots": "tr",
        "title": "İngilizce Konuşma Pratiği Uygulaması: Her Gün 10 Dakika | WordRem AI",
        "desc": "Evde İngilizce konuşma pratiği yap: yapay zeka öğretmenle gerçek hayat diyalogları, rol oyunları ve anında düzeltme. iPhone için ücretsiz indir.",
        "h1": "İngilizce konuşma pratiği, her gün 10 dakika",
        "lead": "İngilizceyi anlıyorsun ama konuşurken takılıyorsun. Çözüm daha çok gramer değil, daha çok konuşma. WordRem AI ile her gün kısa, gerçek konuşmalar yaparsın.",
        "sections": [
            ("Gerçek hayattan konuşmalar", [
                "Kafede sipariş vermek, havalimanında kaybolan bavulu sormak, yeni biriyle tanışmak, iş toplantısında kendini anlatmak. Dersler bu anlara göre kurulu, öğrendiğin her cümleyi gerçekten kullanırsın.",
            ]),
            ("Partner bulmana gerek yok", [
                "Konuşma partneri bulmak, saat ayarlamak, utanmak yok. Yapay zeka öğretmenin gece yarısı da hazır. İstediğin kadar tekrar et, istediğin konuya geç.",
            ]),
            ("İlerlemen kaybolmaz", [
                "Pratik yaptığın her ifade kaydedilir ve tam unutacakken akıllı tekrarlarla geri gelir. Planın kaldığın yerden devam eder.",
            ]),
        ],
        "faq": [
            ("Evde tek başıma İngilizce konuşma pratiği nasıl yaparım?", "Sesli bir yapay zeka öğretmenle konuşarak. WordRem AI seni dinler, cevap verir ve düzeltir, yani karşında gerçek bir konuşma partneri varmış gibi pratik yaparsın."),
            ("Günde ne kadar pratik yapmalıyım?", "Her gün 10 dakika, haftada bir saatlik dersten daha etkilidir. Uygulamadaki günlük hedef ve seri bunu kolaylaştırır."),
        ],
        "links": ["/tr/", "/tr/yapay-zeka-ile-ingilizce-konusma/", "/tr/ingilizce-telaffuz/"],
    },
    {
        "path": "/tr/ingilizce-telaffuz/", "lang": "tr", "group": "pronunciation", "shots": "tr",
        "title": "İngilizce Telaffuz Geliştirme: Yapay Zeka ile Anında Düzeltme | WordRem AI",
        "desc": "İngilizce telaffuzunu yapay zeka öğretmenle geliştir: söylediğini dinler, yanlışı gösterir, doğrusunu sesli tekrar ettirir. Ücretsiz dene.",
        "h1": "İngilizce telaffuzunu yapay zeka ile geliştir",
        "lead": "Doğru kelimeyi bilip yanlış söylemek en sinir bozucu şey. WordRem AI söylediğini dinler ve tam olarak neresinin yanlış olduğunu, nazikçe söyler.",
        "sections": [
            ("Nasıl düzeltir?", [
                "Cümleni sesli söylersin. Öğretmenin anlamadığı ya da yanlış duyduğu kısmı söyler, doğru hâlini sesli okur ve tekrar etmeni ister. Gerekirse kelimeyi hece hece ayırır.",
                "Her kartın üzerindeki hoparlöre basarak doğru telaffuzu istediğin kadar dinleyebilirsin.",
            ]),
            ("Sadece telaffuz değil", [
                "Telaffuz, cümlenin içinde gelişir. Bu yüzden WordRem AI'da tek tek kelime değil, gerçek konuşmanın içindeki cümleleri çalışırsın.",
            ]),
        ],
        "faq": [
            ("İngilizce telaffuz nasıl düzelir?", "Doğrusunu dinleyip sesli tekrar ederek ve geri bildirim alarak. WordRem AI bu döngüyü her cümlede otomatik yapar."),
            ("Aksanım çok kötü, utanıyorum. Yine de kullanabilir miyim?", "Evet. Karşında seni yargılayan biri yok; istediğin kadar tekrar edebilirsin."),
        ],
        "links": ["/tr/", "/tr/yapay-zeka-ile-ingilizce-konusma/", "/tr/ingilizce-konusma-pratigi/"],
    },
    # ---------------- English ----------------
    {
        "path": "/", "lang": "en", "group": "home", "shots": "en",
        "title": "WordRem AI: AI Language Tutor for Speaking Practice",
        "desc": "Speak a new language from day one with a voice AI tutor. Real conversations, instant pronunciation feedback and roleplays in 8 languages. Free on the App Store.",
        "h1": "Speak a new language from day one",
        "lead": "Lupa, your AI tutor, actually talks with you and writes every lesson into your own notebook. Hold the button, say it out loud and get instant, kind feedback, like a real lesson with a great teacher.",
        "sections": [
            ("Real conversations, not quizzes", [
                "• Short voice lessons built around real-life moments: meeting people, cafés, airports, work",
                "• Every phrase you need appears as a card with its translation and audio",
                "• Your tutor asks about your life, so every phrase is one you'll actually use",
                "• Each lesson ends with a roleplay where the tutor plays the other person",
            ]),
            ("Your speaking notebook", [
                "• Every conversation becomes a dated page you can flip through later",
                "• Tap any word on a page to mark it; it joins your reviews with its meaning",
                "• Each lesson ends with a stamp and the new phrases you learned, with audio",
            ]),
            ("A plan that grows with you", [
                "A step-by-step speaking plan from your first hello to handling the airport. Pick your level from A1 to C1 and how fast Lupa speaks. Free chat about anything, and smart reviews bring back phrases right before you'd forget them.",
            ]),
        ],
        "faq": [
            ("What is WordRem AI?", "A voice AI language tutor for iPhone and iPad. You speak, the tutor answers out loud, corrects you gently and teaches you new phrases through real-life conversations."),
            ("Is WordRem AI free?", "It's free to download and your first conversation is free. WordRem AI Pro unlocks the full speaking plan and generous monthly speaking time."),
            ("Which languages can I learn?", "English, Spanish, German, French, Italian, Russian, Chinese and Turkish."),
            ("Can complete beginners use it?", "Yes. Beginners get explanations in their native language, and every phrase comes with a translation."),
            ("Is it available on Android?", "Not yet. WordRem AI is on the App Store for iPhone and iPad."),
        ],
        "links": ["/ai-language-tutor/", "/speaking-practice-app/", "/tr/"],
    },
    {
        "path": "/ai-language-tutor/", "lang": "en", "group": "ai-tutor", "shots": "en",
        "title": "AI Language Tutor App with Voice Conversations | WordRem AI",
        "desc": "An AI language tutor you talk to out loud: it listens, answers and corrects your pronunciation and grammar. Learn Spanish, French, German and more. Free to try.",
        "h1": "An AI language tutor you can actually talk to",
        "lead": "Most apps make you tap. WordRem AI makes you talk. Your AI tutor holds a real spoken conversation with you, adapts to your level and corrects you as you go.",
        "sections": [
            ("What your AI tutor does", [
                "It asks you questions, listens to your answers and replies out loud. When you make a mistake, it gently shows the right phrase on a card and has you say it again.",
                "It learns about you (your name, your job, your hobbies) and builds each lesson around your life.",
            ]),
            ("Why speaking with AI works", [
                "Fluency comes from speaking time. An AI tutor is available 24/7, never judges you and never runs out of patience, so you speak far more than in a weekly class.",
            ]),
        ],
        "faq": [
            ("How is this different from ChatGPT?", "WordRem AI is built as a language teacher: a level-based speaking plan, new phrases as cards, pronunciation feedback, roleplays and spaced reviews of what you learned."),
            ("Can I try it for free?", "Yes. Download it free and have your first conversation at no cost."),
        ],
        "links": ["/", "/speaking-practice-app/"],
    },
    {
        "path": "/speaking-practice-app/", "lang": "en", "group": "practice", "shots": "en",
        "title": "Language Speaking Practice App: Talk Every Day | WordRem AI",
        "desc": "Practice speaking Spanish, English, French, German and more with a voice AI partner. Real-life dialogues, roleplays and instant feedback. Free on iPhone.",
        "h1": "Speaking practice, every day, without a partner",
        "lead": "You understand more than you can say. WordRem AI closes that gap with short daily conversations with a voice AI partner who's always ready.",
        "sections": [
            ("Practice real situations", [
                "Order at a café, check in at the airport, introduce yourself at work. Lessons follow real moments, so everything you practice is something you'll say.",
            ]),
            ("Never lose progress", [
                "Every phrase you practice is saved and comes back in smart reviews. Your plan picks up exactly where you left off.",
            ]),
        ],
        "faq": [
            ("How can I practice speaking a language alone?", "Talk to a voice AI tutor. WordRem AI listens, replies and corrects you, so it feels like practicing with a real conversation partner."),
            ("How much should I practice each day?", "Ten minutes a day beats an hour once a week. The daily goal and streak in the app help you stay consistent."),
        ],
        "links": ["/", "/ai-language-tutor/"],
    },
    # ---------------- Diğer diller (tek sayfa) ----------------
    {
        "path": "/de/", "lang": "de", "group": "home", "shots": "en",
        "title": "WordRem AI: Englisch sprechen mit KI-Tutor",
        "desc": "Englisch und 7 weitere Sprachen sprechend lernen: Dein KI-Sprachlehrer hört zu, antwortet und korrigiert deine Aussprache. Kostenlos im App Store.",
        "h1": "Englisch sprechen lernen mit KI",
        "lead": "WordRem AI ist ein sprachbasierter KI-Sprachlehrer, der wirklich mit dir spricht. Taste halten, laut sprechen, sofort freundliches Feedback bekommen.",
        "sections": [("Echte Gespräche statt Quiz", [
            "• Kurze Sprachlektionen für echte Situationen: Kennenlernen, Café, Flughafen, Arbeit",
            "• Jeder neue Satz erscheint als Karte mit Übersetzung und Audio",
            "• Freies Gespräch über jedes Thema, intelligente Wiederholungen",
            "• Dein Sprechheft: Jedes Gespräch wird zu einer Seite, markierte Wörter landen in deinen Wiederholungen",
            "• Anfänger bekommen Erklärungen auf Deutsch",
        ])],
        "faq": [
            ("Ist WordRem AI kostenlos?", "Der Download und dein erstes Gespräch sind kostenlos. WordRem AI Pro schaltet den kompletten Sprechplan und großzügige monatliche Sprechzeit frei."),
            ("Welche Sprachen kann ich lernen?", "Englisch, Spanisch, Deutsch, Französisch, Italienisch, Russisch, Chinesisch und Türkisch."),
        ],
        "links": ["/", "/tr/"],
    },
    {
        "path": "/fr/", "lang": "fr", "group": "home", "shots": "en",
        "title": "WordRem AI : parler anglais avec l'IA",
        "desc": "Apprends à parler anglais et 7 autres langues avec un tuteur IA vocal : il t'écoute, te répond et corrige ta prononciation. Gratuit sur l'App Store.",
        "h1": "Parler anglais avec l'IA, dès le premier jour",
        "lead": "WordRem AI est un tuteur de langue IA vocal qui parle vraiment avec toi. Maintiens le bouton, parle à voix haute et reçois une correction bienveillante, tout de suite.",
        "sections": [("De vraies conversations, pas des quiz", [
            "• Leçons vocales courtes sur des situations réelles : rencontres, café, aéroport, travail",
            "• Chaque nouvelle phrase arrive sur une carte avec traduction et audio",
            "• Conversation libre sur n'importe quel sujet, révisions intelligentes",
            "• Ton carnet d'oral : chaque conversation devient une page, les mots surlignés rejoignent tes révisions",
            "• Les débutants ont des explications en français",
        ])],
        "faq": [
            ("WordRem AI est-il gratuit ?", "Le téléchargement et ta première conversation sont gratuits. WordRem AI Pro débloque tout le programme et un temps de conversation mensuel généreux."),
            ("Quelles langues puis-je apprendre ?", "Anglais, espagnol, allemand, français, italien, russe, chinois et turc."),
        ],
        "links": ["/", "/tr/"],
    },
    {
        "path": "/es/", "lang": "es", "group": "home", "shots": "en",
        "title": "WordRem AI: hablar inglés con tutor de IA",
        "desc": "Aprende a hablar inglés y 7 idiomas más con un tutor de IA por voz: te escucha, responde y corrige tu pronunciación. Gratis en el App Store.",
        "h1": "Habla inglés con IA desde el primer día",
        "lead": "WordRem AI es un tutor de idiomas con IA que de verdad conversa contigo. Mantén el botón, habla en voz alta y recibe correcciones amables al instante.",
        "sections": [("Conversaciones reales, no tests", [
            "• Lecciones de voz cortas sobre momentos reales: conocer gente, cafetería, aeropuerto, trabajo",
            "• Cada frase nueva aparece en una tarjeta con traducción y audio",
            "• Charla libre sobre cualquier tema y repasos inteligentes",
            "• Tu cuaderno: cada conversación se convierte en una página y las palabras marcadas pasan a tus repasos",
            "• Los principiantes reciben explicaciones en español",
        ])],
        "faq": [
            ("¿WordRem AI es gratis?", "La descarga y tu primera conversación son gratis. WordRem AI Pro desbloquea el plan completo y un tiempo de conversación mensual generoso."),
            ("¿Qué idiomas puedo aprender?", "Inglés, español, alemán, francés, italiano, ruso, chino y turco."),
        ],
        "links": ["/", "/tr/"],
    },
    {
        "path": "/it/", "lang": "it", "group": "home", "shots": "en",
        "title": "WordRem AI: parlare inglese con tutor IA",
        "desc": "Impara a parlare inglese e altre 7 lingue con un tutor IA vocale: ti ascolta, risponde e corregge la pronuncia. Gratis su App Store.",
        "h1": "Parla inglese con l'IA dal primo giorno",
        "lead": "WordRem AI è un tutor di lingue IA vocale che parla davvero con te. Tieni premuto, parla ad alta voce e ricevi subito correzioni gentili.",
        "sections": [("Conversazioni vere, non quiz", [
            "• Brevi lezioni vocali su momenti reali: conoscere persone, bar, aeroporto, lavoro",
            "• Ogni nuova frase arriva su una scheda con traduzione e audio",
            "• Conversazione libera su qualsiasi argomento e ripassi intelligenti",
            "• Il tuo quaderno: ogni conversazione diventa una pagina, le parole evidenziate entrano nei ripassi",
            "• I principianti ricevono spiegazioni in italiano",
        ])],
        "faq": [
            ("WordRem AI è gratis?", "Il download e la prima conversazione sono gratis. WordRem AI Pro sblocca l'intero piano e un generoso tempo di conversazione mensile."),
            ("Quali lingue posso imparare?", "Inglese, spagnolo, tedesco, francese, italiano, russo, cinese e turco."),
        ],
        "links": ["/", "/tr/"],
    },
    {
        "path": "/ru/", "lang": "ru", "group": "home", "shots": "en",
        "title": "WordRem AI: разговорный английский с ИИ",
        "desc": "Учите разговорный английский и ещё 7 языков с голосовым ИИ-репетитором: он слушает, отвечает и исправляет произношение. Бесплатно в App Store.",
        "h1": "Разговорный английский с ИИ с первого дня",
        "lead": "WordRem AI — голосовой ИИ-репетитор, который действительно разговаривает с вами. Удерживайте кнопку, говорите вслух и сразу получайте мягкие исправления.",
        "sections": [("Живые разговоры вместо тестов", [
            "• Короткие голосовые уроки на реальные ситуации: знакомство, кафе, аэропорт, работа",
            "• Каждая новая фраза — на карточке с переводом и озвучкой",
            "• Свободный разговор на любую тему и умные повторения",
            "• Ваша тетрадь: каждый разговор становится страницей, отмеченные слова попадают в повторение",
            "• Новичкам репетитор объясняет по-русски",
        ])],
        "faq": [
            ("WordRem AI бесплатный?", "Скачивание и первый разговор бесплатны. WordRem AI Pro открывает весь план и щедрый ежемесячный лимит времени для разговоров."),
            ("Какие языки можно учить?", "Английский, испанский, немецкий, французский, итальянский, русский, китайский и турецкий."),
        ],
        "links": ["/", "/tr/"],
    },
]


# Uygulama yayına girmeden önceki "yakında" metinleri (LIVE = False)
SOON = {
    "tr": {"cta": "Çok yakında App Store'da", "cta_sub": "iPhone ve iPad için ücretsiz olacak",
           "qr": "Kodu kaydet: uygulama çıkınca seni direkt App Store'a götürür",
           "page": "WordRem AI çok yakında App Store'da. Bu bağlantı, uygulama çıktığı gün seni direkt indirme sayfasına götürecek.",
           "home": "Siteye göz at"},
    "en": {"cta": "Coming soon to the App Store", "cta_sub": "Free for iPhone and iPad",
           "qr": "Save this code: at launch it opens the App Store",
           "page": "WordRem AI is coming soon to the App Store. On launch day this link will take you straight to the download page.",
           "home": "Visit the website"},
    "de": {"cta": "Bald im App Store", "cta_sub": "Kostenlos für iPhone und iPad",
           "qr": "Code merken: zum Start öffnet er direkt den App Store",
           "page": "WordRem AI kommt bald in den App Store. Zum Start führt dich dieser Link direkt zum Download.",
           "home": "Zur Website"},
    "fr": {"cta": "Bientôt sur l'App Store", "cta_sub": "Gratuit sur iPhone et iPad",
           "qr": "Garde ce code : au lancement, il ouvre l'App Store",
           "page": "WordRem AI arrive bientôt sur l'App Store. Le jour du lancement, ce lien t'emmènera directement au téléchargement.",
           "home": "Voir le site"},
    "es": {"cta": "Muy pronto en el App Store", "cta_sub": "Gratis para iPhone y iPad",
           "qr": "Guarda este código: en el lanzamiento abrirá el App Store",
           "page": "WordRem AI llega muy pronto al App Store. El día del lanzamiento, este enlace te llevará directo a la descarga.",
           "home": "Ver la web"},
    "it": {"cta": "Presto su App Store", "cta_sub": "Gratis per iPhone e iPad",
           "qr": "Salva questo codice: al lancio apre App Store",
           "page": "WordRem AI arriva presto su App Store. Il giorno del lancio questo link ti porterà direttamente al download.",
           "home": "Vai al sito"},
    "ru": {"cta": "Скоро в App Store", "cta_sub": "Бесплатно для iPhone и iPad",
           "qr": "Сохраните код: после запуска он откроет App Store",
           "page": "WordRem AI скоро появится в App Store. В день запуска эта ссылка сразу откроет страницу загрузки.",
           "home": "Перейти на сайт"},
}
