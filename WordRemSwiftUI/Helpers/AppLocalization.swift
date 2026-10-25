//
//  AppLocalization.swift
//  WordRemSwiftUI
//
//  Telefon diline göre tüm uygulama metinlerini döndürür.
//  Desteklenen diller: tr, en, de, fr, es, it, ru, zh
//

import Foundation

struct AL {

    // MARK: - Kullanıcı Dili (UserDefaults'tan, cihaz diline bağımlılık yok)
    static var currentCode: String { OL.nativeLangCode }

    // MARK: - String Çekme (code tabanlı — LanguageManager tarafından çağrılır)
    static func s(_ key: Key, for code: String) -> String {
        translations[code]?[key] ?? translations["en"]?[key] ?? key.rawValue
    }

    /// Geriye dönük uyumluluk — UserDefaults'taki dili kullanır.
    static func s(_ key: Key) -> String {
        s(key, for: currentCode)
    }

    static func f(_ key: Key, _ arg: String) -> String {
        String(format: s(key), arg)
    }

    static func f(_ key: Key, _ arg: Int) -> String {
        String(format: s(key), arg)
    }

    static func f(_ key: Key, _ arg1: Int, _ arg2: Int) -> String {
        String(format: s(key), arg1, arg2)
    }

    // MARK: - Paywall Reviews (code tabanlı)
    static func paywallReviews(for code: String) -> [(String, String)] {
        switch code {
        case "tr": return [
            ("3 ayda geçtiğimi düşündüğüm kelimeleri 3 haftada öğrendim!", "Mehmet K."),
            ("Reklamsız deneyim inanılmaz fark yaratıyor.", "Ayşe T."),
            ("İstatistikler motivasyonumu artırıyor, tavsiye ederim.", "Can Ö."),
            ("Her gün birkaç dakika ile B2'ye ulaştım.", "Selin A."),
            ("Pro olmadan düşünemiyorum artık.", "Burak Y."),
        ]
        case "de": return [
            ("In 3 Wochen habe ich mehr gelernt als in 3 Monaten!", "Felix M."),
            ("Das werbefreie Erlebnis macht einen riesigen Unterschied.", "Anna T."),
            ("Die Statistiken motivieren mich sehr.", "Jonas K."),
            ("Täglich ein paar Minuten und schon B2!", "Lisa S."),
            ("Ohne Pro kann ich mir das nicht mehr vorstellen.", "Ben W."),
        ]
        case "fr": return [
            ("J'ai appris en 3 semaines ce que je pensais apprendre en 3 mois !", "Pierre D."),
            ("L'expérience sans pub est vraiment incroyable.", "Sophie L."),
            ("Les statistiques me motivent énormément.", "Lucas M."),
            ("Quelques minutes par jour et j'ai atteint le B2 !", "Emma B."),
            ("Je ne peux plus me passer de Pro.", "Hugo R."),
        ]
        case "es": return [
            ("¡Aprendí en 3 semanas lo que creí que me llevaría 3 meses!", "Carlos R."),
            ("La experiencia sin anuncios marca una diferencia increíble.", "María T."),
            ("Las estadísticas me motivan mucho, lo recomiendo.", "Pablo G."),
            ("Pocos minutos al día y llegué a B2.", "Lucía A."),
            ("Ya no puedo imaginar aprender sin Pro.", "Diego M."),
        ]
        case "it": return [
            ("Ho imparato in 3 settimane ciò che pensavo richiedesse 3 mesi!", "Marco R."),
            ("L'esperienza senza pubblicità fa una differenza enorme.", "Giulia T."),
            ("Le statistiche mi motivano tantissimo.", "Luca B."),
            ("Pochi minuti al giorno e ho raggiunto il B2!", "Sara M."),
            ("Non riesco più a immaginare lo studio senza Pro.", "Andrea V."),
        ]
        case "ru": return [
            ("За 3 недели я выучил то, что думал учить 3 месяца!", "Алексей К."),
            ("Опыт без рекламы имеет невероятное значение.", "Мария Т."),
            ("Статистика очень мотивирует, рекомендую.", "Иван О."),
            ("Несколько минут в день — и я достиг B2!", "Наташа А."),
            ("Теперь я не представляю учёбу без Pro.", "Дмитрий В."),
        ]
        case "zh": return [
            ("3周内学到了我以为需要3个月才能学会的内容！", "小明"),
            ("无广告体验带来了惊人的差异。", "小红"),
            ("数据统计极大地激励了我，推荐！", "小刚"),
            ("每天几分钟，达到了B2水平！", "小芳"),
            ("没有Pro版我已经无法想象学习了。", "大伟"),
        ]
        default: return [
            ("In 3 weeks I learned what I thought would take 3 months!", "Michael K."),
            ("The ad-free experience makes an incredible difference.", "Sarah T."),
            ("The statistics motivate me so much — highly recommend.", "Chris O."),
            ("A few minutes a day and I reached B2!", "Emily A."),
            ("I can't imagine learning without Pro now.", "Ryan Y."),
        ]
        }
    }

    /// Geriye dönük uyumluluk
    static var paywallReviews: [(String, String)] { paywallReviews(for: currentCode) }

    // MARK: - Keys
    enum Key: String {

        // WelcomeView
        case welcomeTagline         = "welcome.tagline"
        case welcomeStart           = "welcome.start"
        case welcomeHaveAccount     = "welcome.have_account"

        // Paywall
        case paywallSubtitle        = "paywall.subtitle"
        case paywallFeature1        = "paywall.feature_1"
        case paywallFeature2        = "paywall.feature_2"
        case paywallFeature3        = "paywall.feature_3"
        case paywallFeature4        = "paywall.feature_4"
        case paywallFeature1Sub     = "paywall.feature_1_sub"
        case paywallFeature2Sub     = "paywall.feature_2_sub"
        case paywallFeature3Sub     = "paywall.feature_3_sub"
        case paywallFeature4Sub     = "paywall.feature_4_sub"
        case paywallReviewsTitle    = "paywall.reviews_title"
        case paywallWeeklyPro       = "paywall.weekly_pro"
        case paywallPerWeek         = "paywall.per_week"
        case paywallRecommended     = "paywall.recommended"
        case paywallPriceFailed     = "paywall.price_failed"
        case paywallRetry           = "paywall.retry"
        case paywallContinue        = "paywall.continue"
        case paywallPurchaseFailed  = "paywall.purchase_failed_title"
        case paywallPurchaseError   = "paywall.purchase_failed_msg"
        case paywallOk              = "paywall.ok"
        case paywallPrivacy         = "paywall.privacy"
        case paywallTerms           = "paywall.terms"
        case paywallRestore         = "paywall.restore"
        case paywallDisclosure      = "paywall.disclosure"
        case paywallAnnual = "paywall.annual"
        case paywallWeeklyPlan = "paywall.weekly_plan"
        case paywallBestValue = "paywall.best_value"
        case paywallSave = "paywall.save"
        case paywallPerYear = "paywall.per_year"
        case paywallWeeklyEquiv = "paywall.weekly_equiv"
        case paywallTrialBadge = "paywall.trial_badge"
        case paywallStartTrial = "paywall.start_trial"
        case paywallTrialThen = "paywall.trial_then"
        case paywallNoCommit = "paywall.no_commit"
        case paywallTLToday = "paywall.tl_today"
        case paywallTLTodaySub = "paywall.tl_today_sub"
        case paywallTLDay = "paywall.tl_day"
        case paywallTLReminderSub = "paywall.tl_reminder_sub"
        case paywallTLChargeSub = "paywall.tl_charge_sub"
        case paywallTrialReminderTitle = "paywall.trial_reminder_title"
        case paywallTrialReminderBody = "paywall.trial_reminder_body"
        case gcJoinTitle = "gc.join_title"
        case gcJoinDesc = "gc.join_desc"
        case gcOpenSettings = "gc.open_settings"
        case profileResetProgress = "profile.reset_progress"
        case profileResetTitle = "profile.reset_title"
        case profileResetMessage = "profile.reset_message"
        case profileResetConfirm = "profile.reset_confirm"
        case profileSyncNote = "profile.sync_note"
        case deckNoWords = "deck.no_words"
        case deckTapToAdd = "deck.tap_to_add"
        case deckWordCount = "deck.word_count"
        case deckOneWord = "deck.one_word"
        case deckQuiz = "deck.quiz"
        case deckCreateTitle = "deck.create_title"
        case deckCreateSubtitle = "deck.create_subtitle"
        case deckChooseFlag = "deck.choose_flag"
        case deckLanguages = "deck.languages"
        case deckSource = "deck.source"
        case deckTarget = "deck.target"
        case deckName = "deck.name"
        case deckNamePlaceholder = "deck.name_placeholder"
        case deckCreate = "deck.create"
        case cardCreateTitle = "card.create_title"
        case cardEditTitle = "card.edit_title"
        case cardWordLabel = "card.word_label"
        case cardTranslating = "card.translating"
        case cardTranslate = "card.translate"
        case cardMeaningLabel = "card.meaning_label"
        case cardGenerating = "card.generating"
        case cardGenerateSentence = "card.generate_sentence"
        case cardExampleSentence = "card.example_sentence"
        case cardReminder = "card.reminder"
        case cardReminderDate = "card.reminder_date"
        case cardRepeat = "card.repeat"
        case cardRepeatNone = "card.repeat_none"
        case cardRepeatWeekly = "card.repeat_weekly"
        case cardRepeatMonthly = "card.repeat_monthly"
        case cardEveryWeeks = "card.every_weeks"
        case cardEveryMonths = "card.every_months"
        case cardSave = "card.save"
        case cardAddWord = "card.add_word"
        case cardCancel = "card.cancel"
        case cardError = "card.error"
        case cardDone = "card.done"
        case aiQuizTitle = "aiq.title"
        case aiQuizSubtitle = "aiq.subtitle"
        case aiQuizHowMany = "aiq.how_many"
        case aiQuizGenerate = "aiq.generate"
        case aiQuizPreparing = "aiq.preparing"
        case aiQuizAbout = "aiq.about"
        case aiQuizError = "aiq.error"
        case aiQuizTryAgain = "aiq.try_again"
        case aiQuizTopicsCount = "aiq.topics_count"
        case aiQuizQuestionsUnit = "aiq.questions_unit"
        case commonSkip = "common.skip"
        case commonClose = "common.close"
        case pathAIGrammarQuiz = "path.ai_grammar_quiz"
        case profTotalQuestions = "prof.total_questions"
        case profCompleted = "prof.completed"
        case profStreak = "prof.streak"
        case profLevelN = "prof.level_n"
        case profNextLevel = "prof.next_level"
        case profTotalXP = "prof.total_xp"
        case profLevels = "prof.levels"
        case quizAnalyzing = "quiz.analyzing"
        case loginTitle = "login.title"
        case loginSubtitle = "login.subtitle"
        case loginEmail = "login.email"
        case loginPassword = "login.password"
        case loginWithApple = "login.with_apple"
        case loginWithGoogle = "login.with_google"
        case loginOr = "login.or"
        case todayTitle = "today.title"
        case todayDueCount = "today.due_count"
        case todayDueMinutes = "today.due_minutes"
        case todayStartReview = "today.start_review"
        case todayAllDone = "today.all_done"
        case todayAllDoneBody = "today.all_done_body"
        case todayNoWords = "today.no_words"
        case todayNoWordsBody = "today.no_words_body"
        case todayLearnNew = "today.learn_new"
        case todayStreak = "today.streak"
        case todayKnown = "today.known"
        case todayThisWeek = "today.this_week"
        case todayWordOfDay = "today.word_of_day"
        case todayMistakes = "today.mistakes"
        case reviewShow = "review.show"
        case reviewAgain = "review.again"
        case reviewHard = "review.hard"
        case reviewGood = "review.good"
        case reviewEasy = "review.easy"
        case reviewMinutes = "review.minutes"
        case reviewDays = "review.days"
        case reviewDoneTitle = "review.done_title"
        case reviewDoneBody = "review.done_body"
        case reviewClose = "review.close"
        case wordsTitle = "words.title"
        case wordsLearned = "words.learned"
        case wordsDecks = "words.decks"
        case wordsSearch = "words.search"
        case wordsEmpty = "words.empty"
        case wordsDue = "words.due"
        case wordsDueIn = "words.due_in"
        case wordsMastered = "words.mastered"
        case tabToday = "tab.today"
        case tabWords = "tab.words"
        case tabPractice = "tab.practice"
        case registerCheckEmailTitle = "register.check_email_title"
        case registerCheckEmail = "register.check_email"
        case hcAccuracy = "hc.accuracy"
        case hcDailyStreak = "hc.daily_streak"
        case hcBestStreak = "hc.best_streak"
        case hcProgress = "hc.progress"
        case hcRecommended = "hc.recommended"
        case hcPerfectForBeginners = "hc.perfect_beginners"
        case hcNext = "hc.next"
        case hcLetsStart = "hc.lets_start"
        case hcAIPage1Title = "hc.ai_p1_title"
        case hcAIPage1Desc = "hc.ai_p1_desc"
        case hcAIPage2Title = "hc.ai_p2_title"
        case hcAIPage2Desc = "hc.ai_p2_desc"
        case hcAIPage3Title = "hc.ai_p3_title"
        case hcAIPage3Desc = "hc.ai_p3_desc"
        case hcAIPage4Title = "hc.ai_p4_title"
        case hcAIPage4Desc = "hc.ai_p4_desc"
        case hcMuteTitle = "hc.mute_title"
        case hcMuteConfirm = "hc.mute_confirm"
        case hcCancel = "hc.cancel"
        case hcMuteMessage = "hc.mute_message"
        case hcNewWord = "hc.new_word"
        case hcTranslateSentence = "hc.translate_sentence"
        case hcPreparingLesson = "hc.preparing_lesson"
        case hcTapToInterrupt = "hc.tap_interrupt"
        case hcHoldToSpeak = "hc.hold_speak"
        case hcListening = "hc.listening"
        case hcStartQuiz = "hc.start_quiz"
        case hcLessonLoadFailed = "hc.lesson_load_failed"
        case hcDidntHear = "hc.didnt_hear"
        case hcChatHistory = "hc.chat_history"
        case hcAIServiceError = "hc.ai_service_error"
        case hcAIRateLimited = "hc.ai_rate_limited"
        case hcAIEmptyResponse = "hc.ai_empty"
        case loginFailedTitle = "login.failed_title"
        case loginButton = "login.button"
        case loginForgotPassword = "login.forgot_password"
        case loginSignUp = "login.sign_up"
        case loginResetEmailMissing = "login.reset_email_missing"
        case loginResetEmailSent = "login.reset_email_sent"
        case loginResetTitle = "login.reset_title"
        case paywallRestoreNothing = "paywall.restore_nothing"
        case paywallRestoreTitle = "paywall.restore_title"
        case paywallWeeklyTerm = "paywall.weekly_term"
        case profileDeleteFailed = "profile.delete_failed"
        case profileDeleting = "profile.deleting"
        case usernameSkip = "username.skip"
        case aiConsentTitle = "ai.consent_title"
        case aiConsentMessage = "ai.consent_message"
        case aiConsentAllow = "ai.consent_allow"
        case aiConsentDeny = "ai.consent_deny"
        case loadFailedMessage = "common.load_failed"

        // HomeScreenView
        case homeSearchPlaceholder  = "home.search_placeholder"
        case homeMyDecks            = "home.my_decks"
        case homeTapToStudy         = "home.tap_to_study"
        case homeNoResultsFormat    = "home.no_results_format"
        case homeNoDecks            = "home.no_decks"
        case homeNoDecksHint        = "home.no_decks_hint"

        // ProfileView
        case profileTotalXP         = "profile.total_xp"
        case profileStreak          = "profile.streak"
        case profileDaysFormat      = "profile.days_format"
        case profileStatistics      = "profile.statistics"
        case profileCompleted       = "profile.completed"
        case profileQuizzes         = "profile.quizzes"
        case profileAccuracy        = "profile.accuracy"
        case profileLevel           = "profile.level"
        case profileLevelFormat     = "profile.level_format"
        case profileAchievements    = "profile.achievements"
        case profileFirstStreak     = "profile.first_streak"
        case profile5Levels         = "profile.5_levels"
        case profile100XP           = "profile.100_xp"
        case profileSharpEye        = "profile.sharp_eye"
        case profile500XP           = "profile.500_xp"
        case profileUpgradePro      = "profile.upgrade_pro"
        case profileSignOut         = "profile.sign_out"
        case profileGuest           = "profile.guest"
        case profileDeleteAccount   = "profile.delete_account"
        case profileDeleteTitle     = "profile.delete_title"
        case profileDeleteMessage   = "profile.delete_message"
        case profileDeleteConfirm   = "profile.delete_confirm"
        case profileDeleteCancel    = "profile.delete_cancel"

        // LeaderboardView
        case leaderboardTitle       = "leaderboard.title"
        case leaderboardSubtitle    = "leaderboard.subtitle"
        case leaderboardNoPlayers   = "leaderboard.no_players"
        case leaderboardNoPlayersHint = "leaderboard.no_players_hint"
        case leaderboardTryAgain    = "leaderboard.try_again"
        case leaderboardDayStreak   = "leaderboard.day_streak"

        // Tab labels
        case tabDecks               = "tab.decks"
        case tabPath                = "tab.path"
        case tabTranslate           = "tab.translate"
        case tabRank                = "tab.rank"
        case tabProfile             = "tab.profile"

        // PathMapView
        case pathMistakesFormat     = "path.mistakes_format"
        case pathMistakesUrgent     = "path.mistakes_urgent"
        case pathUpdating           = "path.updating"
        case pathSomethingWrong     = "path.something_wrong"
        case pathTryAgain           = "path.try_again"
        case pathRefresh            = "path.refresh"
        case pathNoCourses          = "path.no_courses"
        case pathNoCoursesHint      = "path.no_courses_hint"
        case pathNoCourseForLang    = "path.no_course_for_lang"
        case pathNoCourseForLangHint = "path.no_course_for_lang_hint"
        case pathSelectCourse       = "path.select_course"
        case pathStart              = "path.start"
        case pathMotivation0        = "path.motivation_0"
        case pathMotivation1        = "path.motivation_1"
        case pathMotivation2        = "path.motivation_2"
        case pathMotivation3        = "path.motivation_3"
        case pathWellDone           = "path.well_done"
        case pathWellDoneDesc       = "path.well_done_desc"
        case pathContinue           = "path.continue"
        case pathDontBeSad          = "path.dont_be_sad"
        case pathDontBeSadDesc      = "path.dont_be_sad_desc"
        case pathGotIt              = "path.got_it"
        case pathGreatWork          = "path.great_work"
        case pathGreatWorkDesc      = "path.great_work_desc"
        case pathHooray             = "path.hooray"
        case pathMistakesReview     = "path.mistakes_review"

        // GameQuizView
        case gameLoading            = "game.loading"
        case gameWhatIsMeaning      = "game.what_is_meaning"
        case gameTypeTranslation    = "game.type_translation"
        case gameCheck              = "game.check"
        case gameOutOfLives         = "game.out_of_lives"
        case gameDontGiveUp         = "game.dont_give_up"
        case gameTryAgain           = "game.try_again"
        case gameQuit               = "game.quit"
        case gameQuitTitle          = "game.quit_title"
        case gameQuitMessage        = "game.quit_message"
        case gameQuitKeepGoing      = "game.quit_keep_going"
        case gameQuestionFormat     = "game.question_format"
        case gameCorrect            = "game.correct"
        case gameNotQuite           = "game.not_quite"
        case gameContinue           = "game.continue"

        // Listening mode
        case gameListenPrompt       = "game.listen_prompt"
        case gameListenNormal       = "game.listen_normal"
        case gameListenSlow         = "game.listen_slow"
        case gameListenCantHear     = "game.listen_cant_hear"

        // Speaking mode
        case gameSpeakPrompt        = "game.speak_prompt"
        case gameSpeakMicHint       = "game.speak_mic_hint"
        case gameSpeakCantSpeak     = "game.speak_cant_speak"
        case gameSpeakListening     = "game.speak_listening"
        case gameSpeakNoPermission  = "game.speak_no_permission"

        // Daily Limit
        case dailyLimitTitle        = "daily.limit_title"
        case dailyLimitSubtitle     = "daily.limit_subtitle"
        case dailyLimitResetsIn     = "daily.resets_in"
        case dailyLimitGetPro       = "daily.get_pro"
        case dailyLimitClose        = "daily.close"

        // QuizResultView
        case resultLevelComplete    = "result.level_complete"
        case resultKeepPracticing   = "result.keep_practicing"
        case resultScore            = "result.score"
        case resultXPEarned         = "result.xp_earned"
        case resultContinue         = "result.continue"
        case resultTryAgain         = "result.try_again"

        // Profile - Guest & Username flow
        case profileSaveProgress        = "profile.save_progress"
        case profileSaveProgressHint    = "profile.save_progress_hint"
        case profileSaveProgressDesc    = "profile.save_progress_desc"
        case profileLoginApple          = "profile.login_apple"
        case profileLoginGoogle         = "profile.login_google"
        case profileLoginEmail          = "profile.login_email"
        case profileClose               = "profile.close"
        case profileSave                = "profile.save"
        case profileSetUsername         = "profile.set_username"
        case profileChangeUsername      = "profile.change_username"
        case profileUsernameLeaderboard = "profile.username_leaderboard"
        case profileUsernameOneChange   = "profile.username_one_change"
        case profileUsernamePlaceholder = "profile.username_placeholder"

        // Leaderboard - Guest
        case leaderboardJoinTitle       = "leaderboard.join_title"
        case leaderboardJoinDesc        = "leaderboard.join_desc"
        case leaderboardSignIn          = "leaderboard.sign_in"

        // Home - Empty state
        case homeCreateFirstDeck        = "home.create_first_deck"
        case homeCreateFirstDeckHint    = "home.create_first_deck_hint"
        case homeCreateDeck             = "home.create_deck"

        // Path - Unit & Status
        case pathUnitFormat             = "path.unit_format"
        case pathLevelProgressFormat    = "path.level_progress_format"
        case pathStatusCompleted        = "path.status_completed"
        case pathStatusInProgress       = "path.status_in_progress"
        case pathStatusLocked           = "path.status_locked"

        // Home - Loading
        case homeLoadingDecks           = "home.loading_decks"

        // Game - Hint popup
        case gameHintTitle              = "game.hint_title"
        case gameHintRemainingFormat    = "game.hint_remaining_format"
        case gameHintGotIt              = "game.hint_got_it"

        // Game - Quiz labels
        case gameFillBlank              = "game.fill_blank"
        case gameTranslateLabel         = "game.translate_label"
        case gameLoadingAudio           = "game.loading_audio"
        case gameWordQuestionFormat     = "game.word_question_format"

        // Achievement - Rarity labels
        case achievementRarityCommon    = "achievement.rarity.common"
        case achievementRarityRare      = "achievement.rarity.rare"
        case achievementRarityEpic      = "achievement.rarity.epic"
        case achievementRarityLegendary = "achievement.rarity.legendary"

        // Achievement - UI strings
        case achievementViewMore        = "achievement.view_more"
        case achievementAllTitle        = "achievement.all_title"
        case achievementUnlockedBadge   = "achievement.unlocked_badge"
        case achievementLockedBadge     = "achievement.locked_badge"
        case achievementNewUnlocked     = "achievement.new_unlocked"
        case achievementTapToDismiss    = "achievement.tap_to_dismiss"

        // Achievements - Common
        case achFirstStepsTitle         = "ach.first_steps.title"
        case achFirstStepsDesc          = "ach.first_steps.desc"
        case achFirstStreakTitle         = "ach.first_streak.title"
        case achFirstStreakDesc          = "ach.first_streak.desc"
        case ach100XPTitle              = "ach.100xp.title"
        case ach100XPDesc               = "ach.100xp.desc"
        case ach5LevelsTitle            = "ach.5levels.title"
        case ach5LevelsDesc             = "ach.5levels.desc"
        case ach50CorrectTitle          = "ach.50correct.title"
        case ach50CorrectDesc           = "ach.50correct.desc"
        // Achievements - Rare
        case ach500XPTitle              = "ach.500xp.title"
        case ach500XPDesc               = "ach.500xp.desc"
        case achSharpEyeTitle           = "ach.sharp_eye.title"
        case achSharpEyeDesc            = "ach.sharp_eye.desc"
        case ach10LevelsTitle           = "ach.10levels.title"
        case ach10LevelsDesc            = "ach.10levels.desc"
        case ach7StreakTitle            = "ach.7streak.title"
        case ach7StreakDesc             = "ach.7streak.desc"
        case ach1000XPTitle             = "ach.1000xp.title"
        case ach1000XPDesc              = "ach.1000xp.desc"
        case ach100CorrectTitle         = "ach.100correct.title"
        case ach100CorrectDesc          = "ach.100correct.desc"
        // Achievements - Epic
        case ach25LevelsTitle           = "ach.25levels.title"
        case ach25LevelsDesc            = "ach.25levels.desc"
        case ach30StreakTitle           = "ach.30streak.title"
        case ach30StreakDesc            = "ach.30streak.desc"
        case achPerfectionistTitle      = "ach.perfectionist.title"
        case achPerfectionistDesc       = "ach.perfectionist.desc"
        case ach5000XPTitle             = "ach.5000xp.title"
        case ach5000XPDesc              = "ach.5000xp.desc"
        case ach500CorrectTitle         = "ach.500correct.title"
        case ach500CorrectDesc          = "ach.500correct.desc"
        // Achievements - Legendary
        case ach50LevelsTitle           = "ach.50levels.title"
        case ach50LevelsDesc            = "ach.50levels.desc"
        case ach100StreakTitle          = "ach.100streak.title"
        case ach100StreakDesc           = "ach.100streak.desc"
        case ach10000XPTitle            = "ach.10000xp.title"
        case ach10000XPDesc             = "ach.10000xp.desc"
        case achWordGodTitle            = "ach.word_god.title"
        case achWordGodDesc             = "ach.word_god.desc"

        // Navigation titles
        case navSettings                = "nav.settings"
        case navExampleSentences        = "nav.example_sentences"

        // Welcome Popup — New User
        case welcomeNewTitle            = "welcome.new_title"
        case welcomeNewSubtitle         = "welcome.new_subtitle"
        case welcomeNewFeature1         = "welcome.new_feature1"
        case welcomeNewFeature2         = "welcome.new_feature2"
        case welcomeNewFeature3         = "welcome.new_feature3"
        case welcomeNewCTA              = "welcome.new_cta"

        // Welcome Popup — Returning User
        case welcomeBackTitle           = "welcome.back_title"
        case welcomeBackMessageFormat   = "welcome.back_message_format"
        case welcomeBackMotivation      = "welcome.back_motivation"
        case welcomeBackCTA             = "welcome.back_cta"

        // Welcome Popup — Pro Purchase
        case welcomeProTitle            = "welcome.pro_title"
        case welcomeProSubtitle         = "welcome.pro_subtitle"
        case welcomeProFeature1         = "welcome.pro_feature1"
        case welcomeProFeature2         = "welcome.pro_feature2"
        case welcomeProFeature3         = "welcome.pro_feature3"
        case welcomeProCTA              = "welcome.pro_cta"

        // Daily Goal Break Popup
        case dailyBreakTitle         = "daily_break.title"
        case dailyBreakBodyFormat    = "daily_break.body_format"
        case dailyBreakSubtitle      = "daily_break.subtitle"
        case dailyBreakRest          = "daily_break.rest"
        case dailyBreakContinue      = "daily_break.continue"

        // Streak Celebration Screen
        case streakStartedTitle         = "streak.started_title"
        case streakContinuedTitle       = "streak.continued_title"
        case streakSubtitle             = "streak.subtitle"
        case streakContinue             = "streak.continue"
    }

    // MARK: - Haftanın günleri kısaltmaları (Mon→Sun, ISO order)
    static var weekDayAbbreviations: [String] {
        switch LanguageManager.shared.currentLanguageCode {
        case "tr": return ["Pzt", "Sal", "Çrş", "Prş", "Cum", "Cts", "Paz"]
        case "de": return ["Mo",  "Di",  "Mi",  "Do",  "Fr",  "Sa",  "So"]
        case "fr": return ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
        case "es": return ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
        case "it": return ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"]
        case "ru": return ["Пн",  "Вт",  "Ср",  "Чт",  "Пт",  "Сб",  "Вс"]
        case "zh": return ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        default:   return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        }
    }

    // MARK: - Çeviriler
    // swiftlint:disable line_length
    private static let translations: [String: [Key: String]] = [

        // ─────────────────────────────────────────
        "tr": [
            // Welcome
            .welcomeTagline:        "Her gün birkaç kelime.\nKalıcı olarak.",
            .welcomeStart:          "Başla",
            .welcomeHaveAccount:    "Zaten hesabım var",
            // Paywall
            .paywallSubtitle:       "Öğrenmeyi bir üst seviyeye taşı",
            .paywallFeature1:       "Sınırsız günlük pratik",
            .paywallFeature2:       "Sınırsız ipucu",
            .paywallFeature3:       "Sınırsız AI quiz",
            .paywallFeature4:       "Sınırsız AI konuşma koçu",
            .paywallFeature1Sub:    "Günlük soru limiti olmadan çalış",
            .paywallFeature2Sub:    "Takıldığında ipucu hakkın hiç bitmesin",
            .paywallFeature3Sub:    "Dilediğin kadar AI quiz oluştur",
            .paywallFeature4Sub:    "Gramer ve telaffuzu AI ile sınırsız çalış",
            .paywallReviewsTitle:   "Kullanıcılar ne diyor?",
            .paywallWeeklyPro:      "Haftalık Pro",
            .paywallPerWeek:        "%@ / hafta",
            .paywallRecommended:    "TAVSİYE EDİLEN",
            .paywallPriceFailed:    "Fiyat yüklenemedi",
            .paywallRetry:          "Tekrar Dene",
            .paywallContinue:       "Devam Et",
            .paywallPurchaseFailed: "Satın alma başarısız",
            .paywallPurchaseError:  "Bir hata oluştu. Lütfen tekrar dene veya restore kullan.",
            .paywallOk:             "Tamam",
            .paywallPrivacy:        "Gizlilik",
            .paywallTerms:          "Kullanım Şartları (EULA)",
            .paywallRestore:        "Geri Yükle",
            .paywallDisclosure:     "Satın alma onaylandığında Apple Hesabınıza ücretlendirilir. Abonelik, mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir. Aboneliklerinizi App Store Hesap Ayarları'ndan yönetebilirsiniz.",
            .paywallAnnual: "Yıllık",
            .paywallWeeklyPlan: "Haftalık",
            .paywallBestValue: "En avantajlı",
            .paywallSave: "%%%d tasarruf",
            .paywallPerYear: "%@ / yıl",
            .paywallWeeklyEquiv: "Haftada yalnızca %@",
            .paywallTrialBadge: "%d gün ücretsiz",
            .paywallStartTrial: "%d gün ücretsiz dene",
            .paywallTrialThen: "%d gün ücretsiz, sonra %@ / yıl. İstediğin an iptal et.",
            .paywallNoCommit: "Taahhüt yok · İstediğin an iptal et",
            .paywallTLToday: "Bugün",
            .paywallTLTodaySub: "Tüm kurslar ve özellikler açılır",
            .paywallTLDay: "%d. gün",
            .paywallTLReminderSub: "Deneme bitmeden sana hatırlatırız",
            .paywallTLChargeSub: "Abonelik başlar, ücret alınır",
            .paywallTrialReminderTitle: "Deneme süren 2 gün sonra bitiyor",
            .paywallTrialReminderBody: "Devam etmek istemiyorsan Ayarlar › Abonelikler'den iptal edebilirsin.",
            .gcJoinTitle: "Sıralamanı gör",
            .gcJoinDesc: "Sıralama tablosu Game Center kullanır. Diğer öğrencilerle XP'ni karşılaştırmak için Ayarlar'dan Game Center'a giriş yap.",
            .gcOpenSettings: "Ayarlar'ı aç",
            .profileResetProgress: "İlerlemeyi sıfırla",
            .profileResetTitle: "Tüm ilerleme sıfırlansın mı?",
            .profileResetMessage: "XP'n, serin, öğrendiğin kelimeler ve destelerin bu cihazdan ve iCloud'dan silinecek. Bu işlem geri alınamaz. Aboneliğin etkilenmez.",
            .profileResetConfirm: "Sıfırla",
            .profileSyncNote: "İlerlemen iCloud hesabınla otomatik olarak senkronlanır.",
            .deckNoWords: "Henüz kelime yok",
            .deckTapToAdd: "İlk kelimeni eklemek için + simgesine dokun",
            .deckWordCount: "%d kelime",
            .deckOneWord: "1 kelime",
            .deckQuiz: "Quiz",
            .deckCreateTitle: "Yeni Deste Oluştur",
            .deckCreateSubtitle: "Bir bayrak seç ve destene akılda kalıcı bir isim ver.",
            .deckChooseFlag: "Bayrak seç",
            .deckLanguages: "Çeviri dilleri",
            .deckSource: "Kaynak",
            .deckTarget: "Hedef",
            .deckName: "Deste adı",
            .deckNamePlaceholder: "Örn. İspanyolca Temeller, Faydalı Fiiller",
            .deckCreate: "Deste oluştur",
            .cardCreateTitle: "Kelimeni Oluştur",
            .cardEditTitle: "Kelimeni Düzenle",
            .cardWordLabel: "Kelime (ana dilinde)",
            .cardTranslating: "Çevriliyor...",
            .cardTranslate: "Çevir",
            .cardMeaningLabel: "Çeviri (öğrendiğin dilde)",
            .cardGenerating: "Cümle oluşturuluyor...",
            .cardGenerateSentence: "Örnek cümle oluştur",
            .cardExampleSentence: "Örnek cümle",
            .cardReminder: "Hatırlatıcı",
            .cardReminderDate: "Hatırlatma tarihi ve saati",
            .cardRepeat: "Tekrarla",
            .cardRepeatNone: "Yok",
            .cardRepeatWeekly: "Haftalık",
            .cardRepeatMonthly: "Aylık",
            .cardEveryWeeks: "%d haftada bir",
            .cardEveryMonths: "%d ayda bir",
            .cardSave: "Kaydet",
            .cardAddWord: "Kelime ekle",
            .cardCancel: "İptal",
            .cardError: "Hata",
            .cardDone: "Bitti",
            .aiQuizTitle: "AI Quiz",
            .aiQuizSubtitle: "Gramer ve kelime pratiği",
            .aiQuizHowMany: "Kaç soru olsun?",
            .aiQuizGenerate: "Quiz oluştur",
            .aiQuizPreparing: "Quiz hazırlanıyor...",
            .aiQuizAbout: "%d soru:",
            .aiQuizError: "Bir şeyler ters gitti",
            .aiQuizTryAgain: "Tekrar dene",
            .aiQuizTopicsCount: "%d konu",
            .aiQuizQuestionsUnit: "soru",
            .commonSkip: "Atla",
            .commonClose: "Kapat",
            .pathAIGrammarQuiz: "AI gramer quizi",
            .profTotalQuestions: "Toplam soru",
            .profCompleted: "Tamamlanan",
            .profStreak: "Seri",
            .profLevelN: "Seviye %d",
            .profNextLevel: "Sonraki seviye",
            .profTotalXP: "Toplam XP",
            .profLevels: "Seviye",
            .quizAnalyzing: "Analiz ediliyor...",
            .loginTitle: "Tekrar hoş geldin",
            .loginSubtitle: "Kelimelerine kaldığın yerden devam et.",
            .loginEmail: "E-posta",
            .loginPassword: "Şifre",
            .loginWithApple: "Apple ile devam et",
            .loginWithGoogle: "Google ile devam et",
            .loginOr: "veya",
            .todayTitle: "Bugün",
            .todayDueCount: "kelime tekrar bekliyor",
            .todayDueMinutes: "Yaklaşık %d dk",
            .todayStartReview: "Tekrara başla",
            .todayAllDone: "Bugünlük tamam",
            .todayAllDoneBody: "Güzel iş. Birkaç yeni kelime öğren ya da yarın tekrar gel.",
            .todayNoWords: "İlk kelimelerin seni bekliyor",
            .todayNoWordsBody: "Pratik sekmesinde bir ders bitir. Doğru bildiğin kelimeler, tam unutmak üzereyken burada karşına çıkar.",
            .todayLearnNew: "Yeni kelime öğren",
            .todayStreak: "Günlük seri",
            .todayKnown: "Kelime",
            .todayThisWeek: "Bu hafta",
            .todayWordOfDay: "Günün kelimesi",
            .todayMistakes: "Düzeltilecek kelimeler",
            .reviewShow: "Cevabı göster",
            .reviewAgain: "Tekrar",
            .reviewHard: "Zor",
            .reviewGood: "İyi",
            .reviewEasy: "Kolay",
            .reviewMinutes: "10 dk",
            .reviewDays: "%d gün",
            .reviewDoneTitle: "Bugünlük bitti",
            .reviewDoneBody: "%d kelimeyi tekrar ettin. Yarın görüşürüz.",
            .reviewClose: "Kapat",
            .wordsTitle: "Kelimelerim",
            .wordsLearned: "Öğrendiklerim",
            .wordsDecks: "Destelerim",
            .wordsSearch: "Kelime ara",
            .wordsEmpty: "Öğrendiğin kelimeler burada görünecek.",
            .wordsDue: "Sırada",
            .wordsDueIn: "%d gün sonra",
            .wordsMastered: "Kalıcı",
            .tabToday: "Bugün",
            .tabWords: "Kelimeler",
            .tabPractice: "Pratik",
            .registerCheckEmailTitle: "E-postanı Doğrula",
            .registerCheckEmail: "E-postana bir doğrulama bağlantısı gönderdik. Doğruladıktan sonra e-posta ve şifrenle giriş yap.",
            .hcAccuracy: "Doğruluk",
            .hcDailyStreak: "Günlük Seri",
            .hcBestStreak: "En İyi Seri",
            .hcProgress: "İlerleme",
            .hcRecommended: "⭐ TAVSİYE EDİLEN",
            .hcPerfectForBeginners: "Başlangıç için mükemmel",
            .hcNext: "İleri",
            .hcLetsStart: "Hadi Başlayalım!",
            .hcAIPage1Title: "AI ile Kişiselleştirilmiş Quiz",
            .hcAIPage1Desc: "Yapay zeka, seçtiğin konuya özel sorular hazırlar. Her seferinde farklı, her seferinde senin seviyene uygun!",
            .hcAIPage2Title: "Gramer Zamanları",
            .hcAIPage2Desc: "Simple Present'tan Past Perfect'e kadar tüm zaman kiplerini interaktif sorularla öğren. Özellikle Simple Present ile başlamanı öneririz! 🌟",
            .hcAIPage3Title: "Cümle Yapısı",
            .hcAIPage3Desc: "Koşul cümleleri, edilgen yapı, modal fiiller... Gerçek cümleler üzerinden pratik yaparak dili içselleştir.",
            .hcAIPage4Title: "Kelime Kategorileri",
            .hcAIPage4Desc: "Günlük hayat, yiyecekler, seyahat ve daha fazlası. Bağlam içinde kelime öğrenmek kalıcılığı 3 kat artırır!",
            .hcMuteTitle: "🔇 Sessiz Mod",
            .hcMuteConfirm: "15 dk Sessiz Devam",
            .hcCancel: "İptal",
            .hcMuteMessage: "Önümüzdeki 15 dakika boyunca sesli soru sorulmayacak, diğer soru tipleriyle devam edeceğiz.",
            .hcNewWord:  "Yeni kelime",
            .hcTranslateSentence: "Aşağıdaki cümleyi çevir",
            .hcPreparingLesson: "Konu anlatımı hazırlanıyor...",
            .hcTapToInterrupt: "Kesmek için dokunun",
            .hcHoldToSpeak: "Konuşmak için basılı tutun",
            .hcListening: "Seni dinliyorum...",
            .hcStartQuiz: "Quize Başla",
            .hcLessonLoadFailed: "Konu anlatımı yüklenemedi. Quize geçmek için aşağıdaki butonu kullanabilirsin.",
            .hcDidntHear: "Seni duyamadım, tekrar dener misin?",
            .hcChatHistory: "Konuşma Geçmişi",
            .hcAIServiceError: "Yapay zekâ servisine şu an ulaşılamıyor. Lütfen daha sonra tekrar dene.",
            .hcAIRateLimited: "Çok fazla istek gönderildi. Birkaç saniye bekleyip tekrar dene.",
            .hcAIEmptyResponse: "Sunucu boş yanıt döndürdü.",
            .loginFailedTitle: "Giriş Başarısız",
            .loginButton: "Giriş Yap",
            .loginForgotPassword: "Şifreni mi unuttun?",
            .loginSignUp: "Kayıt ol",
            .loginResetEmailMissing: "Önce yukarıya e-posta adresini yaz, sonra tekrar \"Şifreni mi unuttun?\" butonuna bas.",
            .loginResetEmailSent: "Bu e-postaya ait bir hesap varsa şifre sıfırlama bağlantısı gönderdik.",
            .loginResetTitle: "Şifre Sıfırlama",
            .paywallRestoreNothing: "Bu Apple Hesabı için aktif bir abonelik bulunamadı.",
            .paywallRestoreTitle: "Satın Alımları Geri Yükle",
            .paywallWeeklyTerm: "1 hafta · otomatik yenilenir",
            .profileDeleteFailed: "Hesabın silinemedi. Lütfen bağlantını kontrol edip tekrar dene.",
            .profileDeleting: "Hesap siliniyor…",
            .usernameSkip: "Atla",
            .aiConsentTitle: "Yapay Zekâ Özellikleri",
            .aiConsentMessage: "Quiz oluşturmak ve geri bildirim vermek için yazdığın metin ve söylediklerinin yazıya dökülmüş hali, işlenmek üzere yapay zekâ sağlayıcılarımıza (OpenAI ve Google) gönderilir. Ses kaydın gönderilmez. Ayrıntılar için Gizlilik Politikamıza bak.",
            .aiConsentAllow: "İzin Ver",
            .aiConsentDeny: "Şimdi Değil",
            .loadFailedMessage: "İçerik yüklenemedi. Bağlantını kontrol edip tekrar dene.",
            // Home
            .homeSearchPlaceholder: "Deste ara...",
            .homeMyDecks:           "Destelerim",
            .homeTapToStudy:        "Çalışmak için bir deste seç",
            .homeNoResultsFormat:   "\"%@\" için sonuç bulunamadı",
            .homeNoDecks:           "Henüz deste yok",
            .homeNoDecksHint:       "İlk desteni oluşturmak için\naşağıdaki + butonuna bas!",
            // Profile
            .profileTotalXP:        "Toplam XP",
            .profileStreak:         "Seri",
            .profileDaysFormat:     "%d gün",
            .profileStatistics:     "İstatistikler",
            .profileCompleted:      "Tamamlanan",
            .profileQuizzes:        "Quizler",
            .profileAccuracy:       "Doğruluk",
            .profileLevel:          "Seviye",
            .profileLevelFormat:    "Seviye %d",
            .profileAchievements:   "Başarılar",
            .profileFirstStreak:    "İlk Seri",
            .profile5Levels:        "5 Seviye",
            .profile100XP:          "100 XP",
            .profileSharpEye:       "Keskin Göz",
            .profile500XP:          "500 XP",
            .profileUpgradePro:     "Pro'ya Geç",
            .profileSignOut:        "Çıkış Yap",
            .profileGuest:          "Misafir",
            .profileDeleteAccount:  "Hesabı Sil",
            .profileDeleteTitle:    "Hesabı Kalıcı Olarak Sil",
            .profileDeleteMessage:  "Bu işlem geri alınamaz. Tüm verileriniz (ilerleme, XP, desteler) kalıcı olarak silinecektir.",
            .profileDeleteConfirm:  "Evet, Sil",
            .profileDeleteCancel:   "Vazgeç",
            // Leaderboard
            .leaderboardTitle:      "Sıralamalar",
            .leaderboardSubtitle:   "Diğer öğrencilerle yarış! 🏆",
            .leaderboardNoPlayers:  "Henüz oyuncu yok",
            .leaderboardNoPlayersHint: "Sıralamaya girmek için seviyeleri tamamla!",
            .leaderboardTryAgain:   "Tekrar Dene",
            .leaderboardDayStreak:  "%d günlük seri",
            // Tabs
            .tabDecks:              "Desteler",
            .tabPath:               "Yol",
            .tabTranslate:          "Çeviri",
            .tabRank:               "Sıralama",
            .tabProfile:            "Profil",
            // Path
            .pathMistakesFormat:    "%d Hatayı Çalış",
            .pathMistakesUrgent:    "10'dan fazla hatan var! Hemen çalış 👆",
            .pathUpdating:          "İlerleme güncelleniyor...",
            .pathSomethingWrong:    "Bir şeyler ters gitti",
            .pathTryAgain:          "Tekrar Dene",
            .pathRefresh:           "Yenile",
            .pathNoCourses:         "Henüz kurs yok",
            .pathNoCoursesHint:     "Kurs eklemek için Supabase SQL Editörünü kullan.",
            .pathNoCourseForLang:   "Bu dil için henüz kurs yok",
            .pathNoCourseForLangHint: "Seçtiğin dilde içerik hazırlanıyor.\nBeklemede kal!",
            .pathSelectCourse:      "Kurs Seç",
            .pathStart:             "Başla",
            .pathMotivation0:       "Devam et! Harikasın 🎯",
            .pathMotivation1:       "Büyük ilerleme! Muhteşemsin! 🌟",
            .pathMotivation2:       "Neredeyse bitti! Devam et! 💪",
            .pathMotivation3:       "Ustasın! 🏆",
            .pathWellDone:          "Aferin! 🎉",
            .pathWellDoneDesc:      "Bu seviyeyi başarıyla tamamladın ve XP kazandın. Böyle devam et!",
            .pathContinue:          "Devam",
            .pathDontBeSad:         "Üzülme... 🩹",
            .pathDontBeSadDesc:     "Eksik kelimeleri kaydettik, daha sonra çalışabilirsin. Devam et!",
            .pathGotIt:             "Anladım",
            .pathGreatWork:         "Harika İş! 🌟",
            .pathGreatWorkDesc:     "Tüm hataları temizledin ve hafızanı güçlendirdin! Muhteşemsin!",
            .pathHooray:            "Yaşasın!",
            .pathMistakesReview:    "Hata Tekrarı",
            // Game
            .gameLoading:           "Sorular yükleniyor…",
            .gameWhatIsMeaning:     "Bu kelimenin anlamı nedir?",
            .gameTypeTranslation:   "Çeviriyi yaz…",
            .gameCheck:             "Kontrol Et",
            .gameOutOfLives:        "Canın Bitti!",
            .gameDontGiveUp:        "Pes etme — tekrar dene!",
            .gameTryAgain:          "Tekrar Dene",
            .gameQuit:              "Çık",
            .gameQuitTitle:         "Çıkmak istiyor musun?",
            .gameQuitMessage:       "İlerlemeyi kaybedeceksin. Sadece 1 dakika daha ayır!",
            .gameQuitKeepGoing:     "Devam Et",
            .dailyLimitTitle:       "Günlük Limitin Doldu!",
            .dailyLimitSubtitle:    "Bugün 25 soruyu tamamladın.\nYarın tekrar devam edebilirsin.",
            .dailyLimitResetsIn:    "Yenileniyor:",
            .dailyLimitGetPro:      "Sınırsız Öğren — Pro'ya Geç",
            .dailyLimitClose:       "Kapat",
            .gameQuestionFormat:    "Soru %d / %d",
            .gameCorrect:           "Doğru! 🎉",
            .gameNotQuite:          "Pek değil…",
            .gameContinue:          "Devam",
            // Listening
            .gameListenPrompt:      "Kelimeyi dinle, doğru anlamı seç",
            .gameListenNormal:      "Dinle",
            .gameListenSlow:        "Yavaş Dinle",
            .gameListenCantHear:    "Duyamıyor musun?",
            // Speaking
            .gameSpeakPrompt:       "Kelimeyi gör ve yüksek sesle söyle",
            .gameSpeakMicHint:      "Mikrofona dokun ve konuş",
            .gameSpeakCantSpeak:    "Konuşamıyor musun? Geç",
            .gameSpeakListening:    "Dinleniyor…",
            .gameSpeakNoPermission: "Mikrofon izni gerekli",
            // Result
            .resultLevelComplete:   "Seviye Tamamlandı!",
            .resultKeepPracticing:  "Pratik Yapmaya Devam Et!",
            .resultScore:           "Puan",
            .resultXPEarned:        "Kazanılan XP",
            .resultContinue:        "Devam",
            .resultTryAgain:        "Tekrar Dene",
            // Profile - Guest & Username
            .profileSaveProgress:       "İlerlemenizi Kaydedin",
            .profileSaveProgressHint:   "Hesap oluşturun, her şey güvende kalsın",
            .profileSaveProgressDesc:   "Hesap oluşturarak XP'leriniz, serileriniz ve tüm ilerlemeniz güvende kalsın. Uygulamayı silseniz bile her şey yerli yerinde.",
            .profileLoginApple:         "Apple ile Devam Et",
            .profileLoginGoogle:        "Google ile Devam Et",
            .profileLoginEmail:         "E-posta ile Kayıt Ol",
            .profileClose:              "Kapat",
            .profileSave:               "Kaydet",
            .profileSetUsername:        "Kullanıcı adın ne olsun?",
            .profileChangeUsername:     "Kullanıcı adını değiştir",
            .profileUsernameLeaderboard: "Bu isim leaderboard ve profilinde görünecek.",
            .profileUsernameOneChange:  "Bu hakkı yalnızca 1 kez kullanabilirsin.\nLeaderboard ve profilinde güncellenir.",
            .profileUsernamePlaceholder: "Kullanıcı adı (min. 3 karakter)",
            // Leaderboard - Guest
            .leaderboardJoinTitle:      "Sıralamaya katıl! 🏆",
            .leaderboardJoinDesc:       "Leaderboard'u görmek ve\nsıralamaya girmek için giriş yapman gerekiyor.",
            .leaderboardSignIn:         "Giriş Yap",
            // Home - Empty state
            .homeCreateFirstDeck:       "İlk desteni oluştur! 🎉",
            .homeCreateFirstDeckHint:   "Kelimelerini ekle, Reeny seninle\nçalışmaya hazır!",
            .homeCreateDeck:            "Deste Oluştur",
            // Path - Unit & Status
            .pathUnitFormat:            "Ünite %d",
            .pathLevelProgressFormat:   "%d/%d seviye",
            .pathStatusCompleted:       "Tamamlandı",
            .pathStatusInProgress:      "Devam Ediyor",
            .pathStatusLocked:          "Kilitli",
            // Home - Loading
            .homeLoadingDecks:          "Desteleriniz yükleniyor, az sabır! 🐾",
            // Game - Hint popup
            .gameHintTitle:             "İpucu",
            .gameHintRemainingFormat:   "%d ipucu kaldı",
            .gameHintGotIt:             "Anladım, Devam Et",
            // Game - Quiz labels
            .gameFillBlank:             "Boşluğu doldur",
            .gameTranslateLabel:        "Çevir:",
            .gameLoadingAudio:          "Yükleniyor...",
            .gameWordQuestionFormat:    "%@ kelimesi nedir?",
            // Achievement - Rarity
            .achievementRarityCommon:    "Yaygın",
            .achievementRarityRare:      "Nadir",
            .achievementRarityEpic:      "Epik",
            .achievementRarityLegendary: "Efsanevi",
            // Achievement - UI
            .achievementViewMore:        "Tümünü Gör",
            .achievementAllTitle:        "Tüm Başarımlar",
            .achievementUnlockedBadge:   "Kazanıldı",
            .achievementLockedBadge:     "Kilitli",
            .achievementNewUnlocked:     "Yeni Başarım! 🏆",
            .achievementTapToDismiss:    "Kapatmak için dokun",
            // Achievements - Common
            .achFirstStepsTitle:    "İlk Adım",
            .achFirstStepsDesc:     "İlk quizini tamamladın. Yolculuk başlıyor!",
            .achFirstStreakTitle:   "İlk Seri",
            .achFirstStreakDesc:    "Bir günlük serini korudun. Devam et!",
            .ach100XPTitle:        "100 XP",
            .ach100XPDesc:         "100 XP kazandın. Hızlı başladın!",
            .ach5LevelsTitle:      "5 Seviye",
            .ach5LevelsDesc:       "5 seviyeyi tamamladın. Harika ilerliyorsun!",
            .ach50CorrectTitle:    "50 Doğru",
            .ach50CorrectDesc:     "50 soruyu doğru yanıtladın. Süpersin!",
            // Achievements - Rare
            .ach500XPTitle:        "500 XP",
            .ach500XPDesc:         "500 XP'ye ulaştın. Gerçek bir öğrenci!",
            .achSharpEyeTitle:     "Keskin Göz",
            .achSharpEyeDesc:      "En az 20 soruda %90+ doğruluk oranı. İnanılmaz!",
            .ach10LevelsTitle:     "10 Seviye",
            .ach10LevelsDesc:      "10 seviyeyi geçtin. Yolun açık!",
            .ach7StreakTitle:      "Haftalık Seri",
            .ach7StreakDesc:       "7 gün üst üste çalıştın. Alışkanlık oldu!",
            .ach1000XPTitle:       "1000 XP",
            .ach1000XPDesc:        "1000 XP kazandın. Çok azı bu noktaya ulaşır!",
            .ach100CorrectTitle:   "100 Doğru",
            .ach100CorrectDesc:    "100 soruyu doğru yanıtladın. Sana güveniyoruz!",
            // Achievements - Epic
            .ach25LevelsTitle:     "25 Seviye",
            .ach25LevelsDesc:      "25 seviye tamamlandı. Sen bir efsanesin!",
            .ach30StreakTitle:     "Aylık Seri",
            .ach30StreakDesc:      "30 gün boyunca her gün çalıştın. Müthiş!",
            .achPerfectionistTitle:"Mükemmeliyetçi",
            .achPerfectionistDesc: "En az 50 soruda %95+ doğruluk. Mükemmel!",
            .ach5000XPTitle:       "5000 XP",
            .ach5000XPDesc:        "5000 XP! Artık uçuyorsun!",
            .ach500CorrectTitle:   "500 Doğru",
            .ach500CorrectDesc:    "500 doğru cevap. Kelime canavarısın!",
            // Achievements - Legendary
            .ach50LevelsTitle:     "50 Seviye",
            .ach50LevelsDesc:      "50 seviye! Efsaneler buraya ulaşır.",
            .ach100StreakTitle:    "100 Günlük Seri",
            .ach100StreakDesc:     "100 gün boyunca kesintisiz! Demir iradelisin.",
            .ach10000XPTitle:      "10.000 XP",
            .ach10000XPDesc:       "10.000 XP'ye ulaştın. Sen bir efsanesin!",
            .achWordGodTitle:      "Kelime Tanrısı",
            .achWordGodDesc:       "1000 quiz sorusu tamamlandı. Kelime tanrısısın!",
            // Streak
            .streakStartedTitle:   "Bir seri başlattınız! 🔥",
            .streakContinuedTitle: "%d Günlük Seri! 🔥",
            .streakSubtitle:       "Dil yolculuğunuz bugün başlıyor! Devam edin ve hedeflerinize ulaşın.",
            .streakContinue:       "Devam",
            .navSettings:          "Ayarlar",
            .navExampleSentences:  "Örnek Cümleler",
            .welcomeNewTitle:      "WordRem'e Hoşgeldin! 🎉",
            .welcomeNewSubtitle:   "Dil öğreniminin en akıllı yolu",
            .welcomeNewFeature1:   "⚡ Hızlı & eğlenceli quizler",
            .welcomeNewFeature2:   "🔥 Streak sistemi ile motivasyonunu koru",
            .welcomeNewFeature3:   "🏆 Liderlik tablosunda yüksel",
            .welcomeNewCTA:        "Hadi Başlayalım!",
            .welcomeBackTitle:     "Tekrar Hoşgeldin! 👋",
            .welcomeBackMessageFormat: "Seni çok özledik, %@!",
            .welcomeBackMotivation:    "Hedeflerine devam etme zamanı 💪",
            .welcomeBackCTA:       "Devam Et",
            .welcomeProTitle:      "WordRem Pro'ya Hoşgeldin! 👑",
            .welcomeProSubtitle:   "Tüm premium özellikler artık açık",
            .welcomeProFeature1:   "Sınırsız günlük soru hakkı",
            .welcomeProFeature2:   "Sınırsız ipucu kullanımı",
            .welcomeProFeature3:   "Yapay zeka destekli öğrenme",
            .welcomeProCTA:        "Öğrenmeye Başla!",
            .dailyBreakTitle:        "Günlük Hedefe Ulaştın! ☕",
            .dailyBreakBodyFormat:   "Bugün %d dakika boyunca pratik yaptın. Aferin!",
            .dailyBreakSubtitle:     "Bir mola verebilirsin — ama devam etmek tamamen senin kararın.",
            .dailyBreakRest:         "Mola Ver",
            .dailyBreakContinue:     "Devam Et",
        ],

        // ─────────────────────────────────────────
        "en": [
            // Welcome
            .welcomeTagline:        "A few words a day.\nRemembered for good.",
            .welcomeStart:          "Get started",
            .welcomeHaveAccount:    "I already have an account",
            // Paywall
            .paywallSubtitle:       "Take your learning to the next level",
            .paywallFeature1:       "Unlimited daily practice",
            .paywallFeature2:       "Unlimited hints",
            .paywallFeature3:       "Unlimited AI quizzes",
            .paywallFeature4:       "Unlimited AI speaking coach",
            .paywallFeature1Sub:    "No daily question limit",
            .paywallFeature2Sub:    "Never run out of hints when you're stuck",
            .paywallFeature3Sub:    "Create as many AI quizzes as you like",
            .paywallFeature4Sub:    "Practice grammar and pronunciation with AI",
            .paywallReviewsTitle:   "What users say",
            .paywallWeeklyPro:      "Weekly Pro",
            .paywallPerWeek:        "%@ / week",
            .paywallRecommended:    "RECOMMENDED",
            .paywallPriceFailed:    "Price unavailable",
            .paywallRetry:          "Retry",
            .paywallContinue:       "Continue",
            .paywallPurchaseFailed: "Purchase failed",
            .paywallPurchaseError:  "Something went wrong. Please try again or use restore.",
            .paywallOk:             "OK",
            .paywallPrivacy:        "Privacy",
            .paywallTerms:          "Terms of Use (EULA)",
            .paywallRestore:        "Restore",
            .paywallDisclosure:     "Payment will be charged to your Apple Account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage subscriptions in App Store Account Settings.",
            .paywallAnnual: "Annual",
            .paywallWeeklyPlan: "Weekly",
            .paywallBestValue: "Best value",
            .paywallSave: "Save %d%%",
            .paywallPerYear: "%@ / year",
            .paywallWeeklyEquiv: "Just %@ per week",
            .paywallTrialBadge: "%d days free",
            .paywallStartTrial: "Start %d-day free trial",
            .paywallTrialThen: "%d days free, then %@ / year. Cancel anytime.",
            .paywallNoCommit: "No commitment · Cancel anytime",
            .paywallTLToday: "Today",
            .paywallTLTodaySub: "Every course and feature unlocks",
            .paywallTLDay: "Day %d",
            .paywallTLReminderSub: "We'll remind you before the trial ends",
            .paywallTLChargeSub: "Subscription starts and you're charged",
            .paywallTrialReminderTitle: "Your free trial ends in 2 days",
            .paywallTrialReminderBody: "Not for you? Cancel anytime in Settings › Subscriptions.",
            .gcJoinTitle: "See how you rank",
            .gcJoinDesc: "The leaderboard uses Game Center. Sign in to Game Center in Settings to compare your XP with other learners.",
            .gcOpenSettings: "Open Settings",
            .profileResetProgress: "Reset progress",
            .profileResetTitle: "Reset all progress?",
            .profileResetMessage: "Your XP, streak, learned words and decks will be deleted from this device and iCloud. This can't be undone. Your subscription is not affected.",
            .profileResetConfirm: "Reset",
            .profileSyncNote: "Your progress syncs automatically with your iCloud account.",
            .deckNoWords: "No words yet",
            .deckTapToAdd: "Tap + to add your first word",
            .deckWordCount: "%d words",
            .deckOneWord: "1 word",
            .deckQuiz: "Quiz",
            .deckCreateTitle: "Create a New Deck",
            .deckCreateSubtitle: "Choose a flag and give your deck a memorable name.",
            .deckChooseFlag: "Choose flag",
            .deckLanguages: "Translation languages",
            .deckSource: "Source",
            .deckTarget: "Target",
            .deckName: "Deck name",
            .deckNamePlaceholder: "E.g. Spanish Basics, Useful Verbs",
            .deckCreate: "Create deck",
            .cardCreateTitle: "Create Your Word",
            .cardEditTitle: "Edit Your Word",
            .cardWordLabel: "Word (in your native language)",
            .cardTranslating: "Translating...",
            .cardTranslate: "Translate",
            .cardMeaningLabel: "Translation (in learning language)",
            .cardGenerating: "Generating sentence...",
            .cardGenerateSentence: "Generate example sentence",
            .cardExampleSentence: "Example sentence",
            .cardReminder: "Reminder",
            .cardReminderDate: "Reminder date & time",
            .cardRepeat: "Repeat",
            .cardRepeatNone: "None",
            .cardRepeatWeekly: "Weekly",
            .cardRepeatMonthly: "Monthly",
            .cardEveryWeeks: "Every %d week(s)",
            .cardEveryMonths: "Every %d month(s)",
            .cardSave: "Save",
            .cardAddWord: "Add word",
            .cardCancel: "Cancel",
            .cardError: "Error",
            .cardDone: "Done",
            .aiQuizTitle: "AI Quiz",
            .aiQuizSubtitle: "Grammar & vocabulary practice",
            .aiQuizHowMany: "How many questions?",
            .aiQuizGenerate: "Create quiz",
            .aiQuizPreparing: "Preparing your quiz...",
            .aiQuizAbout: "%d questions about",
            .aiQuizError: "Something went wrong",
            .aiQuizTryAgain: "Try again",
            .aiQuizTopicsCount: "%d topics",
            .aiQuizQuestionsUnit: "questions",
            .commonSkip: "Skip",
            .commonClose: "Close",
            .pathAIGrammarQuiz: "AI grammar quiz",
            .profTotalQuestions: "Questions",
            .profCompleted: "Completed",
            .profStreak: "Streak",
            .profLevelN: "Level %d",
            .profNextLevel: "Next level",
            .profTotalXP: "Total XP",
            .profLevels: "Levels",
            .quizAnalyzing: "Analyzing...",
            .loginTitle: "Welcome back",
            .loginSubtitle: "Pick up your words where you left off.",
            .loginEmail: "Email",
            .loginPassword: "Password",
            .loginWithApple: "Continue with Apple",
            .loginWithGoogle: "Continue with Google",
            .loginOr: "or",
            .todayTitle: "Today",
            .todayDueCount: "words to review",
            .todayDueMinutes: "About %d min",
            .todayStartReview: "Start review",
            .todayAllDone: "All caught up",
            .todayAllDoneBody: "Nice work. Learn a few new words, or come back tomorrow.",
            .todayNoWords: "Your first words are waiting",
            .todayNoWordsBody: "Finish a lesson in Practice. Words you get right come back here right before you'd forget them.",
            .todayLearnNew: "Learn new words",
            .todayStreak: "Day streak",
            .todayKnown: "Words",
            .todayThisWeek: "This week",
            .todayWordOfDay: "Word of the day",
            .todayMistakes: "Words to fix",
            .reviewShow: "Show answer",
            .reviewAgain: "Again",
            .reviewHard: "Hard",
            .reviewGood: "Good",
            .reviewEasy: "Easy",
            .reviewMinutes: "10 min",
            .reviewDays: "%d d",
            .reviewDoneTitle: "Done for today",
            .reviewDoneBody: "You reviewed %d words. See you tomorrow.",
            .reviewClose: "Close",
            .wordsTitle: "My Words",
            .wordsLearned: "Learned",
            .wordsDecks: "Decks",
            .wordsSearch: "Search words",
            .wordsEmpty: "Words you learn will appear here.",
            .wordsDue: "Due",
            .wordsDueIn: "in %d d",
            .wordsMastered: "Mastered",
            .tabToday: "Today",
            .tabWords: "Words",
            .tabPractice: "Practice",
            .registerCheckEmailTitle: "Confirm Your Email",
            .registerCheckEmail: "We sent a confirmation link to your email. After confirming, log in with your email and password.",
            .hcAccuracy: "Accuracy",
            .hcDailyStreak: "Daily Streak",
            .hcBestStreak: "Best Streak",
            .hcProgress: "Progress",
            .hcRecommended: "⭐ RECOMMENDED",
            .hcPerfectForBeginners: "Perfect for beginners",
            .hcNext: "Next",
            .hcLetsStart: "Let's Get Started!",
            .hcAIPage1Title: "Personalized Quizzes with AI",
            .hcAIPage1Desc: "AI creates questions tailored to the topic you choose. Different every time, always at your level!",
            .hcAIPage2Title: "Grammar Tenses",
            .hcAIPage2Desc: "Learn every tense from Simple Present to Past Perfect with interactive questions. We recommend starting with Simple Present! 🌟",
            .hcAIPage3Title: "Sentence Structure",
            .hcAIPage3Desc: "Conditionals, passive voice, modal verbs... Internalize the language by practicing with real sentences.",
            .hcAIPage4Title: "Vocabulary Categories",
            .hcAIPage4Desc: "Daily life, food, travel and more. Learning words in context makes them stick 3 times longer!",
            .hcMuteTitle: "🔇 Silent Mode",
            .hcMuteConfirm: "Mute for 15 min",
            .hcCancel: "Cancel",
            .hcMuteMessage: "No listening questions will be asked for the next 15 minutes; we'll continue with other question types.",
            .hcNewWord:  "New word",
            .hcTranslateSentence: "Translate the sentence below",
            .hcPreparingLesson: "Preparing the lesson...",
            .hcTapToInterrupt: "Tap to interrupt",
            .hcHoldToSpeak: "Hold to speak",
            .hcListening: "I'm listening...",
            .hcStartQuiz: "Start Quiz",
            .hcLessonLoadFailed: "The lesson couldn't be loaded. You can use the button below to go to the quiz.",
            .hcDidntHear: "I couldn't hear you, could you try again?",
            .hcChatHistory: "Conversation History",
            .hcAIServiceError: "The AI service is temporarily unavailable. Please try again later.",
            .hcAIRateLimited: "Too many requests. Please wait a few seconds and try again.",
            .hcAIEmptyResponse: "The server returned an empty response.",
            .loginFailedTitle: "Sign In Failed",
            .loginButton: "Log In",
            .loginForgotPassword: "Forgot your password?",
            .loginSignUp: "Sign up",
            .loginResetEmailMissing: "Enter your email address above first, then tap \"Forgot your password?\" again.",
            .loginResetEmailSent: "If an account exists for this email, we've sent a password reset link.",
            .loginResetTitle: "Reset Password",
            .paywallRestoreNothing: "No active subscription was found for this Apple Account.",
            .paywallRestoreTitle: "Restore Purchases",
            .paywallWeeklyTerm: "1 week · auto-renewing",
            .profileDeleteFailed: "Your account could not be deleted. Please check your connection and try again.",
            .profileDeleting: "Deleting account…",
            .usernameSkip: "Skip",
            .aiConsentTitle: "AI-Powered Features",
            .aiConsentMessage: "To create quizzes and give feedback, the text you type and the transcript of what you say are sent to our AI providers (OpenAI and Google) for processing. Your audio recording is not sent. See our Privacy Policy for details.",
            .aiConsentAllow: "Allow",
            .aiConsentDeny: "Not Now",
            .loadFailedMessage: "Couldn't load content. Check your connection and try again.",
            // Home
            .homeSearchPlaceholder: "Search decks...",
            .homeMyDecks:           "My Decks",
            .homeTapToStudy:        "Tap a deck to study",
            .homeNoResultsFormat:   "No results for \"%@\"",
            .homeNoDecks:           "No decks yet",
            .homeNoDecksHint:       "Use the + button below\nto create your first deck!",
            // Profile
            .profileTotalXP:        "Total XP",
            .profileStreak:         "Streak",
            .profileDaysFormat:     "%d days",
            .profileStatistics:     "Statistics",
            .profileCompleted:      "Completed",
            .profileQuizzes:        "Quizzes",
            .profileAccuracy:       "Accuracy",
            .profileLevel:          "Level",
            .profileLevelFormat:    "Level %d",
            .profileAchievements:   "Achievements",
            .profileFirstStreak:    "First Streak",
            .profile5Levels:        "5 Levels",
            .profile100XP:          "100 XP",
            .profileSharpEye:       "Sharp Eye",
            .profile500XP:          "500 XP",
            .profileUpgradePro:     "Upgrade Pro",
            .profileSignOut:        "Sign Out",
            .profileGuest:          "Guest",
            .profileDeleteAccount:  "Delete Account",
            .profileDeleteTitle:    "Permanently Delete Account",
            .profileDeleteMessage:  "This action cannot be undone. All your data (progress, XP, decks) will be permanently deleted.",
            .profileDeleteConfirm:  "Yes, Delete",
            .profileDeleteCancel:   "Cancel",
            // Leaderboard
            .leaderboardTitle:      "Leaderboard",
            .leaderboardSubtitle:   "Compete with other learners! 🏆",
            .leaderboardNoPlayers:  "No players yet",
            .leaderboardNoPlayersHint: "Complete levels to join the leaderboard!",
            .leaderboardTryAgain:   "Try Again",
            .leaderboardDayStreak:  "%d day streak",
            // Tabs
            .tabDecks:              "Decks",
            .tabPath:               "Path",
            .tabTranslate:          "Translate",
            .tabRank:               "Rank",
            .tabProfile:            "Profile",
            // Path
            .pathMistakesFormat:    "Practice %d Mistakes",
            .pathMistakesUrgent:    "You have 10+ mistakes! Practice now 👆",
            .pathUpdating:          "Updating your progress...",
            .pathSomethingWrong:    "Something went wrong",
            .pathTryAgain:          "Try Again",
            .pathRefresh:           "Refresh",
            .pathNoCourses:         "No courses yet",
            .pathNoCoursesHint:     "Run supabase_seed.sql in your\nSupabase SQL Editor to add courses.",
            .pathNoCourseForLang:   "No courses for this language yet",
            .pathNoCourseForLangHint: "Content for your selected language\nis on the way. Stay tuned!",
            .pathSelectCourse:      "Select a Course",
            .pathStart:              "Start",
            .pathMotivation0:       "Keep going! You're doing great 🎯",
            .pathMotivation1:       "Great progress! You're doing amazing! 🌟",
            .pathMotivation2:       "Almost there! Keep it up! 💪",
            .pathMotivation3:       "You're a master! 🏆",
            .pathWellDone:          "Well Done! 🎉",
            .pathWellDoneDesc:      "You've successfully completed this level and earned XP. Keep up the great work!",
            .pathContinue:          "Continue",
            .pathDontBeSad:         "Don't be sad... 🩹",
            .pathDontBeSadDesc:     "We saved the words you missed so you can practice them later. Keep going!",
            .pathGotIt:             "Got it",
            .pathGreatWork:         "Great Work! 🌟",
            .pathGreatWorkDesc:     "You've cleared all your mistakes and reinforced your memory! You are awesome!",
            .pathHooray:            "Hooray!",
            .pathMistakesReview:    "Mistakes Review",
            // Game
            .gameLoading:           "Loading questions…",
            .gameWhatIsMeaning:     "What is the meaning of this word?",
            .gameTypeTranslation:   "Type the translation…",
            .gameCheck:             "Check",
            .gameOutOfLives:        "Out of Lives!",
            .gameDontGiveUp:        "Don't give up — try again!",
            .gameTryAgain:          "Try Again",
            .gameQuit:              "Quit",
            .gameQuitTitle:         "Quit the quiz?",
            .gameQuitMessage:       "You'll lose your progress. Just 1 more minute!",
            .gameQuitKeepGoing:     "Keep Going",
            .dailyLimitTitle:       "Daily Limit Reached!",
            .dailyLimitSubtitle:    "You've completed 25 questions today.\nCome back tomorrow!",
            .dailyLimitResetsIn:    "Resets in:",
            .dailyLimitGetPro:      "Learn Unlimited — Go Pro",
            .dailyLimitClose:       "Close",
            .gameQuestionFormat:    "Question %d / %d",
            .gameCorrect:           "Correct! 🎉",
            .gameNotQuite:          "Not quite…",
            .gameContinue:          "Continue",
            // Listening
            .gameListenPrompt:      "Listen to the word, pick the correct meaning",
            .gameListenNormal:      "Play",
            .gameListenSlow:        "Play Slowly",
            .gameListenCantHear:    "Can't hear it?",
            // Speaking
            .gameSpeakPrompt:       "See the word and say it aloud",
            .gameSpeakMicHint:      "Tap the mic and speak",
            .gameSpeakCantSpeak:    "Can't speak? Skip",
            .gameSpeakListening:    "Listening…",
            .gameSpeakNoPermission: "Microphone permission required",
            // Result
            .resultLevelComplete:   "Level Complete!",
            .resultKeepPracticing:  "Keep Practicing!",
            .resultScore:           "Score",
            .resultXPEarned:        "XP Earned",
            .resultContinue:        "Continue",
            .resultTryAgain:        "Try Again",
            // Profile - Guest & Username
            .profileSaveProgress:       "Save Your Progress",
            .profileSaveProgressHint:   "Create an account, keep everything safe",
            .profileSaveProgressDesc:   "Create an account to keep your XP, streaks and all progress safe. Even if you delete the app, everything stays intact.",
            .profileLoginApple:         "Continue with Apple",
            .profileLoginGoogle:        "Continue with Google",
            .profileLoginEmail:         "Sign Up with Email",
            .profileClose:              "Close",
            .profileSave:               "Save",
            .profileSetUsername:        "What should your username be?",
            .profileChangeUsername:     "Change your username",
            .profileUsernameLeaderboard: "This name will appear on the leaderboard and your profile.",
            .profileUsernameOneChange:  "You can only use this right once.\nWill be updated on the leaderboard and your profile.",
            .profileUsernamePlaceholder: "Username (min. 3 characters)",
            // Leaderboard - Guest
            .leaderboardJoinTitle:      "Join the leaderboard! 🏆",
            .leaderboardJoinDesc:       "You need to log in to see the leaderboard\nand join the rankings.",
            .leaderboardSignIn:         "Sign In",
            // Home - Empty state
            .homeCreateFirstDeck:       "Create Your First Deck! 🎉",
            .homeCreateFirstDeckHint:   "Add your words, Reeny is ready\nto study with you!",
            .homeCreateDeck:            "Create Deck",
            // Path - Unit & Status
            .pathUnitFormat:            "Unit %d",
            .pathLevelProgressFormat:   "%d/%d levels",
            .pathStatusCompleted:       "Completed",
            .pathStatusInProgress:      "In Progress",
            .pathStatusLocked:          "Locked",
            .homeLoadingDecks:          "Loading your decks, hang tight! 🐾",
            .gameHintTitle:             "Hint",
            .gameHintRemainingFormat:   "%d hints left",
            .gameHintGotIt:             "Got It, Continue",
            .gameFillBlank:             "Fill in the blank",
            .gameTranslateLabel:        "Translate:",
            .gameLoadingAudio:          "Loading...",
            .gameWordQuestionFormat:    "What is the %@ word?",
            // Achievement - Rarity
            .achievementRarityCommon:    "Common",
            .achievementRarityRare:      "Rare",
            .achievementRarityEpic:      "Epic",
            .achievementRarityLegendary: "Legendary",
            // Achievement - UI
            .achievementViewMore:        "View All",
            .achievementAllTitle:        "All Achievements",
            .achievementUnlockedBadge:   "Unlocked",
            .achievementLockedBadge:     "Locked",
            .achievementNewUnlocked:     "New Achievement! 🏆",
            .achievementTapToDismiss:    "Tap to dismiss",
            // Common
            .achFirstStepsTitle:    "First Steps",
            .achFirstStepsDesc:     "You completed your first quiz. The journey begins!",
            .achFirstStreakTitle:   "First Streak",
            .achFirstStreakDesc:    "You kept a 1-day streak. Keep going!",
            .ach100XPTitle:        "100 XP",
            .ach100XPDesc:         "You earned 100 XP. Off to a great start!",
            .ach5LevelsTitle:      "5 Levels",
            .ach5LevelsDesc:       "You completed 5 levels. Great progress!",
            .ach50CorrectTitle:    "50 Correct",
            .ach50CorrectDesc:     "You answered 50 questions correctly. You're amazing!",
            // Rare
            .ach500XPTitle:        "500 XP",
            .ach500XPDesc:         "You reached 500 XP. You're a real learner!",
            .achSharpEyeTitle:     "Sharp Eye",
            .achSharpEyeDesc:      "90%+ accuracy over 20+ questions. Incredible!",
            .ach10LevelsTitle:     "10 Levels",
            .ach10LevelsDesc:      "You completed 10 levels. The path is clear!",
            .ach7StreakTitle:      "Week Streak",
            .ach7StreakDesc:       "7 days in a row! It's becoming a habit!",
            .ach1000XPTitle:       "1000 XP",
            .ach1000XPDesc:        "You earned 1000 XP. Few ever reach this point!",
            .ach100CorrectTitle:   "100 Correct",
            .ach100CorrectDesc:    "100 correct answers. We believe in you!",
            // Epic
            .ach25LevelsTitle:     "25 Levels",
            .ach25LevelsDesc:      "25 levels done. You're a legend in the making!",
            .ach30StreakTitle:     "Month Streak",
            .ach30StreakDesc:      "30 consecutive days of studying. Extraordinary!",
            .achPerfectionistTitle:"Perfectionist",
            .achPerfectionistDesc: "95%+ accuracy over 50+ questions. Perfect!",
            .ach5000XPTitle:       "5000 XP",
            .ach5000XPDesc:        "5000 XP! You're flying now!",
            .ach500CorrectTitle:   "500 Correct",
            .ach500CorrectDesc:    "500 correct answers. You're a word monster!",
            // Legendary
            .ach50LevelsTitle:     "50 Levels",
            .ach50LevelsDesc:      "50 levels! Only legends reach this far.",
            .ach100StreakTitle:    "100-Day Streak",
            .ach100StreakDesc:     "100 days without stopping! Iron will.",
            .ach10000XPTitle:      "10,000 XP",
            .ach10000XPDesc:       "You reached 10,000 XP. You're a true legend!",
            .achWordGodTitle:      "Word God",
            .achWordGodDesc:       "1000 quiz questions completed. You are the Word God!",
            // Streak
            .streakStartedTitle:   "You started a streak! 🔥",
            .streakContinuedTitle: "%d Day Streak! 🔥",
            .streakSubtitle:       "Your language journey starts today! Keep going and reach your goals.",
            .streakContinue:       "Continue",
            .navSettings:          "Settings",
            .navExampleSentences:  "Example Sentences",
            .welcomeNewTitle:      "Welcome to WordRem! 🎉",
            .welcomeNewSubtitle:   "The smartest way to learn languages",
            .welcomeNewFeature1:   "⚡ Fast & fun quizzes",
            .welcomeNewFeature2:   "🔥 Stay motivated with streaks",
            .welcomeNewFeature3:   "🏆 Climb the leaderboard",
            .welcomeNewCTA:        "Let's Get Started!",
            .welcomeBackTitle:     "Welcome Back! 👋",
            .welcomeBackMessageFormat: "We missed you so much, %@!",
            .welcomeBackMotivation:    "Time to keep up with your goals 💪",
            .welcomeBackCTA:       "Continue",
            .welcomeProTitle:      "Welcome to WordRem Pro! 👑",
            .welcomeProSubtitle:   "All premium features are now unlocked",
            .welcomeProFeature1:   "Unlimited daily questions",
            .welcomeProFeature2:   "Unlimited hint usage",
            .welcomeProFeature3:   "AI-powered learning",
            .welcomeProCTA:        "Start Learning!",
            .dailyBreakTitle:        "Daily Goal Reached! ☕",
            .dailyBreakBodyFormat:   "You've practiced for %d minutes today. Well done!",
            .dailyBreakSubtitle:     "You can take a break — but continuing is entirely your call.",
            .dailyBreakRest:         "Take a Break",
            .dailyBreakContinue:     "Keep Going",
        ],

        // ─────────────────────────────────────────
        "de": [
            // Welcome
            .welcomeTagline:        "Ein paar Wörter am Tag.\nFür immer gemerkt.",
            .welcomeStart:          "Loslegen",
            .welcomeHaveAccount:    "Ich habe bereits ein Konto",
            // Paywall
            .paywallSubtitle:       "Bringe dein Lernen auf die nächste Stufe",
            .paywallFeature1:       "Unbegrenztes tägliches Üben",
            .paywallFeature2:       "Unbegrenzte Hinweise",
            .paywallFeature3:       "Unbegrenzte KI-Quizze",
            .paywallFeature4:       "Unbegrenzter KI-Sprechcoach",
            .paywallFeature1Sub:    "Kein tägliches Fragenlimit",
            .paywallFeature2Sub:    "Dir gehen nie die Hinweise aus",
            .paywallFeature3Sub:    "Erstelle so viele KI-Quizze, wie du willst",
            .paywallFeature4Sub:    "Übe Grammatik und Aussprache mit KI",
            .paywallReviewsTitle:   "Was sagen Nutzer?",
            .paywallWeeklyPro:      "Wöchentliches Pro",
            .paywallPerWeek:        "%@ / Woche",
            .paywallRecommended:    "EMPFOHLEN",
            .paywallPriceFailed:    "Preis nicht verfügbar",
            .paywallRetry:          "Erneut versuchen",
            .paywallContinue:       "Weiter",
            .paywallPurchaseFailed: "Kauf fehlgeschlagen",
            .paywallPurchaseError:  "Ein Fehler ist aufgetreten. Bitte versuche es erneut oder stelle wieder her.",
            .paywallOk:             "OK",
            .paywallPrivacy:        "Datenschutz",
            .paywallTerms:          "Nutzungsbedingungen",
            .paywallRestore:        "Wiederherstellen",
            .paywallDisclosure:     "Die Zahlung wird bei Kaufbestätigung Ihrem Apple-Konto belastet. Das Abonnement verlängert sich automatisch, sofern es nicht mindestens 24 Stunden vor Ablauf der aktuellen Laufzeit gekündigt wird. Abonnements können in den App-Store-Kontoeinstellungen verwaltet werden.",
            .paywallAnnual: "Jährlich",
            .paywallWeeklyPlan: "Wöchentlich",
            .paywallBestValue: "Bester Wert",
            .paywallSave: "%d %% sparen",
            .paywallPerYear: "%@ / Jahr",
            .paywallWeeklyEquiv: "Nur %@ pro Woche",
            .paywallTrialBadge: "%d Tage gratis",
            .paywallStartTrial: "%d Tage kostenlos testen",
            .paywallTrialThen: "%d Tage gratis, dann %@ / Jahr. Jederzeit kündbar.",
            .paywallNoCommit: "Keine Bindung · Jederzeit kündbar",
            .paywallTLToday: "Heute",
            .paywallTLTodaySub: "Alle Kurse und Funktionen werden freigeschaltet",
            .paywallTLDay: "Tag %d",
            .paywallTLReminderSub: "Wir erinnern dich vor Ende des Tests",
            .paywallTLChargeSub: "Das Abo beginnt, die Zahlung erfolgt",
            .paywallTrialReminderTitle: "Dein Test endet in 2 Tagen",
            .paywallTrialReminderBody: "Nichts für dich? Kündige jederzeit unter Einstellungen › Abonnements.",
            // Home
            .homeSearchPlaceholder: "Stapel suchen...",
            .homeMyDecks:           "Meine Stapel",
            .homeTapToStudy:        "Tippe auf einen Stapel zum Lernen",
            .homeNoResultsFormat:   "Keine Ergebnisse für \"%@\"",
            .homeNoDecks:           "Noch keine Stapel",
            .homeNoDecksHint:       "Tippe unten auf +,\num deinen ersten Stapel zu erstellen!",
            // Profile
            .profileTotalXP:        "Gesamt-XP",
            .profileStreak:         "Serie",
            .profileDaysFormat:     "%d Tage",
            .profileStatistics:     "Statistiken",
            .profileCompleted:      "Abgeschlossen",
            .profileQuizzes:        "Quiz",
            .profileAccuracy:       "Genauigkeit",
            .profileLevel:          "Level",
            .profileLevelFormat:    "Level %d",
            .profileAchievements:   "Erfolge",
            .profileFirstStreak:    "Erste Serie",
            .profile5Levels:        "5 Level",
            .profile100XP:          "100 XP",
            .profileSharpEye:       "Scharfes Auge",
            .profile500XP:          "500 XP",
            .profileUpgradePro:     "Auf Pro upgraden",
            .profileSignOut:        "Abmelden",
            .profileGuest:          "Gast",
            .profileDeleteAccount:  "Konto löschen",
            .profileDeleteTitle:    "Konto dauerhaft löschen",
            .profileDeleteMessage:  "Diese Aktion kann nicht rückgängig gemacht werden. Alle Ihre Daten werden dauerhaft gelöscht.",
            .profileDeleteConfirm:  "Ja, löschen",
            .profileDeleteCancel:   "Abbrechen",
            // Leaderboard
            .leaderboardTitle:      "Rangliste",
            .leaderboardSubtitle:   "Tritt gegen andere Lernende an! 🏆",
            .leaderboardNoPlayers:  "Noch keine Spieler",
            .leaderboardNoPlayersHint: "Schließe Level ab, um der Rangliste beizutreten!",
            .leaderboardTryAgain:   "Erneut versuchen",
            .leaderboardDayStreak:  "%d-Tage-Serie",
            // Tabs
            .tabDecks:              "Stapel",
            .tabPath:               "Pfad",
            .tabTranslate:          "Übersetzen",
            .tabRank:               "Rang",
            .tabProfile:            "Profil",
            // Path
            .pathMistakesFormat:    "%d Fehler üben",
            .pathMistakesUrgent:    "Du hast 10+ Fehler! Jetzt üben 👆",
            .pathUpdating:          "Fortschritt wird aktualisiert...",
            .pathSomethingWrong:    "Etwas ist schiefgelaufen",
            .pathTryAgain:          "Erneut versuchen",
            .pathRefresh:           "Aktualisieren",
            .pathNoCourses:         "Noch keine Kurse",
            .pathNoCoursesHint:     "Führe supabase_seed.sql im\nSupabase SQL-Editor aus.",
            .pathNoCourseForLang:   "Noch keine Kurse für diese Sprache",
            .pathNoCourseForLangHint: "Inhalte für deine Sprache\nkommen bald. Bleib dran!",
            .pathSelectCourse:      "Kurs auswählen",
            .pathStart:              "Start",
            .pathMotivation0:       "Weiter so! Du machst das toll 🎯",
            .pathMotivation1:       "Großartige Fortschritte! Du bist toll! 🌟",
            .pathMotivation2:       "Fast geschafft! Weiter so! 💪",
            .pathMotivation3:       "Du bist ein Meister! 🏆",
            .pathWellDone:          "Gut gemacht! 🎉",
            .pathWellDoneDesc:      "Du hast dieses Level erfolgreich abgeschlossen und XP verdient. Weiter so!",
            .pathContinue:          "Weiter",
            .pathDontBeSad:         "Nicht traurig sein... 🩹",
            .pathDontBeSadDesc:     "Wir haben die Wörter gespeichert, die du verpasst hast. Weiter üben!",
            .pathGotIt:             "Verstanden",
            .pathGreatWork:         "Tolle Arbeit! 🌟",
            .pathGreatWorkDesc:     "Du hast alle Fehler bereinigt und dein Gedächtnis gestärkt! Du bist super!",
            .pathHooray:            "Hurra!",
            .pathMistakesReview:    "Fehler-Wiederholung",
            // Game
            .gameLoading:           "Fragen werden geladen…",
            .gameWhatIsMeaning:     "Was bedeutet dieses Wort?",
            .gameTypeTranslation:   "Gib die Übersetzung ein…",
            .gameCheck:             "Prüfen",
            .gameOutOfLives:        "Keine Leben mehr!",
            .gameDontGiveUp:        "Gib nicht auf — versuche es erneut!",
            .gameTryAgain:          "Erneut versuchen",
            .gameQuit:              "Beenden",
            .gameQuitTitle:         "Quiz beenden?",
            .gameQuitMessage:       "Du verlierst deinen Fortschritt. Nur noch 1 Minute!",
            .gameQuitKeepGoing:     "Weitermachen",
            .dailyLimitTitle:       "Tageslimit erreicht!",
            .dailyLimitSubtitle:    "Du hast heute 25 Fragen abgeschlossen.\nKomm morgen wieder!",
            .dailyLimitResetsIn:    "Zurückgesetzt in:",
            .dailyLimitGetPro:      "Unbegrenzt lernen — Pro werden",
            .dailyLimitClose:       "Schließen",
            .gameQuestionFormat:    "Frage %d / %d",
            .gameCorrect:           "Richtig! 🎉",
            .gameNotQuite:          "Nicht ganz…",
            .gameContinue:          "Weiter",
            // Listening
            .gameListenPrompt:      "Höre das Wort, wähle die richtige Bedeutung",
            .gameListenNormal:      "Abspielen",
            .gameListenSlow:        "Langsam abspielen",
            .gameListenCantHear:    "Kannst du es nicht hören?",
            // Speaking
            .gameSpeakPrompt:       "Sieh das Wort und sage es laut",
            .gameSpeakMicHint:      "Tippe auf das Mikrofon und sprich",
            .gameSpeakCantSpeak:    "Kannst du nicht sprechen? Überspringen",
            .gameSpeakListening:    "Wird gehört…",
            .gameSpeakNoPermission: "Mikrofonberechtigung erforderlich",
            // Result
            .resultLevelComplete:   "Level abgeschlossen!",
            .resultKeepPracticing:  "Weiter üben!",
            .resultScore:           "Punkte",
            .resultXPEarned:        "XP verdient",
            .resultContinue:        "Weiter",
            .resultTryAgain:        "Erneut versuchen",
            // Profile - Guest & Username
            .profileSaveProgress:       "Fortschritt sichern",
            .profileSaveProgressHint:   "Konto erstellen, alles sicher aufbewahren",
            .profileSaveProgressDesc:   "Erstelle ein Konto, um deine XP, Serien und Fortschritte zu sichern. Auch nach dem Löschen der App bleibt alles erhalten.",
            .profileLoginApple:         "Mit Apple fortfahren",
            .profileLoginGoogle:        "Mit Google fortfahren",
            .profileLoginEmail:         "Mit E-Mail registrieren",
            .profileClose:              "Schließen",
            .profileSave:               "Speichern",
            .profileSetUsername:        "Wie soll dein Benutzername lauten?",
            .profileChangeUsername:     "Benutzernamen ändern",
            .profileUsernameLeaderboard: "Dieser Name erscheint im Leaderboard und deinem Profil.",
            .profileUsernameOneChange:  "Du kannst dieses Recht nur einmal nutzen.\nWird im Leaderboard und Profil aktualisiert.",
            .profileUsernamePlaceholder: "Benutzername (min. 3 Zeichen)",
            // Leaderboard - Guest
            .leaderboardJoinTitle:      "Tritt dem Leaderboard bei! 🏆",
            .leaderboardJoinDesc:       "Melde dich an, um das Leaderboard zu sehen\nund mitzumachen.",
            .leaderboardSignIn:         "Anmelden",
            // Home - Empty state
            .homeCreateFirstDeck:       "Erstelle deinen ersten Stapel! 🎉",
            .homeCreateFirstDeckHint:   "Füge deine Wörter hinzu, Reeny ist bereit\nmit dir zu lernen!",
            .homeCreateDeck:            "Stapel erstellen",
            // Path - Unit & Status
            .pathUnitFormat:            "Einheit %d",
            .pathLevelProgressFormat:   "%d/%d Level",
            .pathStatusCompleted:       "Abgeschlossen",
            .pathStatusInProgress:      "In Bearbeitung",
            .pathStatusLocked:          "Gesperrt",
            .homeLoadingDecks:          "Deine Decks werden geladen, kurz warten! 🐾",
            .gameHintTitle:             "Hinweis",
            .gameHintRemainingFormat:   "%d Hinweise übrig",
            .gameHintGotIt:             "Verstanden, Weiter",
            .gameFillBlank:             "Lücke ausfüllen",
            .gameTranslateLabel:        "Übersetzen:",
            .gameLoadingAudio:          "Lädt...",
            .gameWordQuestionFormat:    "Was ist das %@ Wort?",
            .streakStartedTitle:   "Du hast eine Serie gestartet! 🔥",
            .streakContinuedTitle: "%d Tage Serie! 🔥",
            .streakSubtitle:       "Deine Sprachreise beginnt heute! Mach weiter und erreiche deine Ziele.",
            .navSettings:          "Einstellungen",
            .navExampleSentences:  "Beispielsätze",
            .streakContinue:       "Weiter",
            .welcomeNewTitle:      "Willkommen bei WordRem! 🎉",
            .welcomeNewSubtitle:   "Der cleverste Weg, Sprachen zu lernen",
            .welcomeNewFeature1:   "⚡ Schnelle & spaßige Quizze",
            .welcomeNewFeature2:   "🔥 Bleib motiviert mit Serien",
            .welcomeNewFeature3:   "🏆 Erklimm die Bestenliste",
            .welcomeNewCTA:        "Jetzt Starten!",
            .welcomeBackTitle:     "Willkommen zurück! 👋",
            .welcomeBackMessageFormat: "Wir haben dich so vermisst, %@!",
            .welcomeBackMotivation:    "Zeit, deine Ziele weiterzuverfolgen 💪",
            .welcomeBackCTA:       "Weiter",
            .welcomeProTitle:      "Willkommen bei WordRem Pro! 👑",
            .welcomeProSubtitle:   "Alle Premium-Funktionen sind jetzt freigeschaltet",
            .welcomeProFeature1:   "Unbegrenzte tägliche Fragen",
            .welcomeProFeature2:   "Unbegrenzte Hinweis-Nutzung",
            .welcomeProFeature3:   "KI-gestütztes Lernen",
            .welcomeProCTA:        "Jetzt Lernen!",
            .dailyBreakTitle:        "Tagesziel erreicht! ☕",
            .dailyBreakBodyFormat:   "Du hast heute %d Minuten geübt. Prima!",
            .dailyBreakSubtitle:     "Du kannst eine Pause machen — aber weiterzumachen liegt bei dir.",
            .dailyBreakRest:         "Pause machen",
            .dailyBreakContinue:     "Weitermachen",
        ],

        // ─────────────────────────────────────────
        "fr": [
            // Welcome
            .welcomeTagline:        "Quelques mots par jour.\nRetenus pour de bon.",
            .welcomeStart:          "Commencer",
            .welcomeHaveAccount:    "J'ai déjà un compte",
            // Paywall
            .paywallSubtitle:       "Passe ton apprentissage au niveau supérieur",
            .paywallFeature1:       "Pratique quotidienne illimitée",
            .paywallFeature2:       "Indices illimités",
            .paywallFeature3:       "Quiz IA illimités",
            .paywallFeature4:       "Coach oral IA illimité",
            .paywallFeature1Sub:    "Aucune limite de questions par jour",
            .paywallFeature2Sub:    "Ne sois jamais à court d'indices",
            .paywallFeature3Sub:    "Crée autant de quiz IA que tu veux",
            .paywallFeature4Sub:    "Travaille grammaire et prononciation avec l'IA",
            .paywallReviewsTitle:   "Ce que disent les utilisateurs",
            .paywallWeeklyPro:      "Pro hebdomadaire",
            .paywallPerWeek:        "%@ / semaine",
            .paywallRecommended:    "RECOMMANDÉ",
            .paywallPriceFailed:    "Prix indisponible",
            .paywallRetry:          "Réessayer",
            .paywallContinue:       "Continuer",
            .paywallPurchaseFailed: "Achat échoué",
            .paywallPurchaseError:  "Une erreur s'est produite. Réessaie ou utilise la restauration.",
            .paywallOk:             "OK",
            .paywallPrivacy:        "Confidentialité",
            .paywallTerms:          "Conditions d'utilisation",
            .paywallRestore:        "Restaurer",
            .paywallDisclosure:     "Le paiement sera débité de votre compte Apple lors de la confirmation de l'achat. L'abonnement se renouvelle automatiquement, sauf s'il est annulé au moins 24 heures avant la fin de la période en cours. Gérez vos abonnements dans les réglages du compte App Store.",
            .paywallAnnual: "Annuel",
            .paywallWeeklyPlan: "Hebdomadaire",
            .paywallBestValue: "Meilleur prix",
            .paywallSave: "Économisez %d %%",
            .paywallPerYear: "%@ / an",
            .paywallWeeklyEquiv: "Seulement %@ par semaine",
            .paywallTrialBadge: "%d jours offerts",
            .paywallStartTrial: "Essayer %d jours gratuitement",
            .paywallTrialThen: "%d jours offerts, puis %@ / an. Résiliable à tout moment.",
            .paywallNoCommit: "Sans engagement · Résiliable à tout moment",
            .paywallTLToday: "Aujourd'hui",
            .paywallTLTodaySub: "Tous les cours et fonctions sont débloqués",
            .paywallTLDay: "Jour %d",
            .paywallTLReminderSub: "On vous prévient avant la fin de l'essai",
            .paywallTLChargeSub: "L'abonnement commence et vous êtes débité",
            .paywallTrialReminderTitle: "Votre essai se termine dans 2 jours",
            .paywallTrialReminderBody: "Pas pour vous ? Résiliez dans Réglages › Abonnements.",
            // Home
            .homeSearchPlaceholder: "Rechercher des decks...",
            .homeMyDecks:           "Mes Decks",
            .homeTapToStudy:        "Appuie sur un deck pour étudier",
            .homeNoResultsFormat:   "Aucun résultat pour \"%@\"",
            .homeNoDecks:           "Pas encore de decks",
            .homeNoDecksHint:       "Utilise le bouton + ci-dessous\npour créer ton premier deck !",
            // Profile
            .profileTotalXP:        "XP Total",
            .profileStreak:         "Série",
            .profileDaysFormat:     "%d jours",
            .profileStatistics:     "Statistiques",
            .profileCompleted:      "Terminés",
            .profileQuizzes:        "Quiz",
            .profileAccuracy:       "Précision",
            .profileLevel:          "Niveau",
            .profileLevelFormat:    "Niveau %d",
            .profileAchievements:   "Succès",
            .profileFirstStreak:    "Première série",
            .profile5Levels:        "5 niveaux",
            .profile100XP:          "100 XP",
            .profileSharpEye:       "Œil vif",
            .profile500XP:          "500 XP",
            .profileUpgradePro:     "Passer à Pro",
            .profileSignOut:        "Se déconnecter",
            .profileGuest:          "Invité",
            .profileDeleteAccount:  "Supprimer le compte",
            .profileDeleteTitle:    "Supprimer définitivement le compte",
            .profileDeleteMessage:  "Cette action est irréversible. Toutes vos données seront définitivement supprimées.",
            .profileDeleteConfirm:  "Oui, supprimer",
            .profileDeleteCancel:   "Annuler",
            // Leaderboard
            .leaderboardTitle:      "Classement",
            .leaderboardSubtitle:   "Affronte d'autres apprenants ! 🏆",
            .leaderboardNoPlayers:  "Pas encore de joueurs",
            .leaderboardNoPlayersHint: "Complète des niveaux pour rejoindre le classement !",
            .leaderboardTryAgain:   "Réessayer",
            .leaderboardDayStreak:  "série de %d jours",
            // Tabs
            .tabDecks:              "Decks",
            .tabPath:               "Parcours",
            .tabTranslate:          "Traduire",
            .tabRank:               "Rang",
            .tabProfile:            "Profil",
            // Path
            .pathMistakesFormat:    "Pratiquer %d erreurs",
            .pathMistakesUrgent:    "Tu as 10+ erreurs ! Entraîne-toi maintenant 👆",
            .pathUpdating:          "Mise à jour de ta progression...",
            .pathSomethingWrong:    "Quelque chose s'est mal passé",
            .pathTryAgain:          "Réessayer",
            .pathRefresh:           "Actualiser",
            .pathNoCourses:         "Pas encore de cours",
            .pathNoCoursesHint:     "Exécute supabase_seed.sql dans\nl'éditeur SQL Supabase.",
            .pathNoCourseForLang:   "Pas encore de cours pour cette langue",
            .pathNoCourseForLangHint: "Le contenu pour ta langue\narrive bientôt. Reste connecté!",
            .pathSelectCourse:      "Choisir un cours",
            .pathStart:              "Démarrer",
            .pathMotivation0:       "Continue ! Tu es génial 🎯",
            .pathMotivation1:       "Super progrès ! Tu es incroyable ! 🌟",
            .pathMotivation2:       "Presque là ! Continue ! 💪",
            .pathMotivation3:       "Tu es un maître ! 🏆",
            .pathWellDone:          "Bien joué ! 🎉",
            .pathWellDoneDesc:      "Tu as réussi ce niveau et gagné des XP. Continue comme ça !",
            .pathContinue:          "Continuer",
            .pathDontBeSad:         "Ne sois pas triste... 🩹",
            .pathDontBeSadDesc:     "On a sauvegardé les mots manqués pour t'entraîner plus tard. Continue !",
            .pathGotIt:             "Compris",
            .pathGreatWork:         "Excellent travail ! 🌟",
            .pathGreatWorkDesc:     "Tu as corrigé toutes tes erreurs et renforcé ta mémoire ! Tu es formidable !",
            .pathHooray:            "Hourra !",
            .pathMistakesReview:    "Révision des erreurs",
            // Game
            .gameLoading:           "Chargement des questions…",
            .gameWhatIsMeaning:     "Quelle est la signification de ce mot ?",
            .gameTypeTranslation:   "Écris la traduction…",
            .gameCheck:             "Vérifier",
            .gameOutOfLives:        "Plus de vies !",
            .gameDontGiveUp:        "N'abandonne pas — réessaie !",
            .gameTryAgain:          "Réessayer",
            .gameQuit:              "Quitter",
            .gameQuitTitle:         "Quitter le quiz ?",
            .gameQuitMessage:       "Tu perdras ta progression. Encore 1 minute !",
            .gameQuitKeepGoing:     "Continuer",
            .dailyLimitTitle:       "Limite quotidienne atteinte !",
            .dailyLimitSubtitle:    "Tu as complété 25 questions aujourd'hui.\nReviens demain !",
            .dailyLimitResetsIn:    "Réinitialisation dans :",
            .dailyLimitGetPro:      "Apprendre sans limite — Passer Pro",
            .dailyLimitClose:       "Fermer",
            .gameQuestionFormat:    "Question %d / %d",
            .gameCorrect:           "Correct ! 🎉",
            .gameNotQuite:          "Pas tout à fait…",
            .gameContinue:          "Continuer",
            // Listening
            .gameListenPrompt:      "Écoute le mot, choisis le bon sens",
            .gameListenNormal:      "Écouter",
            .gameListenSlow:        "Écouter lentement",
            .gameListenCantHear:    "Tu n'entends pas ?",
            // Speaking
            .gameSpeakPrompt:       "Vois le mot et dis-le à voix haute",
            .gameSpeakMicHint:      "Appuie sur le micro et parle",
            .gameSpeakCantSpeak:    "Tu ne peux pas parler ? Passer",
            .gameSpeakListening:    "Écoute en cours…",
            .gameSpeakNoPermission: "Permission du microphone requise",
            // Result
            .resultLevelComplete:   "Niveau terminé !",
            .resultKeepPracticing:  "Continue à t'entraîner !",
            .resultScore:           "Score",
            .resultXPEarned:        "XP gagné",
            .resultContinue:        "Continuer",
            .resultTryAgain:        "Réessayer",
            // Profile - Guest & Username
            .profileSaveProgress:       "Sauvegarde tes progrès",
            .profileSaveProgressHint:   "Crée un compte, garde tout en sécurité",
            .profileSaveProgressDesc:   "Crée un compte pour garder tes XP, séries et tous tes progrès en sécurité. Même si tu supprimes l'appli, tout reste intact.",
            .profileLoginApple:         "Continuer avec Apple",
            .profileLoginGoogle:        "Continuer avec Google",
            .profileLoginEmail:         "S'inscrire avec l'e-mail",
            .profileClose:              "Fermer",
            .profileSave:               "Sauvegarder",
            .profileSetUsername:        "Quel devrait être ton pseudo ?",
            .profileChangeUsername:     "Changer ton pseudo",
            .profileUsernameLeaderboard: "Ce nom apparaîtra sur le classement et ton profil.",
            .profileUsernameOneChange:  "Tu ne peux utiliser ce droit qu'une seule fois.\nSera mis à jour dans le classement et ton profil.",
            .profileUsernamePlaceholder: "Pseudo (min. 3 caractères)",
            // Leaderboard - Guest
            .leaderboardJoinTitle:      "Rejoins le classement ! 🏆",
            .leaderboardJoinDesc:       "Tu dois te connecter pour voir le classement\net y participer.",
            .leaderboardSignIn:         "Se connecter",
            // Home - Empty state
            .homeCreateFirstDeck:       "Crée ton premier deck ! 🎉",
            .homeCreateFirstDeckHint:   "Ajoute tes mots, Reeny est prêt\nà étudier avec toi !",
            .homeCreateDeck:            "Créer un deck",
            // Path - Unit & Status
            .pathUnitFormat:            "Unité %d",
            .pathLevelProgressFormat:   "%d/%d niveaux",
            .pathStatusCompleted:       "Terminé",
            .pathStatusInProgress:      "En cours",
            .pathStatusLocked:          "Verrouillé",
            .homeLoadingDecks:          "Chargement de vos decks, encore un instant ! 🐾",
            .gameHintTitle:             "Indice",
            .gameHintRemainingFormat:   "%d indices restants",
            .gameHintGotIt:             "Compris, Continuer",
            .gameFillBlank:             "Remplir le blanc",
            .gameTranslateLabel:        "Traduire :",
            .gameLoadingAudio:          "Chargement...",
            .gameWordQuestionFormat:    "Quel est le mot %@ ?",
            .streakStartedTitle:   "Vous avez démarré une série ! 🔥",
            .streakContinuedTitle: "Série de %d jours ! 🔥",
            .streakSubtitle:       "Votre voyage linguistique commence aujourd'hui ! Continuez à atteindre vos objectifs.",
            .navSettings:          "Paramètres",
            .navExampleSentences:  "Exemples de phrases",
            .streakContinue:       "Continuer",
            .welcomeNewTitle:      "Bienvenue sur WordRem ! 🎉",
            .welcomeNewSubtitle:   "La façon la plus intelligente d'apprendre les langues",
            .welcomeNewFeature1:   "⚡ Quiz rapides & amusants",
            .welcomeNewFeature2:   "🔥 Reste motivé avec les séries",
            .welcomeNewFeature3:   "🏆 Grimpe dans le classement",
            .welcomeNewCTA:        "C'est parti !",
            .welcomeBackTitle:     "Bon retour ! 👋",
            .welcomeBackMessageFormat: "Tu nous as tellement manqué, %@ !",
            .welcomeBackMotivation:    "Il est temps de continuer vers tes objectifs 💪",
            .welcomeBackCTA:       "Continuer",
            .welcomeProTitle:      "Bienvenue dans WordRem Pro ! 👑",
            .welcomeProSubtitle:   "Toutes les fonctionnalités premium sont débloquées",
            .welcomeProFeature1:   "Questions quotidiennes illimitées",
            .welcomeProFeature2:   "Utilisation illimitée des indices",
            .welcomeProFeature3:   "Apprentissage avec l'IA",
            .welcomeProCTA:        "Commencer à apprendre !",
            .dailyBreakTitle:        "Objectif du jour atteint ! ☕",
            .dailyBreakBodyFormat:   "Tu as pratiqué pendant %d minutes aujourd'hui. Bravo !",
            .dailyBreakSubtitle:     "Tu peux faire une pause — mais continuer est ton choix.",
            .dailyBreakRest:         "Faire une pause",
            .dailyBreakContinue:     "Continuer",
        ],

        // ─────────────────────────────────────────
        "es": [
            // Welcome
            .welcomeTagline:        "Unas pocas palabras al día.\nPara siempre.",
            .welcomeStart:          "Empezar",
            .welcomeHaveAccount:    "Ya tengo una cuenta",
            // Paywall
            .paywallSubtitle:       "Lleva tu aprendizaje al siguiente nivel",
            .paywallFeature1:       "Práctica diaria ilimitada",
            .paywallFeature2:       "Pistas ilimitadas",
            .paywallFeature3:       "Cuestionarios IA ilimitados",
            .paywallFeature4:       "Entrenador de conversación IA ilimitado",
            .paywallFeature1Sub:    "Sin límite diario de preguntas",
            .paywallFeature2Sub:    "Nunca te quedes sin pistas",
            .paywallFeature3Sub:    "Crea todos los cuestionarios IA que quieras",
            .paywallFeature4Sub:    "Practica gramática y pronunciación con IA",
            .paywallReviewsTitle:   "¿Qué dicen los usuarios?",
            .paywallWeeklyPro:      "Pro semanal",
            .paywallPerWeek:        "%@ / semana",
            .paywallRecommended:    "RECOMENDADO",
            .paywallPriceFailed:    "Precio no disponible",
            .paywallRetry:          "Reintentar",
            .paywallContinue:       "Continuar",
            .paywallPurchaseFailed: "Compra fallida",
            .paywallPurchaseError:  "Ocurrió un error. Por favor, inténtalo de nuevo o usa restaurar.",
            .paywallOk:             "OK",
            .paywallPrivacy:        "Privacidad",
            .paywallTerms:          "Términos de uso",
            .paywallRestore:        "Restaurar",
            .paywallDisclosure:     "El pago se cargará a tu cuenta de Apple al confirmar la compra. La suscripción se renueva automáticamente a menos que se cancele al menos 24 horas antes del final del período actual. Administra las suscripciones en Configuración de cuenta de App Store.",
            .paywallAnnual: "Anual",
            .paywallWeeklyPlan: "Semanal",
            .paywallBestValue: "Mejor precio",
            .paywallSave: "Ahorra un %d %%",
            .paywallPerYear: "%@ / año",
            .paywallWeeklyEquiv: "Solo %@ a la semana",
            .paywallTrialBadge: "%d días gratis",
            .paywallStartTrial: "Prueba %d días gratis",
            .paywallTrialThen: "%d días gratis, luego %@ / año. Cancela cuando quieras.",
            .paywallNoCommit: "Sin compromiso · Cancela cuando quieras",
            .paywallTLToday: "Hoy",
            .paywallTLTodaySub: "Se desbloquean todos los cursos y funciones",
            .paywallTLDay: "Día %d",
            .paywallTLReminderSub: "Te avisamos antes de que termine la prueba",
            .paywallTLChargeSub: "Empieza la suscripción y se te cobra",
            .paywallTrialReminderTitle: "Tu prueba termina en 2 días",
            .paywallTrialReminderBody: "¿No es para ti? Cancela en Ajustes › Suscripciones.",
            // Home
            .homeSearchPlaceholder: "Buscar mazos...",
            .homeMyDecks:           "Mis Mazos",
            .homeTapToStudy:        "Toca un mazo para estudiar",
            .homeNoResultsFormat:   "Sin resultados para \"%@\"",
            .homeNoDecks:           "Aún no hay mazos",
            .homeNoDecksHint:       "Usa el botón + de abajo\n¡para crear tu primer mazo!",
            // Profile
            .profileTotalXP:        "XP Total",
            .profileStreak:         "Racha",
            .profileDaysFormat:     "%d días",
            .profileStatistics:     "Estadísticas",
            .profileCompleted:      "Completados",
            .profileQuizzes:        "Cuestionarios",
            .profileAccuracy:       "Precisión",
            .profileLevel:          "Nivel",
            .profileLevelFormat:    "Nivel %d",
            .profileAchievements:   "Logros",
            .profileFirstStreak:    "Primera racha",
            .profile5Levels:        "5 Niveles",
            .profile100XP:          "100 XP",
            .profileSharpEye:       "Ojo afilado",
            .profile500XP:          "500 XP",
            .profileUpgradePro:     "Mejorar a Pro",
            .profileSignOut:        "Cerrar sesión",
            .profileGuest:          "Invitado",
            .profileDeleteAccount:  "Eliminar cuenta",
            .profileDeleteTitle:    "Eliminar cuenta permanentemente",
            .profileDeleteMessage:  "Esta acción no se puede deshacer. Todos tus datos serán eliminados permanentemente.",
            .profileDeleteConfirm:  "Sí, eliminar",
            .profileDeleteCancel:   "Cancelar",
            // Leaderboard
            .leaderboardTitle:      "Clasificación",
            .leaderboardSubtitle:   "¡Compite con otros estudiantes! 🏆",
            .leaderboardNoPlayers:  "Aún no hay jugadores",
            .leaderboardNoPlayersHint: "¡Completa niveles para unirte a la clasificación!",
            .leaderboardTryAgain:   "Reintentar",
            .leaderboardDayStreak:  "racha de %d días",
            // Tabs
            .tabDecks:              "Mazos",
            .tabPath:               "Ruta",
            .tabTranslate:          "Traducir",
            .tabRank:               "Rango",
            .tabProfile:            "Perfil",
            // Path
            .pathMistakesFormat:    "Practicar %d errores",
            .pathMistakesUrgent:    "¡Tienes 10+ errores! Practica ahora 👆",
            .pathUpdating:          "Actualizando tu progreso...",
            .pathSomethingWrong:    "Algo salió mal",
            .pathTryAgain:          "Reintentar",
            .pathRefresh:           "Actualizar",
            .pathNoCourses:         "Aún no hay cursos",
            .pathNoCoursesHint:     "Ejecuta supabase_seed.sql en\nel editor SQL de Supabase.",
            .pathNoCourseForLang:   "Aún no hay cursos para este idioma",
            .pathNoCourseForLangHint: "El contenido para tu idioma\nestá en camino. ¡Permanece atento!",
            .pathSelectCourse:      "Seleccionar curso",
            .pathStart:             "Empezar",
            .pathMotivation0:       "¡Sigue adelante! Lo estás haciendo genial 🎯",
            .pathMotivation1:       "¡Gran progreso! ¡Eres increíble! 🌟",
            .pathMotivation2:       "¡Casi lo logras! ¡Sigue así! 💪",
            .pathMotivation3:       "¡Eres un maestro! 🏆",
            .pathWellDone:          "¡Bien hecho! 🎉",
            .pathWellDoneDesc:      "Completaste este nivel exitosamente y ganaste XP. ¡Sigue así!",
            .pathContinue:          "Continuar",
            .pathDontBeSad:         "No te pongas triste... 🩹",
            .pathDontBeSadDesc:     "Guardamos las palabras que fallaste para que puedas practicarlas. ¡Sigue adelante!",
            .pathGotIt:             "Entendido",
            .pathGreatWork:         "¡Gran trabajo! 🌟",
            .pathGreatWorkDesc:     "¡Eliminaste todos tus errores y reforzaste tu memoria! ¡Eres increíble!",
            .pathHooray:            "¡Hurra!",
            .pathMistakesReview:    "Repaso de errores",
            // Game
            .gameLoading:           "Cargando preguntas…",
            .gameWhatIsMeaning:     "¿Cuál es el significado de esta palabra?",
            .gameTypeTranslation:   "Escribe la traducción…",
            .gameCheck:             "Verificar",
            .gameOutOfLives:        "¡Sin vidas!",
            .gameDontGiveUp:        "No te rindas — ¡inténtalo de nuevo!",
            .gameTryAgain:          "Reintentar",
            .gameQuit:              "Salir",
            .gameQuitTitle:         "¿Salir del quiz?",
            .gameQuitMessage:       "Perderás tu progreso. ¡Solo 1 minuto más!",
            .gameQuitKeepGoing:     "Continuar",
            .dailyLimitTitle:       "¡Límite diario alcanzado!",
            .dailyLimitSubtitle:    "Completaste 25 preguntas hoy.\n¡Vuelve mañana!",
            .dailyLimitResetsIn:    "Se restablece en:",
            .dailyLimitGetPro:      "Aprender sin límites — Ir Pro",
            .dailyLimitClose:       "Cerrar",
            .gameQuestionFormat:    "Pregunta %d / %d",
            .gameCorrect:           "¡Correcto! 🎉",
            .gameNotQuite:          "No del todo…",
            .gameContinue:          "Continuar",
            // Listening
            .gameListenPrompt:      "Escucha la palabra, elige el significado correcto",
            .gameListenNormal:      "Reproducir",
            .gameListenSlow:        "Reproducir despacio",
            .gameListenCantHear:    "¿No puedes escuchar?",
            // Speaking
            .gameSpeakPrompt:       "Ve la palabra y dila en voz alta",
            .gameSpeakMicHint:      "Toca el micrófono y habla",
            .gameSpeakCantSpeak:    "¿No puedes hablar? Saltar",
            .gameSpeakListening:    "Escuchando…",
            .gameSpeakNoPermission: "Se requiere permiso del micrófono",
            // Result
            .resultLevelComplete:   "¡Nivel completado!",
            .resultKeepPracticing:  "¡Sigue practicando!",
            .resultScore:           "Puntuación",
            .resultXPEarned:        "XP ganado",
            .resultContinue:        "Continuar",
            .resultTryAgain:        "Reintentar",
            // Profile - Guest & Username
            .profileSaveProgress:       "Guarda tu progreso",
            .profileSaveProgressHint:   "Crea una cuenta, mantén todo seguro",
            .profileSaveProgressDesc:   "Crea una cuenta para guardar tu XP, rachas y todo tu progreso. Aunque borres la app, todo quedará intacto.",
            .profileLoginApple:         "Continuar con Apple",
            .profileLoginGoogle:        "Continuar con Google",
            .profileLoginEmail:         "Registrarse con correo",
            .profileClose:              "Cerrar",
            .profileSave:               "Guardar",
            .profileSetUsername:        "¿Cuál debería ser tu nombre de usuario?",
            .profileChangeUsername:     "Cambiar tu nombre de usuario",
            .profileUsernameLeaderboard: "Este nombre aparecerá en el marcador y tu perfil.",
            .profileUsernameOneChange:  "Solo puedes usar este derecho una vez.\nSe actualizará en el marcador y tu perfil.",
            .profileUsernamePlaceholder: "Nombre de usuario (mín. 3 caracteres)",
            // Leaderboard - Guest
            .leaderboardJoinTitle:      "¡Únete al marcador! 🏆",
            .leaderboardJoinDesc:       "Necesitas iniciar sesión para ver el marcador\ny unirte a las clasificaciones.",
            .leaderboardSignIn:         "Iniciar sesión",
            // Home - Empty state
            .homeCreateFirstDeck:       "¡Crea tu primer mazo! 🎉",
            .homeCreateFirstDeckHint:   "Añade tus palabras, Reeny está listo\npara estudiar contigo!",
            .homeCreateDeck:            "Crear mazo",
            // Path - Unit & Status
            .pathUnitFormat:            "Unidad %d",
            .pathLevelProgressFormat:   "%d/%d niveles",
            .pathStatusCompleted:       "Completado",
            .pathStatusInProgress:      "En progreso",
            .pathStatusLocked:          "Bloqueado",
            .homeLoadingDecks:          "Cargando tus mazos, ¡un momento! 🐾",
            .gameHintTitle:             "Pista",
            .gameHintRemainingFormat:   "%d pistas restantes",
            .gameHintGotIt:             "Entendido, Continuar",
            .gameFillBlank:             "Rellena el espacio",
            .gameTranslateLabel:        "Traducir:",
            .gameLoadingAudio:          "Cargando...",
            .gameWordQuestionFormat:    "¿Cuál es la palabra en %@?",
            .streakStartedTitle:   "¡Has iniciado una racha! 🔥",
            .streakContinuedTitle: "¡Racha de %d días! 🔥",
            .streakSubtitle:       "¡Tu viaje lingüístico empieza hoy! Sigue adelante y alcanza tus metas.",
            .navSettings:          "Ajustes",
            .navExampleSentences:  "Frases de ejemplo",
            .streakContinue:       "Continuar",
            .welcomeNewTitle:      "¡Bienvenido a WordRem! 🎉",
            .welcomeNewSubtitle:   "La forma más inteligente de aprender idiomas",
            .welcomeNewFeature1:   "⚡ Quizzes rápidos y divertidos",
            .welcomeNewFeature2:   "🔥 Mantente motivado con rachas",
            .welcomeNewFeature3:   "🏆 Escala en el marcador",
            .welcomeNewCTA:        "¡Comencemos!",
            .welcomeBackTitle:     "¡Bienvenido de vuelta! 👋",
            .welcomeBackMessageFormat: "¡Te echamos tanto de menos, %@!",
            .welcomeBackMotivation:    "Es hora de seguir con tus metas 💪",
            .welcomeBackCTA:       "Continuar",
            .welcomeProTitle:      "¡Bienvenido a WordRem Pro! 👑",
            .welcomeProSubtitle:   "Todas las funciones premium están desbloqueadas",
            .welcomeProFeature1:   "Preguntas diarias ilimitadas",
            .welcomeProFeature2:   "Uso ilimitado de pistas",
            .welcomeProFeature3:   "Aprendizaje con IA",
            .welcomeProCTA:        "¡Empezar a aprender!",
            .dailyBreakTitle:        "¡Meta diaria alcanzada! ☕",
            .dailyBreakBodyFormat:   "Has practicado %d minutos hoy. ¡Bien hecho!",
            .dailyBreakSubtitle:     "Puedes tomar un descanso — pero continuar es tu decisión.",
            .dailyBreakRest:         "Tomar un descanso",
            .dailyBreakContinue:     "Seguir",
        ],

        // ─────────────────────────────────────────
        "it": [
            // Welcome
            .welcomeTagline:        "Poche parole al giorno.\nRicordate per sempre.",
            .welcomeStart:          "Inizia",
            .welcomeHaveAccount:    "Ho già un account",
            // Paywall
            .paywallSubtitle:       "Porta il tuo apprendimento al livello successivo",
            .paywallFeature1:       "Pratica giornaliera illimitata",
            .paywallFeature2:       "Suggerimenti illimitati",
            .paywallFeature3:       "Quiz IA illimitati",
            .paywallFeature4:       "Coach di conversazione IA illimitato",
            .paywallFeature1Sub:    "Nessun limite giornaliero di domande",
            .paywallFeature2Sub:    "Non restare mai senza suggerimenti",
            .paywallFeature3Sub:    "Crea tutti i quiz IA che vuoi",
            .paywallFeature4Sub:    "Esercita grammatica e pronuncia con l'IA",
            .paywallReviewsTitle:   "Cosa dicono gli utenti?",
            .paywallWeeklyPro:      "Pro settimanale",
            .paywallPerWeek:        "%@ / settimana",
            .paywallRecommended:    "CONSIGLIATO",
            .paywallPriceFailed:    "Prezzo non disponibile",
            .paywallRetry:          "Riprova",
            .paywallContinue:       "Continua",
            .paywallPurchaseFailed: "Acquisto fallito",
            .paywallPurchaseError:  "Si è verificato un errore. Riprova o usa il ripristino.",
            .paywallOk:             "OK",
            .paywallPrivacy:        "Privacy",
            .paywallTerms:          "Termini di utilizzo",
            .paywallRestore:        "Ripristina",
            .paywallDisclosure:     "Il pagamento verrà addebitato sul tuo account Apple alla conferma dell'acquisto. L'abbonamento si rinnova automaticamente a meno che non venga annullato almeno 24 ore prima della fine del periodo corrente. Gestisci gli abbonamenti nelle Impostazioni account dell'App Store.",
            .paywallAnnual: "Annuale",
            .paywallWeeklyPlan: "Settimanale",
            .paywallBestValue: "Più conveniente",
            .paywallSave: "Risparmi il %d%%",
            .paywallPerYear: "%@ / anno",
            .paywallWeeklyEquiv: "Solo %@ a settimana",
            .paywallTrialBadge: "%d giorni gratis",
            .paywallStartTrial: "Prova gratis per %d giorni",
            .paywallTrialThen: "%d giorni gratis, poi %@ / anno. Disdici quando vuoi.",
            .paywallNoCommit: "Nessun vincolo · Disdici quando vuoi",
            .paywallTLToday: "Oggi",
            .paywallTLTodaySub: "Si sbloccano tutti i corsi e le funzioni",
            .paywallTLDay: "Giorno %d",
            .paywallTLReminderSub: "Ti avvisiamo prima della fine della prova",
            .paywallTLChargeSub: "Inizia l'abbonamento e avviene l'addebito",
            .paywallTrialReminderTitle: "La tua prova finisce tra 2 giorni",
            .paywallTrialReminderBody: "Non fa per te? Disdici in Impostazioni › Abbonamenti.",
            // Home
            .homeSearchPlaceholder: "Cerca mazzi...",
            .homeMyDecks:           "I miei mazzi",
            .homeTapToStudy:        "Tocca un mazzo per studiare",
            .homeNoResultsFormat:   "Nessun risultato per \"%@\"",
            .homeNoDecks:           "Ancora nessun mazzo",
            .homeNoDecksHint:       "Usa il pulsante + in basso\nper creare il tuo primo mazzo!",
            // Profile
            .profileTotalXP:        "XP totale",
            .profileStreak:         "Serie",
            .profileDaysFormat:     "%d giorni",
            .profileStatistics:     "Statistiche",
            .profileCompleted:      "Completati",
            .profileQuizzes:        "Quiz",
            .profileAccuracy:       "Precisione",
            .profileLevel:          "Livello",
            .profileLevelFormat:    "Livello %d",
            .profileAchievements:   "Obiettivi",
            .profileFirstStreak:    "Prima serie",
            .profile5Levels:        "5 Livelli",
            .profile100XP:          "100 XP",
            .profileSharpEye:       "Occhio acuto",
            .profile500XP:          "500 XP",
            .profileUpgradePro:     "Passa a Pro",
            .profileSignOut:        "Esci",
            .profileGuest:          "Ospite",
            .profileDeleteAccount:  "Elimina account",
            .profileDeleteTitle:    "Elimina account definitivamente",
            .profileDeleteMessage:  "Questa azione non può essere annullata. Tutti i tuoi dati verranno eliminati definitivamente.",
            .profileDeleteConfirm:  "Sì, elimina",
            .profileDeleteCancel:   "Annulla",
            // Leaderboard
            .leaderboardTitle:      "Classifica",
            .leaderboardSubtitle:   "Sfida altri studenti! 🏆",
            .leaderboardNoPlayers:  "Ancora nessun giocatore",
            .leaderboardNoPlayersHint: "Completa i livelli per entrare in classifica!",
            .leaderboardTryAgain:   "Riprova",
            .leaderboardDayStreak:  "serie di %d giorni",
            // Tabs
            .tabDecks:              "Mazzi",
            .tabPath:               "Percorso",
            .tabTranslate:          "Traduci",
            .tabRank:               "Classifica",
            .tabProfile:            "Profilo",
            // Path
            .pathMistakesFormat:    "Esercita %d errori",
            .pathMistakesUrgent:    "Hai 10+ errori! Esercitati ora 👆",
            .pathUpdating:          "Aggiornamento del progresso...",
            .pathSomethingWrong:    "Qualcosa è andato storto",
            .pathTryAgain:          "Riprova",
            .pathRefresh:           "Aggiorna",
            .pathNoCourses:         "Ancora nessun corso",
            .pathNoCoursesHint:     "Esegui supabase_seed.sql nel\neditor SQL di Supabase.",
            .pathNoCourseForLang:   "Ancora nessun corso per questa lingua",
            .pathNoCourseForLangHint: "I contenuti per la tua lingua\nstanno arrivando. Resta aggiornato!",
            .pathSelectCourse:      "Seleziona un corso",
            .pathStart:             "Inizia",
            .pathMotivation0:       "Continua! Stai andando benissimo 🎯",
            .pathMotivation1:       "Ottimi progressi! Sei fantastico! 🌟",
            .pathMotivation2:       "Quasi arrivato! Continua! 💪",
            .pathMotivation3:       "Sei un maestro! 🏆",
            .pathWellDone:          "Ottimo! 🎉",
            .pathWellDoneDesc:      "Hai completato con successo questo livello e guadagnato XP. Continua così!",
            .pathContinue:          "Continua",
            .pathDontBeSad:         "Non essere triste... 🩹",
            .pathDontBeSadDesc:     "Abbiamo salvato le parole che hai mancato così puoi esercitarti dopo. Continua!",
            .pathGotIt:             "Capito",
            .pathGreatWork:         "Ottimo lavoro! 🌟",
            .pathGreatWorkDesc:     "Hai cancellato tutti gli errori e rafforzato la memoria! Sei fantastico!",
            .pathHooray:            "Urrà!",
            .pathMistakesReview:    "Revisione degli errori",
            // Game
            .gameLoading:           "Caricamento domande…",
            .gameWhatIsMeaning:     "Qual è il significato di questa parola?",
            .gameTypeTranslation:   "Scrivi la traduzione…",
            .gameCheck:             "Verifica",
            .gameOutOfLives:        "Vite esaurite!",
            .gameDontGiveUp:        "Non arrenderti — riprova!",
            .gameTryAgain:          "Riprova",
            .gameQuit:              "Esci",
            .gameQuitTitle:         "Uscire dal quiz?",
            .gameQuitMessage:       "Perderai i tuoi progressi. Solo 1 altro minuto!",
            .gameQuitKeepGoing:     "Continua",
            .dailyLimitTitle:       "Limite giornaliero raggiunto!",
            .dailyLimitSubtitle:    "Hai completato 25 domande oggi.\nTorna domani!",
            .dailyLimitResetsIn:    "Si azzera in:",
            .dailyLimitGetPro:      "Impara senza limiti — Vai Pro",
            .dailyLimitClose:       "Chiudi",
            .gameQuestionFormat:    "Domanda %d / %d",
            .gameCorrect:           "Corretto! 🎉",
            .gameNotQuite:          "Non proprio…",
            .gameContinue:          "Continua",
            // Listening
            .gameListenPrompt:      "Ascolta la parola, scegli il significato corretto",
            .gameListenNormal:      "Ascolta",
            .gameListenSlow:        "Ascolta lentamente",
            .gameListenCantHear:    "Non riesci a sentire?",
            // Speaking
            .gameSpeakPrompt:       "Guarda la parola e dilla ad alta voce",
            .gameSpeakMicHint:      "Tocca il microfono e parla",
            .gameSpeakCantSpeak:    "Non riesci a parlare? Salta",
            .gameSpeakListening:    "In ascolto…",
            .gameSpeakNoPermission: "Autorizzazione microfono richiesta",
            // Result
            .resultLevelComplete:   "Livello completato!",
            .resultKeepPracticing:  "Continua ad esercitarti!",
            .resultScore:           "Punteggio",
            .resultXPEarned:        "XP guadagnato",
            .resultContinue:        "Continua",
            .resultTryAgain:        "Riprova",
            // Profile - Guest & Username
            .profileSaveProgress:       "Salva i tuoi progressi",
            .profileSaveProgressHint:   "Crea un account, tieni tutto al sicuro",
            .profileSaveProgressDesc:   "Crea un account per mantenere XP, serie e progressi al sicuro. Anche se elimini l'app, tutto rimane intatto.",
            .profileLoginApple:         "Continua con Apple",
            .profileLoginGoogle:        "Continua con Google",
            .profileLoginEmail:         "Registrati con email",
            .profileClose:              "Chiudi",
            .profileSave:               "Salva",
            .profileSetUsername:        "Come vuoi chiamarti?",
            .profileChangeUsername:     "Cambia il tuo nome utente",
            .profileUsernameLeaderboard: "Questo nome apparirà nella classifica e nel tuo profilo.",
            .profileUsernameOneChange:  "Puoi usare questo diritto solo una volta.\nViene aggiornato nella classifica e nel tuo profilo.",
            .profileUsernamePlaceholder: "Nome utente (min. 3 caratteri)",
            // Leaderboard - Guest
            .leaderboardJoinTitle:      "Unisciti alla classifica! 🏆",
            .leaderboardJoinDesc:       "Devi accedere per vedere la classifica\ne partecipare.",
            .leaderboardSignIn:         "Accedi",
            // Home - Empty state
            .homeCreateFirstDeck:       "Crea il tuo primo mazzo! 🎉",
            .homeCreateFirstDeckHint:   "Aggiungi le tue parole, Reeny è pronto\na studiare con te!",
            .homeCreateDeck:            "Crea mazzo",
            // Path - Unit & Status
            .pathUnitFormat:            "Unità %d",
            .pathLevelProgressFormat:   "%d/%d livelli",
            .pathStatusCompleted:       "Completato",
            .pathStatusInProgress:      "In corso",
            .pathStatusLocked:          "Bloccato",
            .homeLoadingDecks:          "Caricamento dei tuoi mazzi, un attimo! 🐾",
            .gameHintTitle:             "Suggerimento",
            .gameHintRemainingFormat:   "%d suggerimenti rimasti",
            .gameHintGotIt:             "Capito, Continua",
            .gameFillBlank:             "Riempi lo spazio",
            .gameTranslateLabel:        "Traduci:",
            .gameLoadingAudio:          "Caricamento...",
            .gameWordQuestionFormat:    "Qual è la parola %@?",
            .streakStartedTitle:   "Hai iniziato una serie! 🔥",
            .streakContinuedTitle: "Serie di %d giorni! 🔥",
            .streakSubtitle:       "Il tuo viaggio linguistico inizia oggi! Continua e raggiungi i tuoi obiettivi.",
            .navSettings:          "Impostazioni",
            .navExampleSentences:  "Frasi di esempio",
            .streakContinue:       "Continua",
            .welcomeNewTitle:      "Benvenuto su WordRem! 🎉",
            .welcomeNewSubtitle:   "Il modo più intelligente per imparare le lingue",
            .welcomeNewFeature1:   "⚡ Quiz veloci e divertenti",
            .welcomeNewFeature2:   "🔥 Rimani motivato con le serie",
            .welcomeNewFeature3:   "🏆 Scala la classifica",
            .welcomeNewCTA:        "Iniziamo!",
            .welcomeBackTitle:     "Bentornato! 👋",
            .welcomeBackMessageFormat: "Ci sei mancato tanto, %@!",
            .welcomeBackMotivation:    "È ora di continuare verso i tuoi obiettivi 💪",
            .welcomeBackCTA:       "Continua",
            .welcomeProTitle:      "Benvenuto in WordRem Pro! 👑",
            .welcomeProSubtitle:   "Tutte le funzioni premium sono sbloccate",
            .welcomeProFeature1:   "Domande giornaliere illimitate",
            .welcomeProFeature2:   "Utilizzo illimitato dei suggerimenti",
            .welcomeProFeature3:   "Apprendimento con intelligenza artificiale",
            .welcomeProCTA:        "Inizia ad imparare!",
            .dailyBreakTitle:        "Obiettivo giornaliero raggiunto! ☕",
            .dailyBreakBodyFormat:   "Hai praticato per %d minuti oggi. Ottimo lavoro!",
            .dailyBreakSubtitle:     "Puoi fare una pausa — ma continuare è una tua scelta.",
            .dailyBreakRest:         "Fai una pausa",
            .dailyBreakContinue:     "Continua",
        ],

        // ─────────────────────────────────────────
        "ru": [
            // Welcome
            .welcomeTagline:        "Несколько слов в день.\nНавсегда.",
            .welcomeStart:          "Начать",
            .welcomeHaveAccount:    "У меня уже есть аккаунт",
            // Paywall
            .paywallSubtitle:       "Подними своё обучение на новый уровень",
            .paywallFeature1:       "Безлимитная ежедневная практика",
            .paywallFeature2:       "Безлимитные подсказки",
            .paywallFeature3:       "Безлимитные ИИ-квизы",
            .paywallFeature4:       "Безлимитный ИИ-тренер речи",
            .paywallFeature1Sub:    "Без дневного лимита вопросов",
            .paywallFeature2Sub:    "Подсказки никогда не закончатся",
            .paywallFeature3Sub:    "Создавай сколько угодно ИИ-квизов",
            .paywallFeature4Sub:    "Тренируй грамматику и произношение с ИИ",
            .paywallReviewsTitle:   "Что говорят пользователи?",
            .paywallWeeklyPro:      "Еженедельный Pro",
            .paywallPerWeek:        "%@ / неделю",
            .paywallRecommended:    "РЕКОМЕНДУЕТСЯ",
            .paywallPriceFailed:    "Цена недоступна",
            .paywallRetry:          "Повторить",
            .paywallContinue:       "Продолжить",
            .paywallPurchaseFailed: "Покупка не удалась",
            .paywallPurchaseError:  "Произошла ошибка. Повторите или используйте восстановление.",
            .paywallOk:             "ОК",
            .paywallPrivacy:        "Конфиденциальность",
            .paywallTerms:          "Условия использования",
            .paywallRestore:        "Восстановить",
            .paywallDisclosure:     "Оплата будет снята с вашего аккаунта Apple при подтверждении покупки. Подписка автоматически продлевается, если не будет отменена не менее чем за 24 часа до окончания текущего периода. Управляйте подписками в настройках аккаунта App Store.",
            .paywallAnnual: "Годовой",
            .paywallWeeklyPlan: "Недельный",
            .paywallBestValue: "Выгоднее всего",
            .paywallSave: "Экономия %d%%",
            .paywallPerYear: "%@ / год",
            .paywallWeeklyEquiv: "Всего %@ в неделю",
            .paywallTrialBadge: "%d дней бесплатно",
            .paywallStartTrial: "Попробовать %d дней бесплатно",
            .paywallTrialThen: "%d дней бесплатно, затем %@ / год. Отмена в любой момент.",
            .paywallNoCommit: "Без обязательств · Отмена в любой момент",
            .paywallTLToday: "Сегодня",
            .paywallTLTodaySub: "Открываются все курсы и функции",
            .paywallTLDay: "День %d",
            .paywallTLReminderSub: "Напомним до окончания пробного периода",
            .paywallTLChargeSub: "Начинается подписка, списывается оплата",
            .paywallTrialReminderTitle: "Пробный период закончится через 2 дня",
            .paywallTrialReminderBody: "Не подошло? Отмените в Настройки › Подписки.",
            // Home
            .homeSearchPlaceholder: "Поиск колод...",
            .homeMyDecks:           "Мои колоды",
            .homeTapToStudy:        "Нажми на колоду для изучения",
            .homeNoResultsFormat:   "Нет результатов для \"%@\"",
            .homeNoDecks:           "Пока нет колод",
            .homeNoDecksHint:       "Нажми кнопку + внизу,\nчтобы создать первую колоду!",
            // Profile
            .profileTotalXP:        "Всего XP",
            .profileStreak:         "Серия",
            .profileDaysFormat:     "%d дней",
            .profileStatistics:     "Статистика",
            .profileCompleted:      "Завершено",
            .profileQuizzes:        "Викторины",
            .profileAccuracy:       "Точность",
            .profileLevel:          "Уровень",
            .profileLevelFormat:    "Уровень %d",
            .profileAchievements:   "Достижения",
            .profileFirstStreak:    "Первая серия",
            .profile5Levels:        "5 уровней",
            .profile100XP:          "100 XP",
            .profileSharpEye:       "Острый глаз",
            .profile500XP:          "500 XP",
            .profileUpgradePro:     "Перейти на Pro",
            .profileSignOut:        "Выйти",
            .profileGuest:          "Гость",
            .profileDeleteAccount:  "Удалить аккаунт",
            .profileDeleteTitle:    "Удалить аккаунт навсегда",
            .profileDeleteMessage:  "Это действие невозможно отменить. Все ваши данные будут удалены навсегда.",
            .profileDeleteConfirm:  "Да, удалить",
            .profileDeleteCancel:   "Отмена",
            // Leaderboard
            .leaderboardTitle:      "Таблица лидеров",
            .leaderboardSubtitle:   "Соревнуйся с другими учениками! 🏆",
            .leaderboardNoPlayers:  "Пока нет игроков",
            .leaderboardNoPlayersHint: "Завершай уровни, чтобы войти в таблицу лидеров!",
            .leaderboardTryAgain:   "Повторить",
            .leaderboardDayStreak:  "серия %d дней",
            // Tabs
            .tabDecks:              "Колоды",
            .tabPath:               "Путь",
            .tabTranslate:          "Перевод",
            .tabRank:               "Рейтинг",
            .tabProfile:            "Профиль",
            // Path
            .pathMistakesFormat:    "Проработать %d ошибок",
            .pathMistakesUrgent:    "У тебя 10+ ошибок! Повтори сейчас 👆",
            .pathUpdating:          "Обновление прогресса...",
            .pathSomethingWrong:    "Что-то пошло не так",
            .pathTryAgain:          "Повторить",
            .pathRefresh:           "Обновить",
            .pathNoCourses:         "Пока нет курсов",
            .pathNoCoursesHint:     "Запусти supabase_seed.sql в\nредакторе SQL Supabase.",
            .pathNoCourseForLang:   "Пока нет курсов для этого языка",
            .pathNoCourseForLangHint: "Контент для твоего языка\nуже в пути. Следи за обновлениями!",
            .pathSelectCourse:      "Выбрать курс",
            .pathStart:              "Старт",
            .pathMotivation0:       "Продолжай! Ты молодец 🎯",
            .pathMotivation1:       "Отличный прогресс! Ты потрясающий! 🌟",
            .pathMotivation2:       "Почти там! Продолжай! 💪",
            .pathMotivation3:       "Ты мастер! 🏆",
            .pathWellDone:          "Отлично! 🎉",
            .pathWellDoneDesc:      "Ты успешно завершил этот уровень и заработал XP. Продолжай в том же духе!",
            .pathContinue:          "Продолжить",
            .pathDontBeSad:         "Не грусти... 🩹",
            .pathDontBeSadDesc:     "Мы сохранили слова, которые ты пропустил, чтобы ты мог потренироваться позже. Продолжай!",
            .pathGotIt:             "Понял",
            .pathGreatWork:         "Отличная работа! 🌟",
            .pathGreatWorkDesc:     "Ты устранил все ошибки и укрепил память! Ты потрясающий!",
            .pathHooray:            "Ура!",
            .pathMistakesReview:    "Работа над ошибками",
            // Game
            .gameLoading:           "Загрузка вопросов…",
            .gameWhatIsMeaning:     "Что означает это слово?",
            .gameTypeTranslation:   "Введи перевод…",
            .gameCheck:             "Проверить",
            .gameOutOfLives:        "Жизни кончились!",
            .gameDontGiveUp:        "Не сдавайся — попробуй ещё раз!",
            .gameTryAgain:          "Повторить",
            .gameQuit:              "Выйти",
            .gameQuitTitle:         "Выйти из викторины?",
            .gameQuitMessage:       "Ты потеряешь прогресс. Ещё 1 минута!",
            .gameQuitKeepGoing:     "Продолжить",
            .dailyLimitTitle:       "Дневной лимит исчерпан!",
            .dailyLimitSubtitle:    "Сегодня ты ответил на 25 вопросов.\nВозвращайся завтра!",
            .dailyLimitResetsIn:    "Сбросится через:",
            .dailyLimitGetPro:      "Учись без ограничений — Перейти на Pro",
            .dailyLimitClose:       "Закрыть",
            .gameQuestionFormat:    "Вопрос %d / %d",
            .gameCorrect:           "Верно! 🎉",
            .gameNotQuite:          "Не совсем…",
            .gameContinue:          "Продолжить",
            // Listening
            .gameListenPrompt:      "Послушай слово, выбери правильное значение",
            .gameListenNormal:      "Слушать",
            .gameListenSlow:        "Слушать медленно",
            .gameListenCantHear:    "Не слышишь?",
            // Speaking
            .gameSpeakPrompt:       "Посмотри на слово и произнеси его вслух",
            .gameSpeakMicHint:      "Нажми на микрофон и говори",
            .gameSpeakCantSpeak:    "Не можешь говорить? Пропустить",
            .gameSpeakListening:    "Слушаю…",
            .gameSpeakNoPermission: "Требуется разрешение на микрофон",
            // Result
            .resultLevelComplete:   "Уровень пройден!",
            .resultKeepPracticing:  "Продолжай тренироваться!",
            .resultScore:           "Счёт",
            .resultXPEarned:        "Получено XP",
            .resultContinue:        "Продолжить",
            .resultTryAgain:        "Повторить",
            // Profile - Guest & Username
            .profileSaveProgress:       "Сохрани прогресс",
            .profileSaveProgressHint:   "Создай аккаунт, чтобы всё было в безопасности",
            .profileSaveProgressDesc:   "Создай аккаунт, чтобы сохранить XP, серии и весь прогресс. Даже после удаления приложения — всё останется.",
            .profileLoginApple:         "Продолжить с Apple",
            .profileLoginGoogle:        "Продолжить с Google",
            .profileLoginEmail:         "Зарегистрироваться по email",
            .profileClose:              "Закрыть",
            .profileSave:               "Сохранить",
            .profileSetUsername:        "Как тебя называть?",
            .profileChangeUsername:     "Изменить имя пользователя",
            .profileUsernameLeaderboard: "Это имя появится в таблице лидеров и твоём профиле.",
            .profileUsernameOneChange:  "Это право можно использовать только один раз.\nБудет обновлено в таблице лидеров и профиле.",
            .profileUsernamePlaceholder: "Имя пользователя (мин. 3 символа)",
            // Leaderboard - Guest
            .leaderboardJoinTitle:      "Присоединяйся к таблице! 🏆",
            .leaderboardJoinDesc:       "Войди, чтобы увидеть таблицу лидеров\nи участвовать.",
            .leaderboardSignIn:         "Войти",
            // Home - Empty state
            .homeCreateFirstDeck:       "Создай свою первую колоду! 🎉",
            .homeCreateFirstDeckHint:   "Добавь слова, Reeny готов\nучиться вместе с тобой!",
            .homeCreateDeck:            "Создать колоду",
            // Path - Unit & Status
            .pathUnitFormat:            "Блок %d",
            .pathLevelProgressFormat:   "%d/%d уровней",
            .pathStatusCompleted:       "Завершено",
            .pathStatusInProgress:      "В процессе",
            .pathStatusLocked:          "Заблокировано",
            .homeLoadingDecks:          "Загружаем ваши колоды, подождите! 🐾",
            .gameHintTitle:             "Подсказка",
            .gameHintRemainingFormat:   "Осталось %d подсказок",
            .gameHintGotIt:             "Понял, Продолжить",
            .gameFillBlank:             "Заполните пропуск",
            .gameTranslateLabel:        "Перевести:",
            .gameLoadingAudio:          "Загрузка...",
            .gameWordQuestionFormat:    "Какое слово на %@?",
            .streakStartedTitle:   "Вы начали серию! 🔥",
            .streakContinuedTitle: "Серия %d дней! 🔥",
            .streakSubtitle:       "Ваш языковой путь начинается сегодня! Продолжайте и достигайте целей.",
            .navSettings:          "Настройки",
            .navExampleSentences:  "Примеры предложений",
            .streakContinue:       "Продолжить",
            .welcomeNewTitle:      "Добро пожаловать в WordRem! 🎉",
            .welcomeNewSubtitle:   "Самый умный способ учить языки",
            .welcomeNewFeature1:   "⚡ Быстрые и весёлые тесты",
            .welcomeNewFeature2:   "🔥 Оставайся мотивированным с сериями",
            .welcomeNewFeature3:   "🏆 Поднимайся в таблице лидеров",
            .welcomeNewCTA:        "Начнём!",
            .welcomeBackTitle:     "С возвращением! 👋",
            .welcomeBackMessageFormat: "Мы так скучали по тебе, %@!",
            .welcomeBackMotivation:    "Время продолжить к своим целям 💪",
            .welcomeBackCTA:       "Продолжить",
            .welcomeProTitle:      "Добро пожаловать в WordRem Pro! 👑",
            .welcomeProSubtitle:   "Все премиум-функции разблокированы",
            .welcomeProFeature1:   "Неограниченные ежедневные вопросы",
            .welcomeProFeature2:   "Неограниченное использование подсказок",
            .welcomeProFeature3:   "Обучение с ИИ",
            .welcomeProCTA:        "Начать обучение!",
            .dailyBreakTitle:        "Дневная цель достигнута! ☕",
            .dailyBreakBodyFormat:   "Сегодня ты занимался(ась) %d минут. Отлично!",
            .dailyBreakSubtitle:     "Ты можешь сделать перерыв — но продолжать — это твой выбор.",
            .dailyBreakRest:         "Сделать перерыв",
            .dailyBreakContinue:     "Продолжить",
        ],

        // ─────────────────────────────────────────
        "zh": [
            // Welcome
            .welcomeTagline:        "每天几个单词。\n牢记于心。",
            .welcomeStart:          "开始",
            .welcomeHaveAccount:    "我已有账户",
            // Paywall
            .paywallSubtitle:       "将你的学习提升到新高度",
            .paywallFeature1:       "无限每日练习",
            .paywallFeature2:       "无限提示",
            .paywallFeature3:       "无限 AI 测验",
            .paywallFeature4:       "无限 AI 口语教练",
            .paywallFeature1Sub:    "没有每日题目限制",
            .paywallFeature2Sub:    "卡住时提示永远用不完",
            .paywallFeature3Sub:    "随心创建 AI 测验",
            .paywallFeature4Sub:    "用 AI 练习语法和发音",
            .paywallReviewsTitle:   "用户怎么说？",
            .paywallWeeklyPro:      "每周Pro",
            .paywallPerWeek:        "%@ / 周",
            .paywallRecommended:    "推荐",
            .paywallPriceFailed:    "价格不可用",
            .paywallRetry:          "重试",
            .paywallContinue:       "继续",
            .paywallPurchaseFailed: "购买失败",
            .paywallPurchaseError:  "发生错误。请重试或使用恢复购买。",
            .paywallOk:             "好",
            .paywallPrivacy:        "隐私",
            .paywallTerms:          "使用条款",
            .paywallRestore:        "恢复购买",
            .paywallDisclosure:     "购买确认后，将从您的Apple账户扣款。订阅将自动续订，除非在当前期限结束前至少24小时取消。可在App Store账户设置中管理订阅。",
            .paywallAnnual: "年度",
            .paywallWeeklyPlan: "每周",
            .paywallBestValue: "最超值",
            .paywallSave: "节省 %d%%",
            .paywallPerYear: "%@ / 年",
            .paywallWeeklyEquiv: "每周仅 %@",
            .paywallTrialBadge: "免费 %d 天",
            .paywallStartTrial: "免费试用 %d 天",
            .paywallTrialThen: "免费 %d 天，之后 %@ / 年。可随时取消。",
            .paywallNoCommit: "无需承诺 · 随时取消",
            .paywallTLToday: "今天",
            .paywallTLTodaySub: "解锁全部课程和功能",
            .paywallTLDay: "第 %d 天",
            .paywallTLReminderSub: "试用结束前我们会提醒你",
            .paywallTLChargeSub: "订阅开始并扣费",
            .paywallTrialReminderTitle: "你的免费试用将在 2 天后结束",
            .paywallTrialReminderBody: "不适合你？可在 设置 › 订阅 中取消。",
            // Home
            .homeSearchPlaceholder: "搜索卡组...",
            .homeMyDecks:           "我的卡组",
            .homeTapToStudy:        "点击卡组开始学习",
            .homeNoResultsFormat:   "没有的结果",
            .homeNoDecks:           "还没有卡组",
            .homeNoDecksHint:       "使用下方的+按钮\n创建你的第一个卡组！",
            // Profile
            .profileTotalXP:        "总XP",
            .profileStreak:         "连续",
            .profileDaysFormat:     "%d天",
            .profileStatistics:     "统计",
            .profileCompleted:      "已完成",
            .profileQuizzes:        "测验",
            .profileAccuracy:       "准确率",
            .profileLevel:          "等级",
            .profileLevelFormat:    "等级 %d",
            .profileAchievements:   "成就",
            .profileFirstStreak:    "首次连续",
            .profile5Levels:        "5个等级",
            .profile100XP:          "100 XP",
            .profileSharpEye:       "火眼金睛",
            .profile500XP:          "500 XP",
            .profileUpgradePro:     "升级Pro",
            .profileSignOut:        "退出登录",
            .profileGuest:          "访客",
            .profileDeleteAccount:  "删除账户",
            .profileDeleteTitle:    "永久删除账户",
            .profileDeleteMessage:  "此操作无法撤销。您的所有数据（进度、XP、卡组）将被永久删除。",
            .profileDeleteConfirm:  "是，删除",
            .profileDeleteCancel:   "取消",
            // Leaderboard
            .leaderboardTitle:      "排行榜",
            .leaderboardSubtitle:   "与其他学习者竞争！🏆",
            .leaderboardNoPlayers:  "还没有玩家",
            .leaderboardNoPlayersHint: "完成关卡加入排行榜！",
            .leaderboardTryAgain:   "重试",
            .leaderboardDayStreak:  "%d天连续",
            // Tabs
            .tabDecks:              "卡组",
            .tabPath:               "路径",
            .tabTranslate:          "翻译",
            .tabRank:               "排名",
            .tabProfile:            "个人",
            // Path
            .pathMistakesFormat:    "练习%d个错误",
            .pathMistakesUrgent:    "你有10+个错误！现在练习 👆",
            .pathUpdating:          "更新进度中...",
            .pathSomethingWrong:    "出了点问题",
            .pathTryAgain:          "重试",
            .pathRefresh:           "刷新",
            .pathNoCourses:         "还没有课程",
            .pathNoCoursesHint:     "在Supabase SQL编辑器中\n运行supabase_seed.sql。",
            .pathNoCourseForLang:   "暂无该语言的课程",
            .pathNoCourseForLangHint: "你所选语言的内容即将上线。\n敬请期待！",
            .pathSelectCourse:      "选择课程",
            .pathStart:             "开始",
            .pathMotivation0:       "继续！你做得很好 🎯",
            .pathMotivation1:       "进步很大！你太棒了！🌟",
            .pathMotivation2:       "快到了！继续加油！💪",
            .pathMotivation3:       "你是大师！🏆",
            .pathWellDone:          "干得好！🎉",
            .pathWellDoneDesc:      "你成功完成了这个关卡并获得了XP。继续保持！",
            .pathContinue:          "继续",
            .pathDontBeSad:         "别伤心...🩹",
            .pathDontBeSadDesc:     "我们保存了你错过的单词，方便你之后练习。继续加油！",
            .pathGotIt:             "明白了",
            .pathGreatWork:         "太棒了！🌟",
            .pathGreatWorkDesc:     "你清除了所有错误并巩固了记忆！你太厉害了！",
            .pathHooray:            "万岁！",
            .pathMistakesReview:    "错误复习",
            // Game
            .gameLoading:           "加载题目中…",
            .gameWhatIsMeaning:     "这个单词是什么意思？",
            .gameTypeTranslation:   "输入翻译…",
            .gameCheck:             "检查",
            .gameOutOfLives:        "没有生命了！",
            .gameDontGiveUp:        "别放弃——再试一次！",
            .gameTryAgain:          "重试",
            .gameQuit:              "退出",
            .gameQuitTitle:         "退出测验？",
            .gameQuitMessage:       "你将失去进度。再坚持1分钟！",
            .gameQuitKeepGoing:     "继续",
            .dailyLimitTitle:       "已达每日上限！",
            .dailyLimitSubtitle:    "你今天已完成25道题。\n明天再来吧！",
            .dailyLimitResetsIn:    "重置倒计时：",
            .dailyLimitGetPro:      "无限学习 — 升级Pro",
            .dailyLimitClose:       "关闭",
            .gameQuestionFormat:    "题目 %d / %d",
            .gameCorrect:           "正确！🎉",
            .gameNotQuite:          "不太对…",
            .gameContinue:          "继续",
            // Listening
            .gameListenPrompt:      "听单词，选择正确的意思",
            .gameListenNormal:      "播放",
            .gameListenSlow:        "慢速播放",
            .gameListenCantHear:    "听不见？",
            // Speaking
            .gameSpeakPrompt:       "看单词并大声说出来",
            .gameSpeakMicHint:      "点击麦克风并说话",
            .gameSpeakCantSpeak:    "无法说话？跳过",
            .gameSpeakListening:    "正在聆听…",
            .gameSpeakNoPermission: "需要麦克风权限",
            // Result
            .resultLevelComplete:   "关卡完成！",
            .resultKeepPracticing:  "继续练习！",
            .resultScore:           "分数",
            .resultXPEarned:        "获得XP",
            .resultContinue:        "继续",
            .resultTryAgain:        "重试",
            // Profile - Guest & Username
            .profileSaveProgress:       "保存你的进度",
            .profileSaveProgressHint:   "创建账户，保持一切安全",
            .profileSaveProgressDesc:   "创建账户以保护你的XP、连续记录和所有进度。即使删除应用，一切都会保持完好。",
            .profileLoginApple:         "使用Apple继续",
            .profileLoginGoogle:        "使用Google继续",
            .profileLoginEmail:         "使用邮箱注册",
            .profileClose:              "关闭",
            .profileSave:               "保存",
            .profileSetUsername:        "你的用户名是什么？",
            .profileChangeUsername:     "更改用户名",
            .profileUsernameLeaderboard: "此名称将显示在排行榜和你的个人资料上。",
            .profileUsernameOneChange:  "你只能使用这个权利一次。\n将在排行榜和个人资料中更新。",
            .profileUsernamePlaceholder: "用户名（最少3个字符）",
            // Leaderboard - Guest
            .leaderboardJoinTitle:      "加入排行榜！🏆",
            .leaderboardJoinDesc:       "你需要登录才能查看排行榜\n并加入排名。",
            .leaderboardSignIn:         "登录",
            // Home - Empty state
            .homeCreateFirstDeck:       "创建你的第一个卡组！🎉",
            .homeCreateFirstDeckHint:   "添加你的单词，Reeny准备好\n和你一起学习了！",
            .homeCreateDeck:            "创建卡组",
            // Path - Unit & Status
            .pathUnitFormat:            "单元 %d",
            .pathLevelProgressFormat:   "%d/%d 关卡",
            .pathStatusCompleted:       "已完成",
            .pathStatusInProgress:      "进行中",
            .pathStatusLocked:          "已锁定",
            .homeLoadingDecks:          "正在加载你的卡组，请稍候！🐾",
            .gameHintTitle:             "提示",
            .gameHintRemainingFormat:   "剩余 %d 个提示",
            .gameHintGotIt:             "明白了，继续",
            .gameFillBlank:             "填写空白",
            .gameTranslateLabel:        "翻译：",
            .gameLoadingAudio:          "加载中...",
            .gameWordQuestionFormat:    "%@ 这个词是什么？",
            .streakStartedTitle:   "你开启了连续学习！🔥",
            .streakContinuedTitle: "连续 %d 天！🔥",
            .streakSubtitle:       "你的语言之旅今天开始！继续前进，实现你的目标。",
            .navSettings:          "设置",
            .navExampleSentences:  "例句",
            .streakContinue:       "继续",
            .welcomeNewTitle:      "欢迎来到 WordRem！🎉",
            .welcomeNewSubtitle:   "学习语言最聪明的方式",
            .welcomeNewFeature1:   "⚡ 快速有趣的测验",
            .welcomeNewFeature2:   "🔥 用连续学习保持动力",
            .welcomeNewFeature3:   "🏆 登上排行榜",
            .welcomeNewCTA:        "开始吧！",
            .welcomeBackTitle:     "欢迎回来！👋",
            .welcomeBackMessageFormat: "我们太想念你了，%@！",
            .welcomeBackMotivation:    "是时候继续实现你的目标了 💪",
            .welcomeBackCTA:       "继续",
            .welcomeProTitle:      "欢迎加入 WordRem Pro！👑",
            .welcomeProSubtitle:   "所有高级功能现已解锁",
            .welcomeProFeature1:   "无限每日问题",
            .welcomeProFeature2:   "无限使用提示",
            .welcomeProFeature3:   "AI 驱动学习",
            .welcomeProCTA:        "开始学习！",
            .dailyBreakTitle:        "达成每日目标！☕",
            .dailyBreakBodyFormat:   "你今天已练习了 %d 分钟，干得好！",
            .dailyBreakSubtitle:     "你可以休息一下——但是否继续完全取决于你。",
            .dailyBreakRest:         "休息一下",
            .dailyBreakContinue:     "继续学习",
        ],
    ]
    // swiftlint:enable line_length
}
