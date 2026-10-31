//
//  ProfileView.swift
//  WordRemSwiftUI
//

import SwiftUI
import GameKit

struct ProfileView: View {
    /// Ortak üst satırdaki kupa
    var onOpenLeaderboard: () -> Void = {}

    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.openURL) private var openURL
    @StateObject private var vm = ProfileScreenViewModel()
    @ObservedObject private var iap = InAppPurchaseManager.shared
    @ObservedObject private var gameCenter = GameCenterService.shared
    @State private var showPaywall = false
    @State private var voiceEngine = VoiceEngineChoice.current
    @State private var showPrivacy = false
    @State private var showTerms = false
    #if DEBUG
    @State private var showStudio = false
    #endif
    @State private var showManageSubscription = false
    @State private var showUsernameSetup = false
    @State private var showSettings = false
    @State private var nativeOpen = false
    // Ayarlar (Lupa ve uygulama tercihleri)
    @AppStorage(TutorPrefs.speedKey) private var prefSpeed = 1
    @AppStorage(TutorPrefs.cefrKey) private var prefCEFR = -1
    @AppStorage(TutorPrefs.correctionsKey) private var prefCorrections = 0
    @AppStorage(TutorPrefs.alwaysTranslateKey) private var prefTranslate = false
    @AppStorage(TutorPrefs.hapticsKey) private var prefHaptics = true
    @AppStorage(TutorPrefs.penKey) private var prefPen = true
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                AppHeader(onOpenLeaderboard: onOpenLeaderboard)
                    .padding(.horizontal, -4)
                coverSection
                reportList
                weekSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            // Alt menünün altında kalmasın
            .padding(.bottom, 120)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        // Kaydırınca içerik saat/pil satırının altına girmesin
        .overlay(alignment: .top) {
            DS.Colors.paper.frame(height: 0).ignoresSafeArea(edges: .top)
        }
        .paperBackground()
        .navigationBarHidden(true)
        .task { await vm.loadProfile() }
        // Ayarlar: sağ üstteki yuvarlak düğmeyle alttan gelen sayfa
        .sheet(isPresented: $showSettings) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    settingsSection
                    accountSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(DS.Colors.paper)
        }
        .sheet(isPresented: $showPrivacy) {
            SafariWebView(url: URL(string: "https://api.wordremai.app/privacy")!)
        }
        .sheet(isPresented: $showTerms) {
            SafariWebView(url: URL(string: "https://api.wordremai.app/terms")!)
        }
        #if DEBUG
        .sheet(isPresented: $showStudio) {
            NavigationStack {
                let scripts = StudioDirector.scripts()
                List(scripts) { s in
                    Button {
                        showStudio = false
                        // Kayıt izni penceresi sayfa kapandıktan sonra açılsın
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { StudioDirector.shared.arm(s) }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(s.id) · \(s.title)").font(.body.weight(.semibold))
                            Text("\(s.lines.count) replik · \(s.mode ?? "freechat")").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .overlay { if scripts.isEmpty { Text("Documents/studio içinde senaryo yok").foregroundStyle(.secondary) } }
                .navigationTitle("Stüdyo")
                .safeAreaInset(edge: .bottom) {
                    Text("Seçince iOS kayıt izni sorar: \"Ekranı Kaydet\"e dokun. Ders kendiliğinden açılır, oynar ve kaydedilir.")
                        .font(.footnote).foregroundStyle(.secondary).padding()
                }
            }
        }
        #endif
        // Apple'ın kendi abonelik ekranı: plan değiştirme / iptal
        .manageSubscriptionsSheet(isPresented: $showManageSubscription)
        .fullScreenCover(isPresented: $showUsernameSetup) {
            UsernameSetupPopup(
                initialUsername: vm.username,
                isFirstSetup: (vm.user?.usernameChanges ?? 0) == 0,
                onDismiss: { showUsernameSetup = false },
                onSave: { newName in
                    Task {
                        await vm.updateUsername(newName)
                        showUsernameSetup = false
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView(onContinue: { showPaywall = false }, entryPoint: "profile")
        }
        // Profil sekmesine her dönüşte (ör. quiz sonrası) güncel ilerlemeyi göster
        .onReceive(NotificationCenter.default.publisher(for: UserStore.didChangeNotification)) { _ in
            Task { await vm.loadProfile() }
        }
    }

    // MARK: - Kapak: profil senin defterinin kapağı
    // Etikette adın, dilin, seviyen ve sayfan; kapağa kazınmış seri çentikleri; köşede altın Pro çıkartması;
    // sağ üstte ayarlar (alttan gelen sayfa).
    private var coverSection: some View {
        let code = LearningLanguages.current
        let language = OL.languageName(for: code).capitalized(with: Locale(identifier: OL.nativeLangCode))
        let done = LearningLanguages.doneCount(code)
        let inLevel = done % 5
        let level = LearningLanguages.level(code)
        let pages = NotebookStore.shared.pages(for: code).count
        let streak = vm.user?.streakDays ?? 0
        let shape = UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6, bottomTrailingRadius: 18, topTrailingRadius: 18)
        return ZStack(alignment: .topLeading) {
            NotebookCover().clipShape(shape)

            // Etiket
            VStack(alignment: .leading, spacing: 0) {
                Text(ProfileText.thisNotebook)
                    .font(DS.Font.ui(10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(DS.Colors.muted)
                HStack(spacing: 4) {
                    Text(vm.username)
                        .font(DS.Font.display(26, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                    Button { showUsernameSetup = true } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(loc(["Adını değiştir", "Change name", "Namen ändern", "Changer de nom", "Cambiar nombre", "Cambia nome", "Изменить имя", "更改名字"]))
                }
                .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
                Text("\(language) · \(LearningText.level(level)) · \(ProfileText.page(pages))")
                    .font(DS.Font.ui(12, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.top, 8)
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Capsule().fill(i < inLevel ? DS.Colors.accent : DS.Colors.line).frame(height: 5)
                    }
                }
                .padding(.top, 8)
                Text(ProfileText.toNext(5 - inLevel, level + 1))
                    .font(.system(size: 12, design: .serif).italic())
                    .foregroundStyle(DS.Colors.inkSoft)
                    .padding(.top, 5)
                leaderboardNameRow
                    .padding(.top, 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(DS.Colors.paper, in: RoundedRectangle(cornerRadius: 8))
            .rotationEffect(.degrees(-1))
            .shadow(color: .black.opacity(0.22), radius: 12, y: 8)
            .padding(.leading, 40)
            .padding(.trailing, 34)
            .padding(.top, 62)

            // Kapağa kazınmış seri
            HStack(spacing: 10) {
                TallyMarks(count: streak, color: DS.Colors.paper, accentLast: DS.Colors.margin, height: 20, maxShown: 10)
                Text("\(streak) \(ProfileText.streak)")
                    .font(DS.Font.ui(12, weight: .medium))
                    .foregroundStyle(Color(hex: "#E5ECEF"))
            }
            .frame(maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading, 40)
            .padding(.bottom, 20)
        }
        .frame(height: 330)
        // Ayraçlar ve ayarlar düğmesi (sağ üst)
        .overlay(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 14) {
                BookmarkMark(width: 10, colors: [DS.Colors.ink, DS.Colors.accent, DS.Colors.paper, DS.Colors.margin])
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(DS.Colors.paperRaised)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.14), in: Circle())
                }
                .accessibilityLabel(LearningText.settings)
                .padding(.top, 10)
            }
            .padding(.trailing, 12)
        }
        // Altın Pro çıkartması
        .overlay(alignment: .bottomTrailing) { proSticker.padding(14) }
        .shadow(color: Color(red: 0.24, green: 0.16, blue: 0.08).opacity(0.16), radius: 14, y: 10)
    }

    /// Kapağa yapıştırılmış altın çıkartma: Pro değilse "Pro'ya geç" düğmesi (hafifçe sallanır), Pro'ysa mühür
    @ViewBuilder
    private var proSticker: some View {
        if iap.isPremium {
            Button { showManageSubscription = true } label: {
                VStack(spacing: 1) {
                    Text("PRO").font(DS.Font.display(17, weight: .bold))
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy))
                }
                .foregroundStyle(DS.Colors.ink)
                .frame(width: 70, height: 70)
                .background(DS.Colors.gold, in: Circle())
                .overlay(Circle().strokeBorder(DS.Colors.ink.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [2, 2])).padding(5))
                .rotationEffect(.degrees(12))
                .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
            }
            .accessibilityLabel(ProfileText.proActive)
        } else {
            Button {
                Track.screen("profile_pro_card")
                showPaywall = true
            } label: {
                VStack(spacing: 1) {
                    Text("PRO").font(DS.Font.display(19, weight: .bold))
                    Text(ProfileText.go).font(DS.Font.ui(9, weight: .bold)).tracking(0.8)
                }
                .foregroundStyle(DS.Colors.ink)
                .frame(width: 78, height: 78)
                .background(DS.Colors.gold, in: Circle())
                .overlay(Circle().strokeBorder(DS.Colors.ink.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [2, 2])).padding(5))
                .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
                .phaseAnimator([12.0, 4.0, 12.0]) { v, angle in v.rotationEffect(.degrees(angle)) } animation: { _ in .easeInOut(duration: 1.4) }
            }
            .accessibilityLabel(langManager.s(.profileUpgradePro))
        }
    }

    // MARK: - Karnem: noktalı satırlarda sayılar
    private var reportList: some View {
        let code = LearningLanguages.current
        let minutes = (UserStore.shared.snapshot.voiceSeconds ?? 0) / 60
        return VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: ProfileText.reportCard, color: DS.Colors.accentText)
                .padding(.bottom, 2)
            LeaderRow(label: ProfileText.minutesLabel, value: ProfileText.minutesValue(minutes))
            LeaderRow(label: ProfileText.lessonsLabel, value: "\(LearningLanguages.doneCount(code))")
            LeaderRow(label: ProfileText.wordsLabel, value: "\(LearnedWordsStore.load().count)")
            LeaderRow(label: ProfileText.pagesLabel, value: "\(NotebookStore.shared.pages.count)")
            LeaderRow(label: AL.s(.hcBestStreak), value: "\(vm.bestStreak)")
        }
    }

    // MARK: - Bu hafta: çalışılan günler mühürlü
    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: ProfileText.thisWeek, color: DS.Colors.accentText)
            weeklyCalendarView
        }
    }

    // MARK: - Weekly Calendar
    private var weeklyCalendarView: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let streak = vm.user?.streakDays ?? 0
        let lastActive: Date
        if let raw = vm.user?.lastActivityAt {
            lastActive = calendar.startOfDay(for: raw)
        } else {
            lastActive = today
        }

        // Bu hafta, her zaman pazartesiden pazara (ISO hafta); bugün kendi yerinde, sonraki günler boş
        let iso = Calendar(identifier: .iso8601)
        let monday = iso.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let days = (0..<7).map { i -> Date in
            iso.date(byAdding: .day, value: i, to: monday)!
        }
        // Pzt..Paz sırası — seçili dile göre kısa gün adları
        var dayFormatter = Calendar(identifier: .gregorian)
        dayFormatter.locale = Locale(identifier: langManager.currentLanguageCode)
        let symbols = dayFormatter.shortWeekdaySymbols          // Sun=0
        let dayNames = Array(symbols[1...]) + [symbols[0]]      // Mon=0

        return HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                let weekdayIdx = (calendar.component(.weekday, from: day) + 5) % 7 // Mon=0
                let daysSinceLastActive = calendar.dateComponents([.day], from: day, to: lastActive).day ?? 99
                let isActive = daysSinceLastActive >= 0 && daysSinceLastActive < streak
                let isToday = calendar.isDateInToday(day)

                VStack(spacing: 8) {
                    Text(dayNames[weekdayIdx])
                        .font(DS.Font.ui(11, weight: isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? DS.Colors.ink : DS.Colors.muted)

                    // Çalışılan gün: terrakota mühür; bugün: kesik çizgili boş mühür
                    ZStack {
                        if isActive {
                            Circle().strokeBorder(DS.Colors.accent, lineWidth: 2)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(DS.Colors.accent)
                        } else if isToday {
                            Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])).foregroundStyle(DS.Colors.ink)
                        } else {
                            Circle().strokeBorder(DS.Colors.line, lineWidth: 1)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(isActive ? Double((i * 37) % 21) - 10 : 0))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Account (hesap yok: iCloud senkron notu + ilerlemeyi sıfırla)
    /// Sıralamadaki ad Game Center'dan gelir; uygulama içinden değişmez, Game Center profilinden değişir
    @ViewBuilder
    private var leaderboardNameRow: some View {
        if gameCenter.isAuthenticated, let name = gameCenter.playerName {
            HStack(spacing: 6) {
                Image(systemName: "trophy").font(.system(size: 11, weight: .semibold))
                Text(loc(["Sıralamada: ", "On leaderboard: ", "In der Rangliste: ", "Au classement : ",
                          "En la clasificación: ", "In classifica: ", "В рейтинге: ", "排行榜：" ]) + name)
                    .lineLimit(1)
                Button(loc(["Değiştir", "Change", "Ändern", "Modifier", "Cambiar", "Modifica", "Изменить", "更改"])) {
                    GKAccessPoint.shared.trigger(state: .localPlayerProfile) {}
                }
                .font(DS.Font.ui(12, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)
            }
            .font(DS.Font.ui(12))
            .foregroundStyle(DS.Colors.muted)
        } else {
            Text(loc(["Sıralamada görünmek için Ayarlar → Game Center'dan giriş yap",
                      "To appear on the leaderboard, sign in under Settings → Game Center",
                      "Für die Rangliste: Einstellungen → Game Center anmelden",
                      "Pour le classement : Réglages → Game Center",
                      "Para la clasificación: Ajustes → Game Center",
                      "Per la classifica: Impostazioni → Game Center",
                      "Для рейтинга войдите: Настройки → Game Center",
                      "要上排行榜，请在 设置 → Game Center 登录"]))
                .font(DS.Font.ui(12))
                .foregroundStyle(DS.Colors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Ayarlar: ana dil + yasal metinler
    private func loc(_ v: [String]) -> String {
        let order = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
        let i = order.firstIndex(of: langManager.currentLanguageCode) ?? 1
        return v.indices.contains(i) ? v[i] : v[1]
    }

    private var settingsSection: some View {
        let target = LearningLanguages.current
        let targetName = OL.languageName(for: target).capitalized(with: Locale(identifier: OL.nativeLangCode))
        return VStack(alignment: .leading, spacing: 26) {
            Text(LearningText.settings)
                .font(DS.Font.display(28, weight: .bold))
                .foregroundStyle(DS.Colors.ink)

            // LUPA: dersin nasıl geçeceği
            VStack(alignment: .leading, spacing: 18) {
                Eyebrow(text: "Lupa", color: DS.Colors.accentText)
                prefRow(SettingsText.speed, SettingsText.speedHint) {
                    NotebookSegment(options: SettingsText.speeds, selection: $prefSpeed)
                }
                prefRow(SettingsText.level(targetName), SettingsText.levelHint) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Seçilmediyse mevcut seviyeden türetilen işaretli gelir
                        NotebookSegment(options: TutorPrefs.cefrNames,
                                        selection: Binding(get: { prefCEFR >= 0 ? prefCEFR : TutorPrefs.cefr },
                                                           set: { prefCEFR = $0 }))
                        Text(SettingsText.levelMeaning(prefCEFR >= 0 ? prefCEFR : TutorPrefs.cefr))
                            .font(.system(size: 14, design: .serif).italic())
                            .foregroundStyle(DS.Colors.inkSoft)
                    }
                }
                prefRow(SettingsText.corrections, nil) {
                    NotebookSegment(options: SettingsText.correctionOptions, selection: $prefCorrections)
                }
                toggleRow(SettingsText.alwaysTranslate, SettingsText.alwaysTranslateHint, isOn: $prefTranslate)
            }

            // UYGULAMA
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: SettingsText.app, color: DS.Colors.accentText)
                NotebookDropdown(
                    title: loc(["Ana dil", "Native language", "Muttersprache", "Langue maternelle", "Idioma nativo", "Lingua madre", "Родной язык", "母语"]),
                    value: Self.endonym(langManager.currentLanguageCode),
                    options: LanguageManager.supportedCodes.filter { $0 != target }.map { ($0, Self.endonym($0)) },
                    selected: langManager.currentLanguageCode,
                    isOpen: $nativeOpen
                ) { code in
                    Track.language("ui_change", from: langManager.currentLanguageCode, to: code, entryPoint: "profile")
                    langManager.setLanguage(code)
                }
                toggleRow(SettingsText.haptics, nil, isOn: $prefHaptics)
                toggleRow(SettingsText.pen, SettingsText.penHint, isOn: $prefPen)
            }

            // HESAP ve yasal
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: SettingsText.account, color: DS.Colors.accentText)
                VStack(spacing: 0) {
                    if iap.isPremium {
                        Button { showManageSubscription = true } label: {
                            settingsRow(icon: "creditcard",
                                        title: loc(["Aboneliği yönet", "Manage subscription", "Abo verwalten", "Gérer l'abonnement", "Gestionar suscripción", "Gestisci abbonamento", "Управление подпиской", "管理订阅"]))
                        }
                        Rectangle().fill(DS.Colors.rule).frame(height: 1).padding(.leading, 36)
                    }
                    Button { openURL(ReviewPrompt.writeReviewURL) } label: {
                        settingsRow(icon: "star",
                                    title: loc(["WordRem AI'ı puanla", "Rate WordRem AI", "WordRem AI bewerten", "Noter WordRem AI", "Valorar WordRem AI", "Valuta WordRem AI", "Оценить WordRem AI", "为 WordRem AI 评分"]))
                    }
                    Rectangle().fill(DS.Colors.rule).frame(height: 1).padding(.leading, 36)
                    Button { showPrivacy = true } label: {
                        settingsRow(icon: "hand.raised",
                                    title: loc(["Gizlilik Politikası", "Privacy Policy", "Datenschutz", "Confidentialité", "Privacidad", "Privacy", "Конфиденциальность", "隐私政策"]))
                    }
                    Rectangle().fill(DS.Colors.rule).frame(height: 1).padding(.leading, 36)
                    Button { showTerms = true } label: {
                        settingsRow(icon: "doc.text",
                                    title: loc(["Kullanım Şartları", "Terms of Use", "Nutzungsbedingungen", "Conditions d'utilisation", "Términos de uso", "Termini d'uso", "Условия использования", "使用条款"]))
                    }
                    #if DEBUG
                    Rectangle().fill(DS.Colors.rule).frame(height: 1).padding(.leading, 36)
                    Button { FreshUser.isOn ? FreshUser.stop() : FreshUser.start() } label: {
                        settingsRow(icon: "person.badge.plus",
                                    title: FreshUser.isOn ? "Test: gerçek hesaba dön" : "Test: yeni kullanıcı olarak başla")
                    }
                    Rectangle().fill(DS.Colors.rule).frame(height: 1).padding(.leading, 36)
                    Button {
                        VoiceEngineChoice.next()
                        voiceEngine = VoiceEngineChoice.current
                    } label: {
                        settingsRow(icon: "waveform", title: "Test: ses motoru \(voiceEngine) (dokun: değiştir)")
                    }
                    Rectangle().fill(DS.Colors.rule).frame(height: 1).padding(.leading, 36)
                    Button { showStudio = true } label: {
                        settingsRow(icon: "video", title: "Stüdyo: sosyal medya kaydı")
                    }
                    #endif
                }
                .overlay(alignment: .top) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
                .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
            }
        }
    }

    private func prefRow<Control: View>(_ title: String, _ hint: String?, @ViewBuilder _ control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DS.Font.ui(16, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
            if let hint {
                Text(hint)
                    .font(DS.Font.ui(13))
                    .foregroundStyle(DS.Colors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            control()
        }
    }

    private func toggleRow(_ title: String, _ hint: String?, isOn: Binding<Bool>) -> some View {
        Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { isOn.wrappedValue.toggle() }; Haptics.tap() } label: {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(DS.Font.ui(16, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    if let hint {
                        Text(hint)
                            .font(DS.Font.ui(13))
                            .foregroundStyle(DS.Colors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                PaperToggle(isOn: isOn.wrappedValue)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn.wrappedValue ? "1" : "0")
        .accessibilityAddTraits(.isButton)
    }

    /// Dil seçicide her dil kendi adıyla görünür (Deutsch, Français…), herkes kendi dilini bulsun
    private static func endonym(_ code: String) -> String {
        let loc = Locale(identifier: code)
        let name = loc.localizedString(forLanguageCode: code) ?? code
        return name.prefix(1).uppercased(with: loc) + name.dropFirst()
    }

    private func settingsRow(icon: String, title: String, value: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(DS.Colors.accentText)
                .frame(width: 22)
            Text(title)
                .font(DS.Font.ui(16, weight: .medium))
                .foregroundStyle(DS.Colors.ink)
            Spacer()
            if let value {
                Text(value)
                    .font(DS.Font.ui(15))
                    .foregroundStyle(DS.Colors.muted)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.muted)
        }
        .padding(.vertical, 15)
        .contentShape(Rectangle())
    }

    private var accountSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "icloud")
                    .foregroundStyle(DS.Colors.muted)
                Text(langManager.s(.profileSyncNote))
                    .font(DS.Font.ui(13))
                    .foregroundStyle(DS.Colors.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            Button { showResetConfirm = true } label: {
                Text(langManager.s(.profileResetProgress))
                    .font(DS.Font.ui(13, weight: .medium))
                    .foregroundStyle(DS.Colors.danger)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .alert(langManager.s(.profileResetTitle), isPresented: $showResetConfirm) {
                Button(langManager.s(.profileResetConfirm), role: .destructive) {
                    authManager.resetAllProgress()
                }
                Button(langManager.s(.profileDeleteCancel), role: .cancel) {}
            } message: {
                Text(langManager.s(.profileResetMessage))
            }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════════
// MARK: - ViewModel
// MARK: ═══════════════════════════════════════════════════════════

@MainActor
final class ProfileScreenViewModel: ObservableObject {
    @Published var user: SBUser?
    @Published var stats = UserStats(completedLevels: 0, totalAttempts: 0, correctAnswers: 0)
    @Published var isLoading = false
    @Published var showCharacterPicker = false

    /// Seçili karakter asset adı (UserDefaults'ta saklanır)
    @Published var selectedCharacter: String? {
        didSet {
            if let v = selectedCharacter { UserDefaults.standard.set(v, forKey: "selectedCharacter") }
            else { UserDefaults.standard.removeObject(forKey: "selectedCharacter") }
        }
    }

    init() {
        selectedCharacter = UserDefaults.standard.string(forKey: "selectedCharacter")
    }

    var username: String  { user?.username ?? AL.s(.profileGuest) }
    var initials: String  { String((user?.username ?? "?").prefix(1)).uppercased() }
    var userLevel: Int    { max(1, (user?.totalXp ?? 0) / 50 + 1) }

    /// En iyi seri: mevcut streak'ten büyükse UserDefaults'ta sakla
    var bestStreak: Int {
        let current = user?.streakDays ?? 0
        let stored  = UserDefaults.standard.integer(forKey: "bestStreak")
        if current > stored {
            UserDefaults.standard.set(current, forKey: "bestStreak")
            return current
        }
        return max(stored, current)
    }

    func loadProfile() async {
        isLoading = true
        do {
            user  = try await DataService.shared.fetchUserProfile()
            stats = try await DataService.shared.fetchUserStats()
            // Fetch already-saved achievements (no new unlock toast on profile open)
            await AchievementService.shared.fetchSaved()
        } catch {
            print("❌ Profile load error: \(error)")
        }
        isLoading = false
    }

    func updateUsername(_ newUsername: String) async {
        DataService.shared.updateUsername(newUsername)
        user = try? await DataService.shared.fetchUserProfile()
    }
}


// MARK: ═══════════════════════════════════════════════════════════
// MARK: - Subviews
// MARK: ═══════════════════════════════════════════════════════════

// MARK: - Username Setup Popup (mandatory, kapatılamaz)
private struct UsernameSetupPopup: View {
    @EnvironmentObject var langManager: LanguageManager
    let initialUsername: String
    let isFirstSetup: Bool   // true → zorunlu (ilk login), false → profil butonu (1 kez hak)
    let onDismiss: () -> Void
    let onSave: (String) -> Void

    @State private var username: String = ""
    @State private var isSaving = false
    @FocusState private var focused: Bool

    private static func loc(_ code: String, _ v: [String]) -> String {
        let order = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
        let i = order.firstIndex(of: code) ?? 1
        return v.indices.contains(i) ? v[i] : v[1]
    }

    private var isValid: Bool {
        username.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var body: some View {
        ZStack {
            DS.Colors.ink.opacity(0.4)
                .ignoresSafeArea()

            StickyNote(angle: -1) {
                VStack(alignment: .leading, spacing: 0) {
                    // Close butonu — her zaman (ilk kurulumda da atlanabilir; Apple 4.8 / 5.1.1)
                    HStack(alignment: .top) {
                        Text(Self.loc(langManager.currentLanguageCode, ["Öğretmen sana nasıl seslensin?", "What should your tutor call you?",
                            "Wie soll dich dein Tutor nennen?", "Comment ton tuteur doit-il t'appeler ?", "¿Cómo quieres que te llame tu tutor?",
                            "Come vuoi che ti chiami il tuo tutor?", "Как репетитору тебя называть?", "老师该怎么称呼你？"]))
                            .font(DS.Font.display(24))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 12)
                        Button {
                            focused = false
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(DS.Colors.inkSoft)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(DS.Colors.line, lineWidth: 1))
                        }
                        .accessibilityLabel(langManager.s(.usernameSkip))
                    }

                    Text(Self.loc(langManager.currentLanguageCode, [
                        "Sesli derslerde öğretmen seni bu isimle çağırır. İstediğin zaman değiştirebilirsin. Sıralamada Game Center adın görünür.",
                        "Your tutor uses this name in voice lessons. You can change it anytime. The leaderboard shows your Game Center name.",
                        "Dein Tutor nutzt diesen Namen in den Sprachlektionen. Du kannst ihn jederzeit ändern. In der Rangliste steht dein Game-Center-Name.",
                        "Ton tuteur utilise ce prénom pendant les leçons. Tu peux le changer à tout moment. Le classement affiche ton nom Game Center.",
                        "Tu tutor usa este nombre en las clases de voz. Puedes cambiarlo cuando quieras. En la clasificación aparece tu nombre de Game Center.",
                        "Il tutor usa questo nome nelle lezioni vocali. Puoi cambiarlo quando vuoi. In classifica appare il tuo nome Game Center.",
                        "Репетитор обращается к тебе по этому имени. Его можно изменить в любой момент. В рейтинге показывается имя из Game Center.",
                        "老师会在语音课中这样称呼你，随时可以修改。排行榜显示你的 Game Center 名称。"]))
                        .font(DS.Font.ui(14))
                        .foregroundStyle(DS.Colors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)

                    TextField(langManager.s(.profileUsernamePlaceholder), text: $username)
                        .font(DS.Font.display(24, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                        .tint(DS.Colors.accent)
                        .frame(height: 52)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(focused ? DS.Colors.accent : DS.Colors.inkSoft).frame(height: 1.5)
                        }
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .focused($focused)
                        .padding(.top, 20)

                    Button {
                        guard isValid, !isSaving else { return }
                        isSaving = true
                        focused = false
                        onSave(username.trimmingCharacters(in: .whitespaces))
                    } label: {
                        if isSaving {
                            ProgressView().tint(DS.Colors.paperRaised)
                        } else {
                            Text(langManager.s(.profileSave))
                        }
                    }
                    .buttonStyle(InkButtonStyle())
                    .opacity(isValid ? 1 : 0.4)
                    .disabled(!isValid || isSaving)
                    .padding(.top, 16)
                }
            }
            .frame(maxWidth: 440)
            .padding(.horizontal, 24)
            // Keyboard popup'ı yukarı kaydırmasın
            .ignoresSafeArea(.keyboard)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            let generics = ["Apple User", "Google User", "Guest"]
            let cleaned = initialUsername.trimmingCharacters(in: .whitespaces)
            if !generics.contains(where: { cleaned.hasPrefix($0) }) && cleaned.count >= 3 {
                username = cleaned
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}

/// Profil metinleri (sıra: tr, en, de, fr, es, it, ru, zh)
private enum ProfileText {
    static var thisNotebook: String { PageText.t(["BU DEFTER", "THIS NOTEBOOK", "DIESES HEFT", "CE CARNET", "ESTE CUADERNO", "QUESTO QUADERNO", "ЭТА ТЕТРАДЬ", "这本笔记本"]) }
    static func page(_ n: Int) -> String { PageText.t(["\(n). sayfa", "page \(n)", "Seite \(n)", "page \(n)", "página \(n)", "pagina \(n)", "стр. \(n)", "第 \(n) 页"]) }
    static var thisWeek: String { PageText.t(["BU HAFTA", "THIS WEEK", "DIESE WOCHE", "CETTE SEMAINE", "ESTA SEMANA", "QUESTA SETTIMANA", "ЭТА НЕДЕЛЯ", "本周"]) }
    static var reportCard: String { PageText.t(["KARNEM", "MY REPORT CARD", "MEIN ZEUGNIS", "MON BULLETIN", "MI BOLETÍN", "LA MIA PAGELLA", "МОЙ ТАБЕЛЬ", "我的成绩单"]) }
    static var streak: String { PageText.t(["günlük seri", "day streak", "Tage in Folge", "jours d'affilée", "días seguidos", "giorni di fila", "дней подряд", "天连续"]) }
    static func toNext(_ n: Int, _ level: Int) -> String {
        PageText.t(["Seviye \(level) için \(n) ders kaldı", "\(n) lessons to level \(level)", "Noch \(n) Lektionen bis Niveau \(level)", "Encore \(n) leçons avant le niveau \(level)", "Faltan \(n) lecciones para el nivel \(level)", "Mancano \(n) lezioni al livello \(level)", "До уровня \(level): \(n) уроков", "距离 \(level) 级还差 \(n) 节课"])
    }
    static var go: String { PageText.t(["GEÇ", "GET", "HOLEN", "PASSER", "PASAR", "PASSA", "ВЗЯТЬ", "开通"]) }
    static var proActive: String { PageText.t(["Pro üyeliğin aktif", "Your Pro membership is active", "Deine Pro-Mitgliedschaft ist aktiv", "Ton abonnement Pro est actif", "Tu suscripción Pro está activa", "Il tuo abbonamento Pro è attivo", "Подписка Pro активна", "Pro 会员已激活"]) }
    static var minutesLabel: String { PageText.t(["Konuştuğun süre", "Time spoken", "Gesprochene Zeit", "Temps de parole", "Tiempo hablado", "Tempo parlato", "Время разговора", "口语时长"]) }
    static func minutesValue(_ m: Int) -> String { PageText.t(["\(m) dk", "\(m) min", "\(m) Min.", "\(m) min", "\(m) min", "\(m) min", "\(m) мин", "\(m) 分钟"]) }
    static var lessonsLabel: String { PageText.t(["Biten ders", "Lessons done", "Fertige Lektionen", "Leçons terminées", "Lecciones hechas", "Lezioni finite", "Пройдено уроков", "完成的课程"]) }
    static var wordsLabel: String { PageText.t(["Öğrenilen kelime", "Words learned", "Gelernte Wörter", "Mots appris", "Palabras aprendidas", "Parole imparate", "Выучено слов", "学会的单词"]) }
    static var pagesLabel: String { PageText.t(["Dolan sayfa", "Pages written", "Beschriebene Seiten", "Pages écrites", "Páginas escritas", "Pagine scritte", "Исписано страниц", "已写页数"]) }
}

// MARK: - Ayar bileşenleri (defter dili)

/// Defter sekmesi gibi seçenek şeridi: seçili olan not kâğıdı renginde, altı terrakota çizgili
private struct NotebookSegment: View {
    let options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let on = i == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = i }
                    Haptics.tap()
                } label: {
                    Text(options[i])
                        .font(DS.Font.ui(14, weight: on ? .semibold : .regular))
                        .foregroundStyle(on ? DS.Colors.ink : DS.Colors.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(on ? DS.Colors.note : .clear)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(on ? DS.Colors.accent : .clear).frame(height: 2)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
                if i < options.count - 1 {
                    Rectangle().fill(DS.Colors.line).frame(width: 1, height: 22)
                }
            }
        }
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Colors.line, lineWidth: 1))
    }
}

/// Kâğıt anahtar: kapalıyken boş kutu, açıkken terrakota ve kalem tiki
private struct PaperToggle: View {
    let isOn: Bool
    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? DS.Colors.accent : DS.Colors.paperSunken)
                .overlay(Capsule().stroke(isOn ? DS.Colors.accent : DS.Colors.line, lineWidth: 1))
            Circle()
                .fill(DS.Colors.paperRaised)
                .frame(width: 24, height: 24)
                .overlay {
                    if isOn {
                        PenTick()
                            .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 12, height: 10)
                    }
                }
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                .padding(3)
        }
        .frame(width: 52, height: 30)
    }
}

/// Özel açılır liste: satıra dokununca altında seçenekler açılır, seçili olanın yanında kalem tiki
private struct NotebookDropdown: View {
    let title: String
    let value: String
    let options: [(id: String, label: String)]
    let selected: String
    @Binding var isOpen: Bool
    var onPick: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { isOpen.toggle() } } label: {
                HStack(spacing: 12) {
                    Text(title)
                        .font(DS.Font.ui(16, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    Spacer()
                    Text(value)
                        .font(.system(size: 16, design: .serif).italic())
                        .foregroundStyle(DS.Colors.accentText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isOpen {
                VStack(spacing: 0) {
                    ForEach(options, id: \.id) { o in
                        Button {
                            onPick(o.id)
                            Haptics.tap()
                            withAnimation(.easeOut(duration: 0.2)) { isOpen = false }
                        } label: {
                            HStack(spacing: 12) {
                                Text(o.label)
                                    .font(DS.Font.display(17, weight: o.id == selected ? .semibold : .regular))
                                    .foregroundStyle(DS.Colors.ink)
                                Spacer()
                                if o.id == selected {
                                    PenTick()
                                        .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                                        .frame(width: 18, height: 15)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(minHeight: 46)
                            .overlay(alignment: .top) { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isOpen ? DS.Colors.accent.opacity(0.6) : DS.Colors.line, lineWidth: 1))
    }
}

/// Ayarlar metinleri (sıra: tr, en, de, fr, es, it, ru, zh)
private enum SettingsText {
    static var speed: String { PageText.t(["Konuşma hızı", "Speaking speed", "Sprechtempo", "Vitesse de parole", "Velocidad al hablar", "Velocità del parlato", "Скорость речи", "语速"]) }
    static var speedHint: String { PageText.t(["Lupa ne kadar hızlı konuşsun", "How fast Lupa talks", "Wie schnell Lupa spricht", "À quelle vitesse Lupa parle", "Qué tan rápido habla Lupa", "Quanto velocemente parla Lupa", "Как быстро говорит Лупа", "Lupa 说话的快慢"]) }
    static var speeds: [String] { [PageText.t(["Yavaş", "Slow", "Langsam", "Lent", "Lento", "Lento", "Медленно", "慢"]),
                                   PageText.t(["Normal", "Normal", "Normal", "Normal", "Normal", "Normale", "Обычно", "正常"]),
                                   PageText.t(["Hızlı", "Fast", "Schnell", "Rapide", "Rápido", "Veloce", "Быстро", "快"])] }
    static func level(_ lang: String) -> String { PageText.t(["\(lang) seviyen", "Your \(lang) level", "Dein \(lang)-Niveau", "Ton niveau de \(lang)", "Tu nivel de \(lang)", "Il tuo livello di \(lang)", "Твой уровень: \(lang)", "你的\(lang)水平"]) }
    static var levelHint: String { PageText.t(["Lupa anlatım dilini, kelimeleri ve cümle uzunluğunu buna göre ayarlar", "Lupa adapts her explanations, words and sentence length to it", "Lupa passt Erklärungen, Wörter und Satzlänge daran an", "Lupa adapte ses explications, ses mots et la longueur des phrases", "Lupa adapta sus explicaciones, palabras y frases a tu nivel", "Lupa adatta spiegazioni, parole e lunghezza delle frasi", "Лупа подстраивает объяснения, слова и длину фраз", "Lupa 会据此调整讲解语言、词汇和句子长度"]) }
    static func levelMeaning(_ i: Int) -> String {
        let tr = ["A1 · Yeni başlıyorum, Lupa Türkçe anlatsın", "A2 · Temel ifadeleri biliyorum", "B1 · Günlük konularda sohbet edebiliyorum", "B2 · Rahat konuşuyorum, doğal dil istiyorum", "C1 · Akıcıyım, ana dili gibi konuşsun"]
        let en = ["A1 · I'm just starting, explain in my language", "A2 · I know basic phrases", "B1 · I can chat about everyday topics", "B2 · I speak comfortably, give me natural language", "C1 · I'm fluent, talk like a native"]
        let de = ["A1 · Ich fange gerade an", "A2 · Ich kenne einfache Sätze", "B1 · Ich kann über Alltägliches sprechen", "B2 · Ich spreche sicher, bitte natürlich", "C1 · Ich bin fließend, sprich wie ein Muttersprachler"]
        let fr = ["A1 · Je débute", "A2 · Je connais les phrases de base", "B1 · Je peux parler du quotidien", "B2 · Je parle à l'aise, langue naturelle", "C1 · Je suis courant, parle comme un natif"]
        let es = ["A1 · Estoy empezando", "A2 · Conozco frases básicas", "B1 · Puedo charlar sobre lo cotidiano", "B2 · Hablo con soltura, lenguaje natural", "C1 · Tengo fluidez, habla como un nativo"]
        let it = ["A1 · Sto iniziando", "A2 · Conosco le frasi di base", "B1 · So parlare della vita quotidiana", "B2 · Parlo con sicurezza, lingua naturale", "C1 · Sono fluente, parla come un madrelingua"]
        let ru = ["A1 · Только начинаю", "A2 · Знаю базовые фразы", "B1 · Могу говорить о повседневном", "B2 · Говорю уверенно, нужен живой язык", "C1 · Свободно, говори как носитель"]
        let zh = ["A1 · 刚开始学", "A2 · 会基本表达", "B1 · 能聊日常话题", "B2 · 说得流利，要自然的语言", "C1 · 很流利，像母语者一样说"]
        let i = min(4, max(0, i))
        return PageText.t([tr[i], en[i], de[i], fr[i], es[i], it[i], ru[i], zh[i]])
    }
    static var corrections: String { PageText.t(["Düzeltmeler", "Corrections", "Korrekturen", "Corrections", "Correcciones", "Correzioni", "Исправления", "纠错"]) }
    static var correctionOptions: [String] { [PageText.t(["Her hatayı", "Every mistake", "Jeder Fehler", "Chaque erreur", "Cada error", "Ogni errore", "Каждую ошибку", "每个错误"]),
                                              PageText.t(["Sadece önemliler", "Only important", "Nur wichtige", "Les importantes", "Solo importantes", "Solo importanti", "Только важные", "只纠正重要的"])] }
    static var alwaysTranslate: String { PageText.t(["Kartlarda çeviri hep açık", "Always show translations", "Übersetzung immer zeigen", "Toujours afficher la traduction", "Mostrar siempre la traducción", "Mostra sempre la traduzione", "Всегда показывать перевод", "总是显示翻译"]) }
    static var alwaysTranslateHint: String { PageText.t(["Söyleyeceğin cümlenin anlamı hemen altında yazsın", "The meaning appears right under the line you say", "Die Bedeutung steht direkt unter dem Satz", "Le sens s'affiche sous la phrase à dire", "El significado aparece bajo la frase", "Il significato appare sotto la frase", "Перевод сразу под фразой", "要说的句子下方直接显示意思"]) }
    static var app: String { PageText.t(["Uygulama", "App", "App", "App", "App", "App", "Приложение", "应用"]) }
    static var haptics: String { PageText.t(["Titreşim", "Haptics", "Vibration", "Vibrations", "Vibración", "Vibrazione", "Вибрация", "振动"]) }
    static var pen: String { PageText.t(["Kalemle yazma efekti", "Handwriting effect", "Schreibeffekt", "Effet d'écriture", "Efecto de escritura", "Effetto scrittura", "Эффект письма", "手写效果"]) }
    static var penHint: String { PageText.t(["Lupa'nın sözleri harf harf yazılsın", "Lupa's words appear letter by letter", "Lupas Worte erscheinen Buchstabe für Buchstabe", "Les mots de Lupa s'écrivent lettre par lettre", "Las palabras de Lupa aparecen letra a letra", "Le parole di Lupa appaiono lettera per lettera", "Слова Лупы появляются по буквам", "Lupa 的话逐字出现"]) }
    static var account: String { PageText.t(["Hesap", "Account", "Konto", "Compte", "Cuenta", "Account", "Аккаунт", "账户"]) }
}
