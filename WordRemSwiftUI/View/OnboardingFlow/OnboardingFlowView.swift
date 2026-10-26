//
//  OnboardingFlowView.swift
//  WordRemSwiftUI
//
//  Kısa, Pingo tarzı onboarding: karşılama → öğrenilecek dil → ad →
//  canlı sesli demo (öğretmen adıyla karşılar, birkaç cümle konuşturur) → paywall → uygulama.
//  Seçimler dokununca kendiliğinden ilerler; ana dil telefondan gelir, istenirse değiştirilir.
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager

    private enum Step: Int { case welcome, language, name, demo }

    @State private var step: Step = .welcome
    @State private var forward = true
    @State private var native = OL.nativeLangCode
    @State private var target: String?
    @State private var name = ""
    @State private var showPaywall = false
    @State private var paywallSeen = false
    @State private var finished = false
    @FocusState private var nameFocused: Bool

    private static let flags: [String: String] = [
        "tr": "🇹🇷", "en": "🇬🇧", "de": "🇩🇪", "fr": "🇫🇷", "es": "🇪🇸", "it": "🇮🇹", "ru": "🇷🇺", "zh": "🇨🇳",
    ]

    private var targetName: String { langManager.languageName(for: target ?? "en") }

    var body: some View {
        VStack(spacing: 0) {
            if step == .language || step == .name { header }
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
        // Paywall hangi yoldan kapanırsa kapansın (X, satın alma, geri yükleme) onboarding biter → ana sayfa
        .fullScreenCover(isPresented: $showPaywall, onDismiss: finish) {
            OnboardingPaywallView { showPaywall = false }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:  welcome
        case .language: languageStep
        case .name:     nameStep
        case .demo:
            // Canlı sesli demo: öğretmen adıyla karşılar, birkaç cümle konuşturur → paywall
            VoiceTutorView(mode: .demo, onFinished: { _ in
                // Paywall bir kez görüldüyse demodaki X artık doğrudan ana sayfaya götürür
                if paywallSeen { finish() } else { paywallSeen = true; showPaywall = true }
            }, isDemo: true)
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
                ForEach(1...2, id: \.self) { i in
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
        savePreferences()          // öğretmen dili ve adı bilsin
        go(.demo)
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
        Task {
            _ = try? await DataService.shared.updateDailyLoginStreak()
            await MainActor.run { authManager.completeOnboarding() }
        }
    }
}
