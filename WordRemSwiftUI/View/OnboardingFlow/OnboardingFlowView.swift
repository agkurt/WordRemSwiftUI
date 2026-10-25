//
//  OnboardingFlowView.swift
//  WordRemSwiftUI
//
//  Kısa, Pingo tarzı onboarding: karşılama → öğrenilecek dil → ad → seviye → amaç →
//  öğretmen tanışması (sesli, kelime kelime altyazı) → paywall → uygulama.
//  Seçimler dokununca kendiliğinden ilerler; ana dil telefondan gelir, istenirse değiştirilir.
//

import AVFoundation
import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager

    private enum Step: Int { case welcome, language, name, level, goal, tutor }

    @State private var step: Step = .welcome
    @State private var forward = true
    @State private var native = OL.nativeLangCode
    @State private var target: String?
    @State private var name = ""
    @State private var level: Int?
    @State private var goal: Int?
    @State private var showPaywall = false
    @FocusState private var nameFocused: Bool

    private static let flags: [String: String] = [
        "tr": "🇹🇷", "en": "🇬🇧", "de": "🇩🇪", "fr": "🇫🇷", "es": "🇪🇸", "it": "🇮🇹", "ru": "🇷🇺", "zh": "🇨🇳",
    ]

    private var targetName: String { langManager.languageName(for: target ?? "en") }

    var body: some View {
        VStack(spacing: 0) {
            if step != .welcome && step != .tutor { header }
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
        .paperBackground()
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallView { showPaywall = false; finish() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:  welcome
        case .language: languageStep
        case .name:     nameStep
        case .level:    levelStep
        case .goal:     goalStep
        case .tutor:
            TutorIntroView(name: name, languageName: targetName, languageCode: target ?? "en") {
                savePreferences()
                showPaywall = true
            }
        }
    }

    private func go(_ next: Step) {
        forward = next.rawValue > step.rawValue
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { step = next }
    }

    /// Seçim vurgusu görünsün diye kısa gecikmeyle ilerle
    private func advance(after next: Step) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { go(next) }
    }

    // MARK: - Üst çubuk: geri + ilerleme
    private var header: some View {
        HStack(spacing: 14) {
            Button { go(Step(rawValue: step.rawValue - 1) ?? .welcome) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .frame(width: 40, height: 40)
            }
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { i in
                    Capsule()
                        .fill(i <= step.rawValue ? DS.Colors.accent : DS.Colors.line)
                        .frame(height: 5)
                }
            }
            .animation(.easeOut(duration: 0.3), value: step)
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
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
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 18)
    }

    // MARK: - 0. Karşılama
    private var welcome: some View {
        VStack(spacing: 0) {
            WordRemLogoText(size: 22).padding(.top, 16)
            Spacer()
            VoiceLogoView(phase: .aiSpeaking, level: 0.4)
                .scaleEffect(2.4)
                .frame(height: 120)
            Text(langManager.s(.obHeroTitle))
                .font(DS.Font.display(36, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 36)
            Text(langManager.s(.obHeroSub))
                .font(DS.Font.ui(17))
                .foregroundStyle(DS.Colors.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            Spacer()
            Button(langManager.s(.obLetsGo)) { go(.language) }
                .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
            nativeMenu.padding(.top, 14).padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    /// Ana dil telefondan gelir; yanlışsa buradan değiştirilir (arayüz dili de değişir)
    private var nativeMenu: some View {
        Menu {
            ForEach(LanguageManager.supportedCodes, id: \.self) { code in
                Button("\(Self.flags[code] ?? "") \(langManager.languageName(for: code))") {
                    native = code
                    langManager.setLanguage(code)
                    if target == code { target = nil }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(langManager.f(.obNativeIs, "\(Self.flags[native] ?? "") \(langManager.languageName(for: native))"))
                Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
            }
            .font(DS.Font.ui(14, weight: .medium))
            .foregroundStyle(DS.Colors.muted)
        }
    }

    // MARK: - 1. Öğrenilecek dil
    private var languageStep: some View {
        VStack(spacing: 0) {
            title(langManager.s(.whatToLearn))
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(LanguageManager.supportedCodes.filter { $0 != native }, id: \.self) { code in
                        optionRow(selected: target == code) {
                            Text(Self.flags[code] ?? "").font(.system(size: 26)).frame(width: 36)
                            Text(langManager.languageName(for: code))
                        } action: {
                            target = code
                            advance(after: .name)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - 2. Ad
    private var nameStep: some View {
        VStack(spacing: 0) {
            title(langManager.s(.obNameTitle), langManager.s(.obNameSub))
            TextField(langManager.s(.obNamePlaceholder), text: $name)
                .font(DS.Font.display(28, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($nameFocused)
                .onSubmit(submitName)
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.accent).frame(height: 2) }
                .padding(.horizontal, 24)
            Spacer()
            Button(langManager.s(.continueButton), action: submitName)
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
        go(.level)
    }

    // MARK: - 3. Seviye
    private var levelStep: some View {
        VStack(spacing: 0) {
            title(langManager.f(.howMuchFormat, targetName))
            VStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    optionRow(selected: level == i) {
                        Image("level\(i + 1)").resizable().scaledToFit().frame(width: 30, height: 30)
                        Text(langManager.s([.level1, .level2, .level3, .level4][i]))
                    } action: {
                        level = i
                        advance(after: .goal)
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    // MARK: - 4. Amaç
    private var goals: [(label: String, asset: String)] {
        [
            (langManager.s(.interestTravel), "travel"),
            (langManager.s(.interestCareer), "career"),
            (langManager.s(.interestEducation), "education"),
            (langManager.s(.interestDaily), "daily"),
            (langManager.s(.interestFunCulture), "funandculture"),
            (langManager.s(.interestFamily), "friendsandfamily"),
        ]
    }

    private var goalStep: some View {
        VStack(spacing: 0) {
            title(langManager.f(.interestQuestion, targetName))
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(goals.indices, id: \.self) { i in
                        Button {
                            goal = i
                            advance(after: .tutor)
                        } label: {
                            VStack(spacing: 10) {
                                Image(goals[i].asset).resizable().scaledToFit().frame(height: 52)
                                Text(goals[i].label)
                                    .font(DS.Font.ui(15, weight: .semibold))
                                    .foregroundStyle(DS.Colors.ink)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .modifier(OBSelectableCard(isSelected: goal == i))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Ortak seçenek satırı
    private func optionRow<Label: View>(selected: Bool, @ViewBuilder label: () -> Label,
                                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                label()
                    .font(DS.Font.ui(17, weight: .medium))
                    .foregroundStyle(DS.Colors.ink)
                Spacer()
                OBCheckmark(isSelected: selected)
            }
            .modifier(OBSelectableCard(isSelected: selected))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Kaydet & bitir
    private func savePreferences() {
        let code = target ?? "en"
        let interest = goal.map { goals[$0].label } ?? ""
        let d = UserDefaults.standard
        d.set(code, forKey: "selectedTargetLanguageCode")
        d.set(langManager.languageName(for: code), forKey: "selectedTargetLanguageName")
        d.set(level ?? 0, forKey: "selectedProficiencyLevel")
        d.set(10, forKey: "dailyGoalMinutes")
        if !interest.isEmpty { d.set(interest, forKey: "learningInterest") }
        langManager.setLanguage(native)
        if !trimmedName.isEmpty { DataService.shared.updateUsername(trimmedName) }
        Task {
            try? await DataService.shared.saveUserPreferences(
                targetLangCode: code, nativeLangCode: native, proficiencyLevel: level ?? 0,
                learningInterest: interest, dailyGoalMinutes: 10)
        }
    }

    private func finish() {
        Task {
            _ = try? await DataService.shared.updateDailyLoginStreak()
            await MainActor.run { authManager.completeOnboarding() }
        }
    }
}

// MARK: - Öğretmen tanışması: logo konuşur, altyazı sesle kelime kelime açılır
private struct TutorIntroView: View {
    @EnvironmentObject var langManager: LanguageManager
    let name: String
    let languageName: String
    let languageCode: String
    var onReady: () -> Void

    @StateObject private var speaker = GreetingSpeaker()
    @State private var showButton = false

    private var greeting: String {
        let code = langManager.currentLanguageCode
        let lang = ["fr", "es", "it", "ru"].contains(code) ? languageName.lowercased() : languageName
        return langManager.s(.obTutorGreeting)
            .replacingOccurrences(of: "{name}", with: name.isEmpty ? "👋" : name)
            .replacingOccurrences(of: "{lang}", with: lang)
    }

    var body: some View {
        VStack(spacing: 0) {
            VoiceLogoView(phase: speaker.isSpeaking ? .aiSpeaking : .listening, level: 0.2)
                .scaleEffect(1.6)
                .frame(height: 70)
                .padding(.top, 40)
            Spacer()
            captionText
                .font(DS.Font.ui(24, weight: .medium))
                .lineSpacing(7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .animation(.easeOut(duration: 0.15), value: speaker.spoken)
            Spacer()
            Button(langManager.s(.obReady)) {
                speaker.stop()
                onReady()
            }
            .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showButton)
        }
        .onAppear {
            speaker.speak(greeting, nativeCode: langManager.currentLanguageCode)
            // Konuşma bitince (ya da en geç 5 sn sonra) düğme belirir
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { showButton = true }
        }
        .onChange(of: speaker.finished) { done in if done { showButton = true } }
        .onDisappear { speaker.stop() }
    }

    /// Söylenen kelimeler koyu, sıradaki kelime soluk
    private var captionText: Text {
        let full = greeting
        let shown = String(full.prefix(speaker.spoken))
        let rest = full.dropFirst(shown.count)
        let next = rest.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
        return Text(shown).foregroundColor(DS.Colors.ink) + Text(next).foregroundColor(DS.Colors.muted.opacity(0.45))
    }
}

/// Cihaz içi seslendirme (ücretsiz, mikrofon izni gerekmez); söylenen kelimeyi yayınlar
@MainActor
private final class GreetingSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var spoken = 0
    @Published var isSpeaking = false
    @Published var finished = false

    private let synth = AVSpeechSynthesizer()
    private var text = ""
    private var fallback: Timer?
    private var started = false   // seslendirme gerçekten başladı mı

    func speak(_ text: String, nativeCode: String) {
        self.text = text
        synth.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        let u = AVSpeechUtterance(string: text)
        u.voice = Self.bestVoice(for: nativeCode)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.98
        u.preUtteranceDelay = 0.4
        synth.speak(u)
        isSpeaking = true

        // Altyazı sesi bekler (kelimeler seslendirme ilerledikçe açılır). Ses 2.5 sn içinde hiç başlamazsa
        // (sessiz mod vb.) altyazı okuma hızında kendiliğinden akar.
        let start = Date()
        fallback = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.started else { return }
                let waited = Date().timeIntervalSince(start) - 2.5
                guard waited > 0 else { return }
                self.reveal(upTo: Int(waited * 14))
                if self.spoken >= self.text.count { self.complete() }
            }
        }
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        fallback?.invalidate()
        isSpeaking = false
    }

    private func reveal(upTo n: Int) {
        let n = min(n, text.count)
        // kelime sınırına yuvarla
        if n < text.count, let sp = text.prefix(n).lastIndex(of: " ") {
            spoken = max(spoken, text.distance(from: text.startIndex, to: sp) + 1)
        } else {
            spoken = max(spoken, n)
        }
    }

    private func complete() {
        spoken = text.count
        isSpeaking = false
        finished = true
        fallback?.invalidate()
    }

    private static func bestVoice(for code: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.lowercased().hasPrefix(code.lowercased()) }
        return voices.max { $0.quality.rawValue < $1.quality.rawValue } ?? AVSpeechSynthesisVoice(language: code)
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange, utterance: AVSpeechUtterance) {
        let end = r.location + r.length
        Task { @MainActor in
            // söylenen kelimenin sonuna kadar aç (UTF-16 → karakter)
            let ns = self.text as NSString
            let upTo = (ns.substring(to: min(end, ns.length)) as String).count
            self.spoken = max(self.spoken, upTo)
        }
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.started = true }
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.complete() }
    }
}
