//
//  OnboardingLocalization.swift
//  WordRemSwiftUI
//
//  Telefon diline göre onboarding metinlerini döndürür.
//  Desteklenen diller: tr, en, de, fr, es, it, ru, zh
//

import Foundation

struct OL {

    // MARK: - Telefon Dili (UI metinleri için)
    static var phoneCode: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return supported.contains(code) ? code : "en"
    }

    private static let supported = ["tr","en","de","fr","es","it","ru","zh"]

    // MARK: - Kullanıcının Seçtiği Anadil (öğrenme içeriği için)
    /// Onboarding'de seçilen anadil kodu. Bulunamazsa telefon diline döner.
    static var nativeLangCode: String {
        UserDefaults.standard.string(forKey: "userNativeLangCode") ?? phoneCode
    }

    // MARK: - String Çekme
    static func s(_ key: Key) -> String {
        translations[phoneCode]?[key] ?? translations["en"]?[key] ?? key.rawValue
    }

    static func f(_ key: Key, _ arg: String) -> String {
        String(format: s(key), arg)
    }

    // MARK: - "For X speakers" subtitle — seçilen anadile göre
    /// Kullanıcının seçtiği anadili kendi dilinde yazar: "Türkçe bilenler için" vs.
    static func forSpeakersSubtitle(nativeLangCode: String) -> String {
        let langName = Locale.current.localizedString(forLanguageCode: nativeLangCode)
                       ?? Locale(identifier: "en").localizedString(forLanguageCode: nativeLangCode)
                       ?? nativeLangCode.uppercased()
        return f(.forSpeakersFormat, langName)
    }

    /// Geriye dönük uyumluluk (telefon diline göre)
    static var forSpeakersSubtitle: String {
        forSpeakersSubtitle(nativeLangCode: phoneCode)
    }

    // MARK: - Dil İsimlerini Telefon Diline Göre Döndür
    /// "İngilizce" yerine telefon İngilizce'yse "English" döner
    static func languageName(for isoCode: String) -> String {
        Locale.current.localizedString(forLanguageCode: isoCode) ?? isoCode
    }

    // MARK: - Quiz Kelime Bankası — telefon diline göre
    static var quizCorrectWords: [String] {
        switch phoneCode {
        case "tr": return ["Dil", "öğrenmeyi", "seviyorum"]
        case "en": return ["I", "love", "learning", "languages"]
        case "de": return ["Ich", "liebe", "Sprachen", "lernen"]
        case "fr": return ["J'adore", "apprendre", "les", "langues"]
        case "es": return ["Me", "encanta", "aprender", "idiomas"]
        case "it": return ["Adoro", "imparare", "le", "lingue"]
        case "ru": return ["Я", "люблю", "изучать", "языки"]
        default:   return ["I", "love", "learning", "languages"]
        }
    }

    static var quizDecoyWords: [String] {
        switch phoneCode {
        case "tr": return ["olmak", "Nasılsın", "zaman", "Harika"]
        case "en": return ["she", "hates", "cooking", "music"]
        case "de": return ["bin", "nicht", "gut", "heute"]
        case "fr": return ["elle", "n'aime", "pas", "cuisine"]
        case "es": return ["ella", "no", "le", "gusta"]
        case "it": return ["lei", "non", "ama", "cucina"]
        case "ru": return ["она", "не", "любит", "готовить"]
        default:   return ["she", "hates", "cooking", "music"]
        }
    }

    // MARK: - Keys
    enum Key: String {
        // Shared
        case continueButton     = "continue_button"

        // NativeLanguageSelectionView
        case nativeLangTitle    = "native_lang.title"
        case nativeLangHint     = "native_lang.hint"

        // LanguageSelectionView
        case whatToLearn        = "lang_select.title"
        case forSpeakersFormat  = "lang_select.for_speakers_format"
        case nativeSpeakers     = "lang_select.native_speakers"

        // ProficiencyView
        case howMuchFormat      = "proficiency.question_format"
        case level1             = "proficiency.level_1"
        case level2             = "proficiency.level_2"
        case level3             = "proficiency.level_3"
        case level4             = "proficiency.level_4"
        case level5             = "proficiency.level_5"

        // BenefitsView
        case benefitsTitle      = "benefits.title"
        case benefit1Title      = "benefits.item1_title"
        case benefit1Desc       = "benefits.item1_desc"
        case benefit2Title      = "benefits.item2_title"
        case benefit2Desc       = "benefits.item2_desc"
        case benefit3Title      = "benefits.item3_title"
        case benefit3Desc       = "benefits.item3_desc"

        // OnboardingQuizView
        case quizInstruction    = "quiz.instruction"
        case quizCheck          = "quiz.check"
        case quizCorrect        = "quiz.correct"
        case quizWrong          = "quiz.wrong"
        case quizCorrectAnswer  = "quiz.correct_answer"

        // PlanSelectionView
        case planSpeechBubble   = "plan.speech_bubble"
        case planProSubtitle    = "plan.pro_subtitle"
        case planFreeTitle      = "plan.free_title"
        case planFreeSubtitle   = "plan.free_subtitle"
        case planRecommended    = "plan.recommended"

        // OnboardingLoadingView
        case loadingText        = "loading.text"
        case loadingMessage     = "loading.message"
    }

    // MARK: - Çeviriler
    // swiftlint:disable line_length
    private static let translations: [String: [Key: String]] = [

        // ─────────────────────────────────────────
        "tr": [
            .continueButton:    "DEVAM ET",
            .nativeLangTitle:   "Ana dilin hangisi?",
            .nativeLangHint:    "Bunu bilerek sana en uygun dersleri hazırlıyoruz.",
            .whatToLearn:       "Ne öğrenmek istersin?",
            .forSpeakersFormat: "%@ bilenler için",
            .nativeSpeakers:    "Türkçe bilenler için",
            .howMuchFormat:     "Ne kadar %@ biliyorsun?",
            .level1:            "Yeni başlıyorum",
            .level2:            "Bazı yaygın kelimeleri biliyorum",
            .level3:            "Basit konuşmalar yapabilirim",
            .level4:            "Çeşitli konular hakkında konuşabilirim",
            .level5:            "Çoğu konuyu ayrıntılı tartışabilirim",
            .benefitsTitle:     "İşte 3 ayda elde\nedebileceklerin!",
            .benefit1Title:     "Korkusuzca konuş",
            .benefit1Desc:      "Stressiz konuşma ve dinleme egzersizleri",
            .benefit2Title:     "Kelime hazneni geliştirme",
            .benefit2Desc:      "Yaygın kelimeler ve kullanışlı ifadeler",
            .benefit3Title:     "Öğrenim alışkanlığı edin",
            .benefit3Desc:      "Akıllı bildirimler, eğlenceli mücadeleler ve daha fazlası",
            .quizInstruction:   "Aşağıdaki cümleyi çevir:",
            .quizCheck:         "KONTROL ET",
            .quizCorrect:       "Harika!",
            .quizWrong:         "Yanlış Cevap",
            .quizCorrectAnswer: "Doğrusu: %@",
            .planSpeechBubble:  "Harika! İstediğin zaman\nplanını yükseltebilirsin.",
            .planProSubtitle:   "Daha hızlı ilerleme, reklamsız deneyim",
            .planFreeTitle:     "Ücretsiz Öğrenim",
            .planFreeSubtitle:  "Reklamlarla birlikte ana öğrenim özellikleri",
            .planRecommended:   "TAVSİYE EDİLEN",
            .loadingText:       "YÜKLENİYOR...",
            .loadingMessage:    "İnsanlar WordRem'de, aynı süre boyunca bir sınıfta ders alan öğrencilerden daha fazla şey öğreniyor. Hem de evden çıkmalarına gerek kalmadan!",
        ],

        // ─────────────────────────────────────────
        "en": [
            .continueButton:    "CONTINUE",
            .nativeLangTitle:   "What is your native language?",
            .nativeLangHint:    "We'll personalize your lessons based on this.",
            .whatToLearn:       "What do you want to learn?",
            .forSpeakersFormat: "For %@ speakers",
            .nativeSpeakers:    "For English speakers",
            .howMuchFormat:     "How much %@ do you know?",
            .level1:            "I'm just starting out",
            .level2:            "I know some common words",
            .level3:            "I can have simple conversations",
            .level4:            "I can talk about various topics",
            .level5:            "I can discuss most topics in detail",
            .benefitsTitle:     "Here's what you can achieve\nin 3 months!",
            .benefit1Title:     "Speak fearlessly",
            .benefit1Desc:      "Stress-free speaking and listening exercises",
            .benefit2Title:     "Build your vocabulary",
            .benefit2Desc:      "Common words and useful phrases",
            .benefit3Title:     "Build a learning habit",
            .benefit3Desc:      "Smart reminders, fun challenges and more",
            .quizInstruction:   "Translate the sentence below:",
            .quizCheck:         "CHECK",
            .quizCorrect:       "Great!",
            .quizWrong:         "Wrong Answer",
            .quizCorrectAnswer: "Correct: %@",
            .planSpeechBubble:  "Great! You can upgrade\nyour plan anytime.",
            .planProSubtitle:   "Faster progress, ad-free experience",
            .planFreeTitle:     "Free Learning",
            .planFreeSubtitle:  "Core learning features with ads",
            .planRecommended:   "RECOMMENDED",
            .loadingText:       "LOADING...",
            .loadingMessage:    "People learn more on WordRem than students who spend the same time in a classroom — without even leaving home!",
        ],

        // ─────────────────────────────────────────
        "de": [
            .continueButton:    "WEITER",
            .nativeLangTitle:   "Was ist deine Muttersprache?",
            .nativeLangHint:    "So können wir deine Lektionen optimal anpassen.",
            .whatToLearn:       "Was möchtest du lernen?",
            .forSpeakersFormat: "Für %@-Sprecher",
            .nativeSpeakers:    "Für Deutschsprachige",
            .howMuchFormat:     "Wie gut kannst du %@?",
            .level1:            "Ich fange gerade erst an",
            .level2:            "Ich kenne einige häufige Wörter",
            .level3:            "Ich kann einfache Gespräche führen",
            .level4:            "Ich kann über verschiedene Themen sprechen",
            .level5:            "Ich kann die meisten Themen ausführlich besprechen",
            .benefitsTitle:     "Das kannst du in 3 Monaten\nerreichen!",
            .benefit1Title:     "Furchtlos sprechen",
            .benefit1Desc:      "Stressfreie Sprech- und Hörübungen",
            .benefit2Title:     "Wortschatz aufbauen",
            .benefit2Desc:      "Häufige Wörter und nützliche Phrasen",
            .benefit3Title:     "Lerngewohnheit aufbauen",
            .benefit3Desc:      "Intelligente Erinnerungen, lustige Herausforderungen und mehr",
            .quizInstruction:   "Übersetze den folgenden Satz:",
            .quizCheck:         "PRÜFEN",
            .quizCorrect:       "Toll!",
            .quizWrong:         "Falsche Antwort",
            .quizCorrectAnswer: "Richtig: %@",
            .planSpeechBubble:  "Super! Du kannst deinen Plan\njederzeit upgraden.",
            .planProSubtitle:   "Schnellerer Fortschritt, werbefreies Erlebnis",
            .planFreeTitle:     "Kostenlos lernen",
            .planFreeSubtitle:  "Kernfunktionen mit Werbung",
            .planRecommended:   "EMPFOHLEN",
            .loadingText:       "WIRD GELADEN...",
            .loadingMessage:    "Menschen lernen mit WordRem mehr als Schüler, die die gleiche Zeit im Unterricht verbringen – und das ohne das Haus zu verlassen!",
        ],

        // ─────────────────────────────────────────
        "fr": [
            .continueButton:    "CONTINUER",
            .nativeLangTitle:   "Quelle est ta langue maternelle ?",
            .nativeLangHint:    "Cela nous permet de personnaliser tes leçons.",
            .whatToLearn:       "Que veux-tu apprendre ?",
            .forSpeakersFormat: "Pour les locuteurs %@",
            .nativeSpeakers:    "Pour les francophones",
            .howMuchFormat:     "Quel est ton niveau en %@ ?",
            .level1:            "Je commence tout juste",
            .level2:            "Je connais quelques mots courants",
            .level3:            "Je peux avoir des conversations simples",
            .level4:            "Je peux parler de divers sujets",
            .level5:            "Je peux discuter de la plupart des sujets en détail",
            .benefitsTitle:     "Voici ce que tu peux\natteindre en 3 mois !",
            .benefit1Title:     "Parler sans peur",
            .benefit1Desc:      "Exercices de conversation et d'écoute sans stress",
            .benefit2Title:     "Enrichir son vocabulaire",
            .benefit2Desc:      "Mots courants et expressions utiles",
            .benefit3Title:     "Créer une habitude d'apprentissage",
            .benefit3Desc:      "Rappels intelligents, défis amusants et plus encore",
            .quizInstruction:   "Traduis la phrase ci-dessous :",
            .quizCheck:         "VÉRIFIER",
            .quizCorrect:       "Super !",
            .quizWrong:         "Mauvaise réponse",
            .quizCorrectAnswer: "Correct : %@",
            .planSpeechBubble:  "Super ! Tu peux mettre à niveau\nton plan à tout moment.",
            .planProSubtitle:   "Progression plus rapide, sans publicité",
            .planFreeTitle:     "Apprentissage gratuit",
            .planFreeSubtitle:  "Fonctionnalités de base avec publicités",
            .planRecommended:   "RECOMMANDÉ",
            .loadingText:       "CHARGEMENT...",
            .loadingMessage:    "Les gens apprennent plus avec WordRem que les élèves qui passent le même temps en classe — sans même quitter la maison !",
        ],

        // ─────────────────────────────────────────
        "es": [
            .continueButton:    "CONTINUAR",
            .nativeLangTitle:   "¿Cuál es tu idioma nativo?",
            .nativeLangHint:    "Así personalizamos tus lecciones.",
            .whatToLearn:       "¿Qué quieres aprender?",
            .forSpeakersFormat: "Para hablantes de %@",
            .nativeSpeakers:    "Para hispanohablantes",
            .howMuchFormat:     "¿Cuánto sabes de %@?",
            .level1:            "Estoy empezando",
            .level2:            "Conozco algunas palabras comunes",
            .level3:            "Puedo tener conversaciones simples",
            .level4:            "Puedo hablar sobre varios temas",
            .level5:            "Puedo discutir la mayoría de los temas en detalle",
            .benefitsTitle:     "¡Esto es lo que puedes\nlograr en 3 meses!",
            .benefit1Title:     "Habla sin miedo",
            .benefit1Desc:      "Ejercicios de conversación y escucha sin estrés",
            .benefit2Title:     "Amplía tu vocabulario",
            .benefit2Desc:      "Palabras comunes y frases útiles",
            .benefit3Title:     "Crea un hábito de aprendizaje",
            .benefit3Desc:      "Recordatorios inteligentes, desafíos divertidos y más",
            .quizInstruction:   "Traduce la siguiente frase:",
            .quizCheck:         "VERIFICAR",
            .quizCorrect:       "¡Genial!",
            .quizWrong:         "Respuesta incorrecta",
            .quizCorrectAnswer: "Correcto: %@",
            .planSpeechBubble:  "¡Genial! Puedes actualizar\ntu plan en cualquier momento.",
            .planProSubtitle:   "Progreso más rápido, sin anuncios",
            .planFreeTitle:     "Aprendizaje gratuito",
            .planFreeSubtitle:  "Funciones principales con anuncios",
            .planRecommended:   "RECOMENDADO",
            .loadingText:       "CARGANDO...",
            .loadingMessage:    "¡Las personas aprenden más con WordRem que los estudiantes que pasan el mismo tiempo en clase, y sin salir de casa!",
        ],

        // ─────────────────────────────────────────
        "it": [
            .continueButton:    "CONTINUA",
            .nativeLangTitle:   "Qual è la tua lingua madre?",
            .nativeLangHint:    "In questo modo personalizziamo le tue lezioni.",
            .whatToLearn:       "Cosa vuoi imparare?",
            .forSpeakersFormat: "Per i parlanti %@",
            .nativeSpeakers:    "Per gli italofoni",
            .howMuchFormat:     "Quanto conosci il %@?",
            .level1:            "Sto iniziando adesso",
            .level2:            "Conosco alcune parole comuni",
            .level3:            "Posso avere conversazioni semplici",
            .level4:            "Posso parlare di vari argomenti",
            .level5:            "Posso discutere la maggior parte degli argomenti in dettaglio",
            .benefitsTitle:     "Ecco cosa puoi ottenere\nin 3 mesi!",
            .benefit1Title:     "Parla senza paura",
            .benefit1Desc:      "Esercizi di conversazione e ascolto senza stress",
            .benefit2Title:     "Arricchisci il tuo vocabolario",
            .benefit2Desc:      "Parole comuni e frasi utili",
            .benefit3Title:     "Crea un'abitudine di apprendimento",
            .benefit3Desc:      "Promemoria intelligenti, sfide divertenti e altro",
            .quizInstruction:   "Traduci la frase seguente:",
            .quizCheck:         "VERIFICA",
            .quizCorrect:       "Ottimo!",
            .quizWrong:         "Risposta sbagliata",
            .quizCorrectAnswer: "Corretto: %@",
            .planSpeechBubble:  "Ottimo! Puoi aggiornare\nil tuo piano in qualsiasi momento.",
            .planProSubtitle:   "Progressi più veloci, senza pubblicità",
            .planFreeTitle:     "Apprendimento gratuito",
            .planFreeSubtitle:  "Funzionalità principali con pubblicità",
            .planRecommended:   "CONSIGLIATO",
            .loadingText:       "CARICAMENTO...",
            .loadingMessage:    "Le persone imparano di più con WordRem rispetto agli studenti che trascorrono lo stesso tempo in classe, senza neanche uscire di casa!",
        ],

        // ─────────────────────────────────────────
        "ru": [
            .continueButton:    "ПРОДОЛЖИТЬ",
            .nativeLangTitle:   "Какой у тебя родной язык?",
            .nativeLangHint:    "Это поможет нам персонализировать твои уроки.",
            .whatToLearn:       "Что ты хочешь выучить?",
            .forSpeakersFormat: "Для носителей %@",
            .nativeSpeakers:    "Для русскоязычных",
            .howMuchFormat:     "Насколько хорошо ты знаешь %@?",
            .level1:            "Я только начинаю",
            .level2:            "Я знаю несколько распространённых слов",
            .level3:            "Я могу вести простые разговоры",
            .level4:            "Я могу говорить на разные темы",
            .level5:            "Я могу подробно обсуждать большинство тем",
            .benefitsTitle:     "Вот чего ты можешь достичь\nза 3 месяца!",
            .benefit1Title:     "Говори без страха",
            .benefit1Desc:      "Упражнения на разговор и аудирование без стресса",
            .benefit2Title:     "Пополни словарный запас",
            .benefit2Desc:      "Общеупотребительные слова и полезные фразы",
            .benefit3Title:     "Выработай привычку учиться",
            .benefit3Desc:      "Умные напоминания, весёлые челленджи и многое другое",
            .quizInstruction:   "Переведи следующее предложение:",
            .quizCheck:         "ПРОВЕРИТЬ",
            .quizCorrect:       "Отлично!",
            .quizWrong:         "Неправильный ответ",
            .quizCorrectAnswer: "Правильно: %@",
            .planSpeechBubble:  "Отлично! Ты можешь обновить\nсвой план в любое время.",
            .planProSubtitle:   "Быстрее прогресс, без рекламы",
            .planFreeTitle:     "Бесплатное обучение",
            .planFreeSubtitle:  "Основные функции с рекламой",
            .planRecommended:   "РЕКОМЕНДУЕТСЯ",
            .loadingText:       "ЗАГРУЗКА...",
            .loadingMessage:    "Люди учатся с WordRem больше, чем студенты, проводящие столько же времени в классе — и даже не выходя из дома!",
        ],

        // ─────────────────────────────────────────
        "zh": [
            .continueButton:    "继续",
            .nativeLangTitle:   "你的母语是什么？",
            .nativeLangHint:    "这样我们可以为你量身定制课程。",
            .whatToLearn:       "你想学什么？",
            .forSpeakersFormat: "适合%@使用者",
            .nativeSpeakers:    "适合中文使用者",
            .howMuchFormat:     "你的%@水平如何？",
            .level1:            "我刚开始学",
            .level2:            "我知道一些常用词",
            .level3:            "我可以进行简单对话",
            .level4:            "我可以谈论各种话题",
            .level5:            "我可以详细讨论大多数话题",
            .benefitsTitle:     "这是你3个月内\n可以实现的目标！",
            .benefit1Title:     "无畏地开口说",
            .benefit1Desc:      "无压力的口语和听力练习",
            .benefit2Title:     "扩充词汇量",
            .benefit2Desc:      "常用词汇和实用短语",
            .benefit3Title:     "培养学习习惯",
            .benefit3Desc:      "智能提醒、有趣挑战等更多功能",
            .quizInstruction:   "翻译下面的句子：",
            .quizCheck:         "检查",
            .quizCorrect:       "太棒了！",
            .quizWrong:         "回答错误",
            .quizCorrectAnswer: "正确：%@",
            .planSpeechBubble:  "太棒了！你可以随时\n升级你的计划。",
            .planProSubtitle:   "进步更快，无广告体验",
            .planFreeTitle:     "免费学习",
            .planFreeSubtitle:  "含广告的核心学习功能",
            .planRecommended:   "推荐",
            .loadingText:       "加载中...",
            .loadingMessage:    "使用WordRem的人比在课堂上花同样时间的学生学得更多——甚至不需要出门！",
        ],
    ]
    // swiftlint:enable line_length
}
