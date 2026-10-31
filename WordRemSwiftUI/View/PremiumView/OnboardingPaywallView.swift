//
//  OnboardingPaywallView.swift
//  WordRemSwiftUI
//
//  Defter görünümlü paywall: 1) değer (kişisel söz, 30 gün önce/sonra, gerçek yorumlar)
//  2) plan (yıllık seçili, tasarruf mührü, deneme takvimi) 3) deneme hatırlatma sözü.
//  `isHard`: kapatma yok — yalnızca satın alma / geri yükleme ile geçilir.
//

import SwiftUI
import RevenueCat
import SafariServices
import UserNotifications

struct OnboardingPaywallView: View {

    @EnvironmentObject var langManager: LanguageManager
    var onContinue: () -> Void
    /// Paywall'un nereden açıldığı (analitik): onboarding, lesson_limit, profile, ai_quiz, grammar_voice, launch_gate
    var entryPoint: String = "other"
    /// Sert paywall: X yok, aşağı kaydırarak kapanmaz; yalnızca satın alma / geri yükleme ile geçilir
    var isHard: Bool = false

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var plans: [SubscriptionPlan] = []
    @State private var selectedId: String?
    @State private var fetchAttempts: Int = 0
    @State private var fetchFailed: Bool = false
    @State private var isLoading: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPurchaseErrorAlert: Bool = false
    @State private var showWelcomePro: Bool = false
    @State private var restoreMessage: String?
    /// 0: değer · 1: plan seçimi · 2: deneme hatırlatma sözü (yalnızca deneme varsa)
    @State private var step = 0
    @State private var visit: Track.PaywallVisit?
    @State private var purchased = false
    /// Satın alma / geri yükleme sürerken Pro durumu değişirse paywall kendiliğinden kapanmasın (Hoş geldin ekranı gelsin)
    @State private var transactionInFlight = false
    @State private var ctaPulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.paper.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        switch step {
                        case 0:  valueStep
                        case 1:  planStep
                        default: reminderStep
                        }
                        // Apple: gizlilik, kullanım şartları ve abonelik açıklaması her adımda görünür
                        legalFooter.padding(.top, 12)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                .id(step)   // adım değişince sayfanın başından başla
                .scrollBounceBehavior(.basedOnSize)
                // Ana düğme hep görünür: kaydırmaya gerek yok
                .safeAreaInset(edge: .bottom, spacing: 0) { ctaBar }

                if isLoading {
                    Color.black.opacity(0.25).ignoresSafeArea()
                        .overlay(ProgressView().tint(.white).scaleEffect(1.4))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if step > 0 {
                        Button { withAnimation { step -= 1 } } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(DS.Colors.inkSoft)
                        }
                    } else if !isHard {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            onContinue()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(DS.Colors.inkSoft)
                        }
                    } else {
                        debugSkip
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(langManager.s(.paywallRestore)) { restorePurchases() }
                        .font(DS.Font.ui(14, weight: .medium))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
            }
        }
        .interactiveDismissDisabled(isHard)
        .onAppear {
            if visit == nil {
                let v = Track.PaywallVisit(entryPoint: entryPoint)
                visit = v
                Track.paywall("view", v, step: 0)
            }
            fetchPlans()
        }
        // Hangi yoldan kapanırsa kapansın: ne kadar kaldı, nereye kadar geldi, hangi plana bakıyordu
        .onDisappear {
            if let visit, !purchased { Track.paywall("close", visit, step: step, plan: selectedPlan) }
        }
        .onChange(of: step) { newStep in
            if let visit { Track.paywall("step_view", visit, step: newStep, plan: selectedPlan) }
            updatePulse(on: newStep == 2)
        }
        // Sert paywall: Pro durumu başka yoldan geldiyse (geç gelen senkron, başka cihazda alım) hemen içeri al
        .onReceive(InAppPurchaseManager.shared.$isPremium) { premium in
            guard isHard, premium, !purchased, !transactionInFlight, !showWelcomePro else { return }
            purchased = true
            onContinue()
        }
        .alert(langManager.s(.paywallRestoreTitle), isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button(langManager.s(.paywallOk), role: .cancel) { restoreMessage = nil }
        } message: {
            Text(restoreMessage ?? "")
        }
        .alert(langManager.s(.paywallPurchaseFailed), isPresented: $showPurchaseErrorAlert) {
            Button(langManager.s(.paywallOk), role: .cancel) {}
        } message: {
            Text(langManager.s(.paywallPurchaseError))
        }
        .sheet(isPresented: $showPrivacy) {
            SafariWebView(url: URL(string: "https://api.wordremai.app/privacy")!)
        }
        .sheet(isPresented: $showTerms) {
            SafariWebView(url: URL(string: "https://api.wordremai.app/terms")!)
        }
        .fullScreenCover(isPresented: $showWelcomePro) {
            WelcomeProView {
                showWelcomePro = false
                presentationMode.wrappedValue.dismiss()
                onContinue()
            }
            .environmentObject(langManager)
        }
    }

    /// Yalnızca Debug: sert paywall'u geçmek için (test cihazı Pro değilken DebugDriver akışları çalışsın)
    @ViewBuilder
    private var debugSkip: some View {
        #if DEBUG
        Button {
            UserDefaults.standard.set(true, forKey: "debugSkipPaywall")
            onContinue()
        } label: {
            Text("DEBUG ›")
                .font(DS.Font.ui(12, weight: .semibold))
                .foregroundStyle(DS.Colors.muted)
        }
        #endif
    }

    // MARK: - Kişiselleştirme
    private var learnerName: String? {
        let n = UserStore.shared.snapshot.username.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? nil : n
    }

    private var targetLanguageName: String {
        langManager.languageName(for: LearningLanguages.current)
    }

    private var heroTitle: String {
        if let name = learnerName { return AL.f(.pwxHeroName, name) }
        return AL.s(.pwxHero)
    }

    /// Önce → sonra: öğrencinin eski şikâyeti kırmızı kalemle çizilir, yerine yenisi yazılır
    private var outcomes: [(before: String, after: String)] {
        [
            (AL.s(.pwxBefore1), AL.s(.pwxAfter1)),
            (AL.s(.pwxBefore2), AL.s(.pwxAfter2)),
            (AL.s(.pwxBefore3), AL.s(.pwxAfter3)),
        ]
    }

    // MARK: - Alt çubuk: adım adım ana düğme
    private var ctaBar: some View {
        VStack(spacing: 8) {
            Button(action: primaryAction) {
                HStack(spacing: 8) {
                    Text(primaryTitle)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .buttonStyle(PaywallHeroButtonStyle(tall: step == 2))
            .scaleEffect(ctaPulse ? 1.025 : 1)
            .disabled(primaryDisabled)
            .opacity(primaryDisabled ? 0.4 : 1)

            Text(primarySubtitle)
                .font(DS.Font.ui(13))
                .foregroundStyle(DS.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            if step == 1, selectedPlan?.trialDays != nil {
                Label(AL.s(.paywallTLReminderSub), systemImage: "bell")
                    .font(DS.Font.ui(12, weight: .medium))
                    .foregroundStyle(DS.Colors.accentText)
            } else if step == 2 {
                Label(AL.s(.paywallEasyCancel), systemImage: "checkmark")
                    .font(DS.Font.ui(12, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background {
            DS.Colors.paper
                .overlay(alignment: .top) { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var primaryTitle: String {
        step == 0 ? AL.s(.pwxCtaValue) : ctaTitle
    }

    private var primaryDisabled: Bool {
        step > 0 && (selectedPlan == nil || isLoading)
    }

    private var primarySubtitle: String {
        if step == 0 {
            if let days = selectedPlan?.trialDays { return AL.f(.pwxFreeNoPay, days) }
            return AL.s(.paywallNoCommit)
        }
        return ctaSubtitle
    }

    private func primaryAction() {
        switch step {
        case 0:
            withAnimation { step = 1 }
        case 1:
            if let visit { Track.paywall("cta_tap", visit, step: step, plan: selectedPlan) }
            if selectedPlan?.trialDays != nil { withAnimation { step = 2 } } else { purchaseSelected() }
        default:
            purchaseSelected()
        }
    }

    /// 3. adımda ana düğme hafifçe nefes alır (hareket azaltma açıksa durur)
    private func updatePulse(on: Bool) {
        if on && !reduceMotion {
            // Sayfa geçişi bittikten sonra başlasın (sonsuz animasyon geçişe karışmasın)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard step == 2, !ctaPulse else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { ctaPulse = true }
            }
        } else {
            withAnimation(.easeOut(duration: 0.15)) { ctaPulse = false }
        }
    }

    // MARK: - Adım 1: değer
    private var valueStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Eyebrow(text: "WordRem Pro · \(targetLanguageName)", color: DS.Colors.accentText)
                    .padding(.top, 16)
                Spacer(minLength: 12)
                BookmarkMark(width: 9)
            }

            Text(heroTitle)
                .font(DS.Font.display(34, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            Text(AL.s(.paywallHeroVoice))
                .font(.system(size: 18, design: .serif).italic())
                .foregroundStyle(DS.Colors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            Text(AL.s(.pwx30Days))
                .font(DS.Font.display(21, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .padding(.top, 30)
                .padding(.bottom, 2)
            outcomeList

        }
    }

    /// Kırmızı kalemle çizilmiş eski hal → kalem tikiyle yeni hal
    private var outcomeList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(outcomes.enumerated()), id: \.offset) { i, o in
                HStack(alignment: .top, spacing: 14) {
                    PenTick()
                        .stroke(DS.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(width: 24, height: 20)
                        .padding(.top, 24)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(o.before)
                            .font(.system(size: 15, design: .serif).italic())
                            .strikethrough(true, color: DS.Colors.redPen)
                            .foregroundStyle(DS.Colors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(o.after)
                            .font(DS.Font.ui(17, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 13)
                .overlay(alignment: .bottom) {
                    if i < outcomes.count - 1 { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
                }
            }
        }
    }

    // MARK: - Adım 2: plan seçimi
    private var planStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AL.s(.paywallChoosePlan))
                .font(DS.Font.display(32, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .padding(.top, 16)
                .padding(.bottom, 30)

            Group {
                if !plans.isEmpty {
                    VStack(spacing: 16) {
                        ForEach(plans) { plan in planCard(plan) }
                    }
                } else if fetchFailed {
                    VStack(spacing: 8) {
                        Text(langManager.s(.paywallPriceFailed))
                            .font(DS.Font.ui(15, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                        Button { fetchAttempts = 0; fetchPlans() } label: {
                            Text(langManager.s(.paywallRetry))
                                .font(DS.Font.ui(15, weight: .semibold))
                                .foregroundStyle(DS.Colors.accent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                } else {
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .fill(DS.Colors.paperSunken)
                        .frame(height: 150)
                        .overlay(ProgressView().tint(DS.Colors.muted))
                }
            }
            .padding(.bottom, 20)

            if let days = selectedPlan?.trialDays {
                trialTeaser(days: days).padding(.bottom, 22)
            }

        }
    }

    /// Deneme takvimi önizlemesi: bugün ücretsiz → hatırlatma → ilk ödeme
    private func trialTeaser(days: Int) -> some View {
        let items: [(day: String, text: String)] = [
            (AL.s(.paywallTLToday), AL.s(.pwxTLFree)),
            (AL.f(.paywallTLDay, max(1, days - 2)), AL.s(.pwxTLRemind)),
            (AL.f(.paywallTLDay, days), AL.s(.pwxTLCharge)),
        ]
        return HStack(alignment: .top, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(i == 0 ? DS.Colors.accent : (i == 1 ? DS.Colors.margin : DS.Colors.muted))
                            .frame(width: 10, height: 10)
                        if i < items.count - 1 {
                            Rectangle().fill(DS.Colors.line).frame(height: 2)
                        } else {
                            Spacer(minLength: 0)
                        }
                    }
                    Text(item.day)
                        .font(.system(size: 14, design: .serif).italic())
                        .foregroundStyle(i == 2 ? DS.Colors.muted : DS.Colors.accentText)
                    Text(item.text)
                        .font(DS.Font.ui(12, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Adım 3: hatırlatma sözü
    private var reminderStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AL.s(.paywallReminderHeadline))
                .font(DS.Font.display(32, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
                .padding(.bottom, 24)
            if let days = selectedPlan?.trialDays {
                trialTimeline(days: days).padding(.bottom, 30)
            }
            if let plan = selectedPlan, let days = plan.trialDays {
                dueNote(plan, days: days).padding(.bottom, 26)
            }
            Text(AL.s(.pwxReady))
                .font(.system(size: 17, design: .serif).italic())
                .foregroundStyle(DS.Colors.accentText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
        }
        .onAppear { updatePulse(on: true) }
    }

    /// "Bugün ödenecek ........ 0" — denemenin gerçekten ücretsiz olduğunu açıkça yazar
    private func dueNote(_ plan: SubscriptionPlan, days: Int) -> some View {
        let chargeDay = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        let dateText = chargeDay.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode)))
        return StickyNote(angle: -1) {
            VStack(alignment: .leading, spacing: 14) {
                LeaderRow(label: AL.s(.pwxDueToday),
                          value: formatted(0, like: plan) ?? "0",
                          size: 19,
                          valueColor: DS.Colors.success)
                LeaderRow(label: AL.f(.pwxFromDate, dateText),
                          value: periodPrice(plan),
                          size: 16,
                          labelColor: DS.Colors.inkSoft,
                          valueColor: DS.Colors.inkSoft)
            }
        }
    }

    private var legalFooter: some View {
        VStack(spacing: 10) {
            HStack(spacing: 20) {
                legalButton(langManager.s(.paywallPrivacy)) {
                    if let visit { Track.paywall("legal_open", visit, step: step, legalDoc: "privacy") }
                    showPrivacy = true
                }
                legalButton(langManager.s(.paywallTerms)) {
                    if let visit { Track.paywall("legal_open", visit, step: step, legalDoc: "terms") }
                    showTerms = true
                }
            }
            Text(langManager.s(.paywallDisclosure))
                .font(DS.Font.ui(11))
                .foregroundStyle(DS.Colors.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
    }

    // MARK: - Legal Button
    private func legalButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DS.Font.ui(13, weight: .medium))
                .foregroundStyle(DS.Colors.inkSoft)
                .underline(color: DS.Colors.line)
        }
    }

    // MARK: - Plan helpers
    private var selectedPlan: SubscriptionPlan? { plans.first { $0.id == selectedId } }
    private var weeklyPlan: SubscriptionPlan? { plans.first { $0.product.subscriptionPeriod?.unit == .week } }
    private var monthlyPlan: SubscriptionPlan? { plans.first { $0.product.subscriptionPeriod?.unit == .month } }

    /// Yıllığın karşılaştırma fiyatı: aylık plan × 12 (yoksa haftalık × 52) — gerçek bir fiyat
    private func yearlyEquivalent() -> Decimal? {
        if let m = monthlyPlan { return m.product.price * 12 }
        if let w = weeklyPlan { return w.product.price * 52 }
        return nil
    }

    private func formatted(_ amount: Decimal, like plan: SubscriptionPlan) -> String? {
        plan.product.priceFormatter?.string(from: NSDecimalNumber(decimal: amount))
    }

    /// Yıllık planın haftalığa göre tasarruf yüzdesi
    private func savingsPercent(_ plan: SubscriptionPlan) -> Int? {
        guard plan.isAnnual, let yearly = yearlyEquivalent(), yearly > 0 else { return nil }
        let ratio = NSDecimalNumber(decimal: plan.product.price / yearly).doubleValue
        let pct = Int((1 - ratio) * 100)
        return pct >= 10 ? pct : nil
    }

    /// Dile göre yüzde: "62%", "%62", "62 %"
    private func percentText(_ pct: Int) -> String {
        (Double(pct) / 100).formatted(.percent.precision(.fractionLength(0)).locale(Locale(identifier: AL.currentCode)))
    }

    private func periodPrice(_ plan: SubscriptionPlan) -> String {
        if plan.isAnnual { return AL.f(.paywallPerYear, plan.product.localizedPriceString) }
        if plan.isMonthly { return AL.f(.paywallPerMonth, plan.product.localizedPriceString) }
        return langManager.f(.paywallPerWeek, plan.product.localizedPriceString)
    }

    private var ctaTitle: String {
        if let days = selectedPlan?.trialDays { return AL.f(.paywallStartTrial, days) }
        return langManager.s(.paywallContinue)
    }

    private var ctaSubtitle: String {
        guard let plan = selectedPlan else { return " " }
        if let days = plan.trialDays {
            return String(format: AL.s(.paywallTrialThen), days, plan.product.localizedPriceString)
        }
        return AL.s(.paywallNoCommit)
    }

    @ViewBuilder
    private func planCard(_ plan: SubscriptionPlan) -> some View {
        let selected = plan.id == selectedId
        let saving = savingsPercent(plan)
        Button {
            if selectedId != plan.id, let visit {
                visit.planSwitches += 1
                Track.paywall("plan_select", visit, step: step, plan: plan)
            }
            if selectedId != plan.id { Haptics.tap() }
            selectedId = plan.id
        } label: {
            HStack(alignment: plan.isAnnual ? .top : .center, spacing: 14) {
                Circle()
                    .strokeBorder(selected ? DS.Colors.ink : Color(hex: "#B8B0A4"), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().fill(DS.Colors.accent).frame(width: 12, height: 12).opacity(selected ? 1 : 0))
                    .padding(.top, plan.isAnnual ? 2 : 0)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.isAnnual ? AL.s(.paywallAnnual) : (plan.isMonthly ? AL.s(.paywallMonthlyPlan) : AL.s(.paywallWeeklyPlan)))
                            .font(DS.Font.display(20, weight: plan.isAnnual ? .bold : .semibold))
                            .foregroundStyle(DS.Colors.ink)
                        if let days = plan.trialDays {
                            Text(AL.f(.paywallTrialBadge, days))
                                .font(DS.Font.ui(11, weight: .semibold))
                                .foregroundStyle(DS.Colors.accentText)
                        }
                    }
                    if plan.isAnnual {
                        // Apple: faturalanan tutar en belirgin fiyat olmalı; haftalık karşılığı fosforlu kalemle altında
                        Text(periodPrice(plan))
                            .font(DS.Font.display(24, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .padding(.top, 2)
                        if let perWeek = plan.product.localizedPricePerWeek {
                            highlightedText(AL.f(.paywallWeeklyEquiv, perWeek))
                                .font(DS.Font.ui(15, weight: .semibold))
                                .foregroundStyle(DS.Colors.ink)
                        }
                        if monthlyPlan != nil, let y = yearlyEquivalent(), y > plan.product.price, let f = formatted(y, like: plan) {
                            HStack(spacing: 6) {
                                Text(f)
                                    .font(DS.Font.ui(13, weight: .medium))
                                    .strikethrough(true, color: DS.Colors.redPen)
                                    .foregroundStyle(DS.Colors.muted)
                                Text(AL.s(.pwxVsMonthly))
                                    .font(DS.Font.ui(13))
                                    .foregroundStyle(DS.Colors.muted)
                            }
                            .padding(.top, 2)
                        }
                    } else {
                        Text(plan.isMonthly ? AL.s(.paywallMonthlyTerm) : langManager.s(.paywallWeeklyTerm))
                            .font(DS.Font.ui(13))
                            .foregroundStyle(DS.Colors.muted)
                    }
                }
                Spacer(minLength: 8)
                if !plan.isAnnual {
                    Text(periodPrice(plan))
                        .font(DS.Font.display(18, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(18)
            .padding(.top, plan.isAnnual && saving == nil ? 8 : 0)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(selected ? DS.Colors.ink : DS.Colors.line, lineWidth: selected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                // Gerçek tasarruf (aylık × 12'ye göre) sayfaya basılmış mühür olarak
                if plan.isAnnual, let saving {
                    InkStamp(top: AL.s(.pwxStampSave).uppercased(with: Locale(identifier: AL.currentCode)),
                             title: percentText(saving),
                             bottom: AL.s(.paywallAnnual).uppercased(with: Locale(identifier: AL.currentCode)),
                             size: 92,
                             angle: -12)
                        .background(Circle().fill(DS.Colors.paper.opacity(0.92)))
                        .offset(x: 8, y: -30)
                }
            }
            .overlay(alignment: .topLeading) {
                // Tasarruf hesaplanamazsa küçük "en avantajlı" etiketi
                if plan.isAnnual, saving == nil {
                    Text(AL.s(.paywallBestValue).uppercased(with: Locale(identifier: AL.currentCode)))
                        .font(DS.Font.ui(10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(DS.Colors.accentText)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(DS.Colors.paper, in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(DS.Colors.accent, lineWidth: 1.5))
                        .rotationEffect(.degrees(-4))
                        .offset(x: 16, y: -12)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// Bugün → hatırlatma (bitişten 2 gün önce) → ücretlendirme: günlük sayfası gibi, tarih kenar boşluğunda
    private func trialTimeline(days: Int) -> some View {
        let steps: [(day: String, text: String)] = [
            (AL.s(.paywallTLToday), AL.s(.paywallTLTodaySub)),
            (AL.f(.paywallTLDay, max(1, days - 2)), AL.s(.paywallTLReminderSub)),
            (AL.f(.paywallTLDay, days), AL.s(.paywallTLChargeSub)),
        ]
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(step.day)
                        .font(.system(size: 16, design: .serif).italic())
                        .foregroundStyle(index == 2 ? DS.Colors.muted : DS.Colors.accentText)
                        .frame(width: 64, alignment: .trailing)
                    Text(step.text)
                        .font(DS.Font.ui(16, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 16)
                .overlay(alignment: .bottom) {
                    if index < steps.count - 1 { Rectangle().fill(DS.Colors.rule).frame(height: 1) }
                }
            }
        }
        .background(alignment: .leading) {
            Rectangle().fill(DS.Colors.margin).frame(width: 1.5).padding(.leading, 71)
        }
    }

    // MARK: - Actions
    private func fetchPlans() {
        fetchFailed = false
        fetchAttempts += 1
        Task { @MainActor in
            let result = await InAppPurchaseManager.shared.fetchPlans()
            if !result.isEmpty {
                plans = result
                if selectedId == nil { selectedId = result.first?.id }   // yıllık önce gelir
            } else if fetchAttempts < 3 {
                // Ağ / StoreKit geçici hatalarında sessizce tekrar dene
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                fetchPlans()
            } else {
                fetchFailed = true
                if let visit { Track.paywall("plans_load_fail", visit, step: step) }
            }
        }
    }

    private func purchaseSelected() {
        guard let plan = selectedPlan else { return }
        isLoading = true
        transactionInFlight = true
        let visit = visit
        if let visit { Track.paywall("purchase_start", visit, step: step, plan: plan) }
        InAppPurchaseManager.shared.purchase(product: plan.product) { outcome in
            DispatchQueue.main.async { self.isLoading = false }
            switch outcome {
            case .success(let transactionId):
                DispatchQueue.main.async {
                    self.purchased = true
                    if let visit {
                        Track.paywall("purchase_success", visit, step: self.step, plan: plan)
                        Track.purchase(plan, visit, transactionId: transactionId)
                    }
                }
                if let days = plan.trialDays { scheduleTrialReminder(trialDays: days) }
                DispatchQueue.main.async { self.showWelcomePro = true }
            case .cancelled:
                DispatchQueue.main.async {
                    self.transactionInFlight = false
                    if let visit { Track.paywall("purchase_cancel", visit, step: self.step, plan: plan) }
                }
            case .failed(let code):
                DispatchQueue.main.async {
                    self.transactionInFlight = false
                    if let visit { Track.paywall("purchase_fail", visit, step: self.step, plan: plan, error: code) }
                }
                DispatchQueue.main.async { self.showPurchaseErrorAlert = true }
            }
        }
    }

    /// Paywall'da verilen sözü tutar: deneme bitmeden 2 gün önce yerel bildirim
    private func scheduleTrialReminder(trialDays: Int) {
        guard trialDays > 2 else { return }
        let content = UNMutableNotificationContent()
        content.title = AL.s(.paywallTrialReminderTitle)
        content.body = AL.s(.paywallTrialReminderBody)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval((trialDays - 2) * 86_400), repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "wordrem.trial_reminder", content: content, trigger: trigger))
    }

    private func restorePurchases() {
        isLoading = true
        transactionInFlight = true
        if let visit { Track.paywall("restore_start", visit, step: step) }
        InAppPurchaseManager.shared.restorePurchases { result in
            DispatchQueue.main.async { self.isLoading = false }
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.purchased = true
                    if let visit = self.visit { Track.paywall("restore_success", visit, step: self.step) }
                    self.showWelcomePro = true
                }
            case .failure:
                DispatchQueue.main.async {
                    self.transactionInFlight = false
                    if let visit = self.visit { Track.paywall("restore_fail", visit, step: self.step) }
                    self.restoreMessage = langManager.s(.paywallRestoreNothing)
                }
            }
        }
    }
}

/// Paywall'un ana düğmesi: imza renginde, biraz daha iri; son adımda daha da büyük
private struct PaywallHeroButtonStyle: ButtonStyle {
    var tall = false
    // RevenueCat'in Configuration tipiyle karışmasın diye tam ad
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(DS.Font.ui(tall ? 19 : 18, weight: .bold))
            .foregroundStyle(DS.Colors.paperRaised)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: tall ? 64 : 58)
            .background(DS.Colors.accent, in: RoundedRectangle(cornerRadius: DS.Radius.button))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - SafariWebView
struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    OnboardingPaywallView(onContinue: {})
        .environmentObject(LanguageManager.shared)
}
