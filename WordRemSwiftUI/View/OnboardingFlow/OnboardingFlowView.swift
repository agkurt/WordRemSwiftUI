//
//  OnboardingFlowView.swift
//  WordRemSwiftUI
//
//  Kısa onboarding: defter kapağı → ana dil → öğrenilecek dil → etikete ad →
//  canlı sesli demo (öğretmen adıyla karşılar, birkaç cümle konuşturur) → paywall → uygulama.
//  Seçimler dokununca kendiliğinden ilerler; ana dil telefondan gelir, istenirse değiştirilir.
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager

    private enum Step: Int { case welcome, native, language, name, demo }

    /// Paywall'a ulaşıldı ama onboarding bitmedi: uygulama kapatılırsa yeniden açılışta doğrudan paywall (sert paywall)
    static let reachedPaywallKey = "onboardingReachedPaywall"

    @State private var step: Step = .welcome
    @State private var forward = true
    @State private var native = OL.nativeLangCode
    @State private var target: String?
    @State private var name = ""
    @State private var showPaywall = false
    @State private var paywallSeen = false
    @State private var checkingPro = false
    @State private var finished = false
    /// Demodan sonra paywall'dan önce ~3 sn "defterin hazırlanıyor" sayfası
    @State private var preparing = false
    @FocusState private var nameFocused: Bool
    @State private var stepStartedAt = Date()

    private static let stepNames: [Step: String] = [
        .welcome: "welcome", .native: "native_language", .language: "target_language", .name: "name", .demo: "demo",
    ]
    private func trackStep(_ action: String, _ s: Step) {
        Track.onboarding(action, step: Self.stepNames[s] ?? "\(s.rawValue)", index: s.rawValue,
                         timeOnStep: action == "view" ? nil : Date().timeIntervalSince(stepStartedAt),
                         native: native, target: target, hasName: !name.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private var targetName: String { langManager.languageName(for: target ?? "en") }

    var body: some View {
        VStack(spacing: 0) {
            if step == .native || step == .language || step == .name { header }
            ZStack {
                content
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        // Karşılama defter kapağıdır; sonraki adımlar kenar boşluklu sayfa
        .background {
            if step == .welcome { NotebookCover().ignoresSafeArea() }
            else { Color.clear.ruledPage(margin: false) }
        }
        .onAppear { stepStartedAt = Date(); trackStep("view", step); Track.screen("onboarding") }
        // Sert paywall: kapatma yok; yalnızca satın alma / geri yükleme sonrası (Hoş geldin → devam) onboarding biter → ana sayfa
        .fullScreenCover(isPresented: $showPaywall, onDismiss: finish) {
            OnboardingPaywallView(onContinue: { showPaywall = false }, entryPoint: "onboarding", isHard: true)
                .interactiveDismissDisabled(true)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:  welcome
        case .native:   nativeStep
        case .language: languageStep
        case .name:     nameStep
        case .demo:
            // Canlı sesli demo: öğretmen adıyla karşılar, birkaç cümle konuşturur → defter hazırlanır → paywall
            if preparing {
                NotebookPreparingView(name: trimmedName, language: target ?? "en") {
                    showPaywall = true
                }
                .transition(.opacity)
            } else {
                VoiceTutorView(mode: .demo, onFinished: { _ in demoFinished() }, isDemo: true)
            }
        }
    }

    /// Demo bitti (veda, X ya da süre doldu). Pro kullanıcı (ör. silip yeniden yükleyen) paywall görmez.
    private func demoFinished() {
        // Paywall açıkken ya da "defterin hazırlanıyor" sayfasındayken gelen ikinci "bitti" sinyali
        // akışı atlatmasın (yoksa paywall'a gelmeden onboarding biterdi)
        guard !showPaywall, !checkingPro, !preparing else { return }
        if !paywallSeen { trackStep("complete", .demo) }
        if paywallSeen { return finish() }
        checkingPro = true
        Task {
            let iap = InAppPurchaseManager.shared
            let pro = iap.isPremium ? true : await iap.isPro()
            await MainActor.run {
                checkingPro = false
                if pro { iap.isPremium = true; finish() }
                else {
                    paywallSeen = true
                    UserDefaults.standard.set(true, forKey: Self.reachedPaywallKey)
                    withAnimation(.easeOut(duration: 0.3)) { preparing = true }
                }
            }
        }
    }

    private func go(_ next: Step) {
        guard next != step else { return }
        trackStep(next.rawValue > step.rawValue ? "complete" : "back", step)
        stepStartedAt = Date()
        trackStep("view", next)
        forward = next.rawValue > step.rawValue
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { step = next }
    }

    /// Seçim vurgusu görünsün diye kısa gecikmeyle ilerle
    private func advance(after next: Step) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { go(next) }
    }

    // MARK: - Üst çubuk: geri + sayfa numarası
    private var header: some View {
        HStack(spacing: 6) {
            Button { go(Step(rawValue: step.rawValue - 1) ?? .welcome) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 44, height: 44)
            }
            Text(PageText.page(step.rawValue) + " / 3")
                .font(.system(size: 15, design: .serif).italic())
                .foregroundStyle(DS.Colors.muted)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: step)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func title(_ text: String, _ sub: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(DS.Font.display(30, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let sub {
                Text(sub).font(DS.Font.ui(16)).foregroundStyle(DS.Colors.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, DS.Page.textX)
        .padding(.trailing, 24)
        .padding(.top, 20)
        .padding(.bottom, 18)
    }

    // MARK: - 0. Karşılama: defter kapağı, üstten sarkan ayraçlar, etiket
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                BookmarkMark(mood: .speaking, width: 17,
                             colors: [DS.Colors.ink, DS.Colors.accent, DS.Colors.paper, DS.Colors.margin])
                    .padding(.trailing, 16)
            }
            Spacer()
            coverLabel(name: nil)
            Text(langManager.s(.obHeroSub))
                .font(.system(size: 18, design: .serif).italic())
                .foregroundStyle(Color(hex: "#E5ECEF"))
                .padding(.top, 28)
                .padding(.leading, 28)
            Spacer()
            Button(langManager.s(.obLetsGo)) { go(.native) }
                .buttonStyle(InkButtonStyle(fill: DS.Colors.paper, foreground: DS.Colors.ink))
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    /// Kapaktaki etiket: marka, "dil defteri", tek cümle, ad satırı
    private func coverLabel(name: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            WordRemLogoText(size: 34)
            Eyebrow(text: OnbText.notebook, color: DS.Colors.accentText).padding(.top, 8)
            Text(langManager.s(.obHeroTitle))
                .font(DS.Font.display(22, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            // Basılı başlangıç satırı (doldurulacak bir alan gibi görünmesin): ilk sayfa ve bugünün tarihi
            HStack(spacing: 8) {
                RibbonShape().fill(DS.Colors.accent).frame(width: 8, height: 16)
                Text("\(PageText.page(1)) · \(Date().formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: OL.nativeLangCode))))")
                    .font(.system(size: 14, design: .serif).italic())
                    .foregroundStyle(DS.Colors.inkSoft)
            }
            .padding(.top, 20)
        }
        .padding(22)
        .background(DS.Colors.paper, in: RoundedRectangle(cornerRadius: 8))
        .rotationEffect(.degrees(-1))
        .shadow(color: .black.opacity(0.22), radius: 14, y: 10)
        .padding(.leading, 28)
    }

    // MARK: - 1. Ana dil (telefondan gelen dil seçili gelir; seçince arayüz de o dile geçer)
    private var nativeStep: some View {
        VStack(spacing: 0) {
            title(langManager.s(.obNativeTitle), langManager.s(.obNativeSub))
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(LanguageManager.supportedCodes, id: \.self) { code in
                        optionRow(selected: native == code) {
                            miniCover(code, filled: native == code)
                            Text(langManager.languageName(for: code))
                        } action: {
                            native = code
                            langManager.setLanguage(code)
                            if target == code { target = nil }
                            advance(after: .language)
                        }
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - 2. Öğrenilecek dil
    private var languageStep: some View {
        VStack(spacing: 0) {
            title(langManager.s(.whatToLearn))
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(LanguageManager.supportedCodes.filter { $0 != native }, id: \.self) { code in
                        optionRow(selected: target == code) {
                            miniCover(code, filled: target == code)
                            Text(langManager.languageName(for: code))
                        } action: {
                            target = code
                            advance(after: .name)
                        }
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - 3. Ad: defterin etiketine yazılır
    private var nameStep: some View {
        VStack(spacing: 0) {
            title(langManager.s(.obNameTitle), langManager.s(.obNameSub))
            ZStack(alignment: .topTrailing) {
                NotebookCover()
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6,
                                                      bottomTrailingRadius: 16, topTrailingRadius: 16))
                BookmarkMark(width: 10, colors: [DS.Colors.ink, DS.Colors.accent, DS.Colors.paper, DS.Colors.margin])
                    .padding(.trailing, 22)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        WordRemLogoText(size: 20)
                        if let target {
                            Eyebrow(text: langManager.languageName(for: target), color: DS.Colors.accentText)
                        }
                    }
                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Text(langManager.s(.obNamePlaceholder)).font(DS.Font.ui(13)).foregroundStyle(DS.Colors.muted)
                        TextField("", text: $name)
                            .font(DS.Font.display(30, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($nameFocused)
                            .onSubmit(submitName)
                            .padding(.bottom, 2)
                            .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.accent).frame(height: 1.5) }
                    }
                    .padding(.top, 14)
                }
                .padding(18)
                .background(DS.Colors.paper, in: RoundedRectangle(cornerRadius: 8))
                .rotationEffect(.degrees(-1))
                .padding(.horizontal, 36)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 230)
            .padding(.horizontal, 24)
            Spacer()
            Button(OnbText.meetLupa, action: submitName)
                .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                .obDisabled(trimmedName.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { nameFocused = true } }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func submitName() {
        guard !trimmedName.isEmpty else { return }
        name = String(trimmedName.prefix(24))
        nameFocused = false
        savePreferences()          // öğretmen dili ve adı bilsin
        go(.demo)
    }

    // MARK: - Ortak seçenek satırı: çizgili liste, seçilince kenar boşluğunda kalem tiki
    private func optionRow<Label: View>(selected: Bool, @ViewBuilder label: () -> Label,
                                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                label()
                    .font(DS.Font.ui(18, weight: selected ? .semibold : .medium))
                    .foregroundStyle(DS.Colors.ink)
                Spacer()
            }
            .padding(.leading, DS.Page.textX)
            .frame(height: 60)
            .background(selected ? DS.Colors.note : .clear)
            .overlay(alignment: .leading) {
                PenTick()
                    .trim(from: 0, to: selected ? 1 : 0)
                    .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: 28, height: 24)
                    .padding(.leading, 22)
                    .animation(.easeOut(duration: 0.25), value: selected)
            }
            .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Dil satırındaki küçük defter: seçiliyse dolu arduvaz, değilse kesik çizgili
    private func miniCover(_ code: String, filled: Bool) -> some View {
        Text(code.uppercased())
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(filled ? DS.Colors.paperRaised : DS.Colors.muted)
            .frame(width: 26, height: 34)
            .background(filled ? DS.Colors.slate : .clear,
                        in: UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 3, bottomTrailingRadius: 6, topTrailingRadius: 6))
            .overlay(UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 3, bottomTrailingRadius: 6, topTrailingRadius: 6)
                .strokeBorder(filled ? .clear : Color(hex: "#B8B0A4"), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])))
    }

    // MARK: - Kaydet & bitir
    private func savePreferences() {
        let code = target ?? "en"
        let interest = ""
        let d = UserDefaults.standard
        d.set(code, forKey: "selectedTargetLanguageCode")
        d.set(langManager.languageName(for: code), forKey: "selectedTargetLanguageName")
        d.set(1, forKey: "selectedProficiencyLevel")   // seviye sorulmuyor: öğretmen konuşmadan kendisi ayarlar
        d.set(10, forKey: "dailyGoalMinutes")
        if !interest.isEmpty { d.set(interest, forKey: "learningInterest") }
        langManager.setLanguage(native)
        if !trimmedName.isEmpty { DataService.shared.updateUsername(trimmedName) }
        Task {
            try? await DataService.shared.saveUserPreferences(
                targetLangCode: code, nativeLangCode: native, proficiencyLevel: 1,
                learningInterest: interest, dailyGoalMinutes: 10)
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        UserDefaults.standard.removeObject(forKey: Self.reachedPaywallKey)
        Track.onboarding("finish", step: Self.stepNames[step] ?? "demo", index: step.rawValue,
                         native: native, target: target, hasName: !name.trimmingCharacters(in: .whitespaces).isEmpty)
        Task {
            _ = try? await DataService.shared.updateDailyLoginStreak()
            await MainActor.run { authManager.completeOnboarding() }
        }
    }
}

/// Onboarding'in defter metinleri (sıra: tr, en, de, fr, es, it, ru, zh)
private enum OnbText {
    static var notebook: String { PageText.t(["Dil defteri", "Language notebook", "Sprachheft", "Carnet de langue", "Cuaderno de idiomas", "Quaderno di lingue", "Языковая тетрадь", "语言笔记本"]) }
    static var meetLupa: String { PageText.meetLupa }
}

extension View {
    /// Ink CTA'nın pasif hali: aynı stil, düşük opaklık
    func obDisabled(_ disabled: Bool) -> some View {
        self.disabled(disabled).opacity(disabled ? 0.35 : 1)
    }
}

// MARK: - Demodan sonra: "defterin hazırlanıyor" (~3 sn)
/// Üç madde sırayla kalemle yazılır ve kenarda tiklenir, alttaki çizgi bu sırada dolar;
/// sonunda tarihli "Hazır" mührü basılır ve paywall gelir. Seviye gibi bilmediğimiz bir şey iddia edilmez.
private struct NotebookPreparingView: View {
    let name: String
    let language: String
    var onDone: () -> Void

    @State private var started = 0
    @State private var ticked = 0
    @State private var progress: CGFloat = 0
    @State private var stamped = false

    private var steps: [String] { [PrepText.writing, PrepText.chapter, PrepText.reminders] }
    private var finals: [String] {
        let chapter = ScenarioStore.shared.chapters.first?.localizedTitle ?? ""
        return [PrepText.writtenFinal, PrepText.chapterFinal(chapter), PrepText.remindersFinal]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: PageText.firstPage, color: DS.Colors.accentText)
                Text(stamped ? PrepText.ready(name) : PrepText.preparing(name))
                    .font(DS.Font.display(28, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
            .padding(.leading, DS.Page.textX)
            .padding(.trailing, 24)
            .padding(.top, 90)
            .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<started, id: \.self) { i in
                    PenText(text: stamped ? finals[i] : steps[i], animate: !stamped, size: 18, speed: 34)
                        .overlay(alignment: .topLeading) {
                            PenTick()
                                .trim(from: 0, to: i < ticked ? 1 : 0)
                                .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .frame(width: 24, height: 20)
                                .offset(x: -(DS.Page.textX - 20), y: 6)
                                .animation(.easeOut(duration: 0.25), value: ticked)
                        }
                }
            }
            .padding(.leading, DS.Page.textX)
            .padding(.trailing, 24)
            .frame(height: DS.Page.pitch * 4, alignment: .top)
            .background(alignment: .top) { RuledLines() }

            Spacer(minLength: 0)
            InkStamp(top: Date().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode))).uppercased(),
                     title: PrepText.readyStamp,
                     bottom: OL.languageName(for: language).uppercased(with: Locale(identifier: OL.nativeLangCode)),
                     size: 120)
                .scaleEffect(stamped ? 1 : 2.2)
                .opacity(stamped ? 1 : 0)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Colors.line)
                    Capsule().fill(DS.Colors.accent).frame(width: g.size.width * progress)
                }
            }
            .frame(height: 3)
            .padding(.leading, DS.Page.textX)
            .padding(.trailing, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { MarginLine() }
        .overlay(alignment: .topTrailing) {
            BookmarkMark(mood: .speaking, width: 12).padding(.trailing, 24)
        }
        // Bu sayfada dokunuşlar hiçbir şeyi atlatmaz: paywall açılana kadar beklenir
        .contentShape(Rectangle())
        .onTapGesture {}
        .task {
            withAnimation(.linear(duration: 3.0)) { progress = 1 }
            // Maddeler sırayla: biri yazılıp tiklenmeden diğeri başlamaz
            for i in 0..<3 {
                started = i + 1
                try? await Task.sleep(nanoseconds: 780_000_000)
                ticked = i + 1
                Haptics.tap()
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.55)) { stamped = true }
            Haptics.success()
            try? await Task.sleep(nanoseconds: 900_000_000)
            onDone()
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Defterin hazırlanıyor" metinleri (sıra: tr, en, de, fr, es, it, ru, zh)
private enum PrepText {
    static func preparing(_ name: String) -> String {
        name.isEmpty
            ? PageText.t(["Defterin hazırlanıyor", "Your notebook is getting ready", "Dein Heft wird vorbereitet", "Ton carnet se prépare", "Tu cuaderno se está preparando", "Il tuo quaderno si sta preparando", "Твоя тетрадь готовится", "你的笔记本正在准备"])
            : PageText.t(["\(name), defterin hazırlanıyor", "\(name), your notebook is getting ready", "\(name), dein Heft wird vorbereitet", "\(name), ton carnet se prépare", "\(name), tu cuaderno se está preparando", "\(name), il tuo quaderno si sta preparando", "\(name), твоя тетрадь готовится", "\(name)，你的笔记本正在准备"])
    }
    static func ready(_ name: String) -> String {
        name.isEmpty
            ? PageText.t(["Defterin hazır", "Your notebook is ready", "Dein Heft ist bereit", "Ton carnet est prêt", "Tu cuaderno está listo", "Il tuo quaderno è pronto", "Твоя тетрадь готова", "你的笔记本准备好了"])
            : PageText.t(["\(name), defterin hazır", "\(name), your notebook is ready", "\(name), dein Heft ist bereit", "\(name), ton carnet est prêt", "\(name), tu cuaderno está listo", "\(name), il tuo quaderno è pronto", "\(name), твоя тетрадь готова", "\(name)，你的笔记本准备好了"])
    }
    static var writing: String { PageText.t(["Sohbetin deftere yazılıyor", "Writing your chat into the notebook", "Dein Gespräch wird ins Heft geschrieben", "Ta conversation s'écrit dans le carnet", "Tu charla se escribe en el cuaderno", "La tua chiacchierata va nel quaderno", "Записываем разговор в тетрадь", "正在把对话写进笔记本"]) }
    static var chapter: String { PageText.t(["İlk bölüm hazırlanıyor", "Preparing your first chapter", "Dein erstes Kapitel wird vorbereitet", "Préparation du premier chapitre", "Preparando tu primer capítulo", "Preparo il primo capitolo", "Готовим первую главу", "正在准备第一章"]) }
    static var reminders: String { PageText.t(["Hatırlatmaların kuruluyor", "Setting up your reminders", "Deine Erinnerungen werden eingerichtet", "Tes rappels se mettent en place", "Configurando tus recordatorios", "Imposto i tuoi promemoria", "Настраиваем напоминания", "正在设置提醒"]) }
    static var writtenFinal: String { PageText.t(["İlk sohbetin 1. sayfada", "Your first chat is on page 1", "Dein erstes Gespräch steht auf Seite 1", "Ta première conversation est en page 1", "Tu primera charla está en la página 1", "La tua prima chiacchierata è a pagina 1", "Первый разговор на 1-й странице", "第一次对话在第 1 页"]) }
    static func chapterFinal(_ c: String) -> String { PageText.t(["İlk bölüm: \(c)", "First chapter: \(c)", "Erstes Kapitel: \(c)", "Premier chapitre : \(c)", "Primer capítulo: \(c)", "Primo capitolo: \(c)", "Первая глава: \(c)", "第一章：\(c)"]) }
    static var remindersFinal: String { PageText.t(["Lupa seni her gün bekleyecek", "Lupa will be waiting for you every day", "Lupa wartet jeden Tag auf dich", "Lupa t'attendra chaque jour", "Lupa te esperará cada día", "Lupa ti aspetterà ogni giorno", "Лупа будет ждать тебя каждый день", "Lupa 每天都会等你"]) }
    static var readyStamp: String { PageText.t(["Hazır", "Ready", "Bereit", "Prêt", "Listo", "Pronto", "Готово", "就绪"]) }
}
