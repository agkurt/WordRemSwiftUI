//
//  OnboardingPaywallView.swift
//  WordRemSwiftUI
//

import SwiftUI
import RevenueCat
import SafariServices
import UserNotifications

struct OnboardingPaywallView: View {

    @EnvironmentObject var langManager: LanguageManager
    var onContinue: () -> Void

    @Environment(\.presentationMode) var presentationMode

    @State private var plans: [SubscriptionPlan] = []
    @State private var selectedId: String?
    @State private var fetchAttempts: Int = 0
    @State private var fetchFailed: Bool = false
    @State private var isLoading: Bool = false
    @State private var isCloseVisible: Bool = true
    @State private var showPrivacy: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPurchaseErrorAlert: Bool = false
    @State private var showWelcomePro: Bool = false
    @State private var restoreMessage: String?

    // (SF Symbol, title, subtitle) — Pro'nun gerçekten açtığı özellikler
    // AI satırları yalnızca Apple Intelligence olan cihazlarda gösterilir (vaat edilen her şey çalışmalı)
    private var features: [(String, String, String)] {
        var list = [
            ("infinity",  langManager.s(.paywallFeature1), langManager.s(.paywallFeature1Sub)),
            ("lightbulb", langManager.s(.paywallFeature2), langManager.s(.paywallFeature2Sub)),
        ]
        if AIEngine.isAvailable {
            list += [
                ("list.bullet.rectangle", langManager.s(.paywallFeature3), langManager.s(.paywallFeature3Sub)),
                ("waveform",              langManager.s(.paywallFeature4), langManager.s(.paywallFeature4Sub)),
            ]
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.paper.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Hero ───────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: "WordRem Pro")
                        Text(langManager.s(.paywallSubtitle))
                            .font(DS.Font.display(34, weight: .bold))
                            .foregroundStyle(DS.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                    // ── Features ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(features, id: \.0) { symbol, title, subtitle in
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: symbol)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(DS.Colors.accent)
                                    .frame(width: 24)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(title)
                                        .font(DS.Font.ui(17, weight: .semibold))
                                        .foregroundStyle(DS.Colors.ink)
                                    Text(subtitle)
                                        .font(DS.Font.ui(14))
                                        .foregroundStyle(DS.Colors.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 14)
                            if symbol != features.last?.0 {
                                Rectangle().fill(DS.Colors.line).frame(height: 1)
                            }
                        }
                    }
                    .padding(.bottom, 28)

                    // ── Plans ──────────────────────────────────────────
                    Group {
                        if !plans.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(plans) { plan in
                                    planCard(plan)
                                }
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

                    // ── Trial timeline (only when a free trial applies) ──
                    if let days = selectedPlan?.trialDays, days >= 3 {
                        trialTimeline(days: days)
                            .padding(.bottom, 20)
                    }

                    // ── Purchase Button ────────────────────────────────
                    Button(ctaTitle, action: purchaseSelected)
                        .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                        .disabled(selectedPlan == nil || isLoading)
                        .opacity(selectedPlan == nil ? 0.4 : 1)
                        .padding(.bottom, 8)

                    Text(ctaSubtitle)
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)

                    // ── Legal ──────────────────────────────────────────
                    HStack(spacing: 20) {
                        legalButton(langManager.s(.paywallPrivacy)) { showPrivacy = true }
                        legalButton(langManager.s(.paywallTerms))   { showTerms = true }
                        legalButton(langManager.s(.paywallRestore)) { restorePurchases() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)

                    // ── Auto-renewal Disclosure (Apple requirement) ─────
                    Text(langManager.s(.paywallDisclosure))
                        .font(DS.Font.ui(11))
                        .foregroundStyle(DS.Colors.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                }

                if isLoading {
                    Color.black.opacity(0.25).ignoresSafeArea()
                        .overlay(ProgressView().tint(.white).scaleEffect(1.4))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isCloseVisible {
                        Button {
                            EventManager.shared.logPaywallEvent("close_tapped")
                            presentationMode.wrappedValue.dismiss()
                            onContinue()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(DS.Colors.inkSoft)
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchPlans()
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
            SafariWebView(url: URL(string: "https://sites.google.com/view/wordremprivacy/home")!)
        }
        .sheet(isPresented: $showTerms) {
            SafariWebView(url: URL(string: "https://sites.google.com/view/wordremterms/home")!)
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

    /// Yıllık planın haftalığa göre tasarruf yüzdesi
    private func savingsPercent(_ plan: SubscriptionPlan) -> Int? {
        guard plan.isAnnual, let weekly = weeklyPlan?.product.price, weekly > 0 else { return nil }
        let ratio = NSDecimalNumber(decimal: plan.product.price / (weekly * 52)).doubleValue
        let pct = Int((1 - ratio) * 100)
        return pct >= 10 ? pct : nil
    }

    private func periodPrice(_ plan: SubscriptionPlan) -> String {
        plan.isAnnual ? AL.f(.paywallPerYear, plan.product.localizedPriceString)
                      : langManager.f(.paywallPerWeek, plan.product.localizedPriceString)
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
        Button {
            selectedId = plan.id
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(selected ? DS.Colors.accent : DS.Colors.line)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.isAnnual ? AL.s(.paywallAnnual) : AL.s(.paywallWeeklyPlan))
                            .font(DS.Font.ui(17, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                        if let days = plan.trialDays {
                            Text(AL.f(.paywallTrialBadge, days))
                                .font(DS.Font.ui(11, weight: .semibold))
                                .foregroundStyle(DS.Colors.accent)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(DS.Colors.accent.opacity(0.1), in: Capsule())
                        }
                    }
                    if plan.isAnnual, let perWeek = plan.product.localizedPricePerWeek {
                        Text(AL.f(.paywallWeeklyEquiv, perWeek))
                            .font(DS.Font.ui(13))
                            .foregroundStyle(DS.Colors.muted)
                    } else {
                        Text(langManager.s(.paywallWeeklyTerm))
                            .font(DS.Font.ui(13))
                            .foregroundStyle(DS.Colors.muted)
                    }
                }
                Spacer(minLength: 8)
                Text(periodPrice(plan))
                    .font(DS.Font.display(18, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .multilineTextAlignment(.trailing)
            }
            .padding(18)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(selected ? DS.Colors.ink : DS.Colors.line, lineWidth: selected ? 1.5 : 1))
            .overlay(alignment: .topTrailing) {
                if plan.isAnnual {
                    Text(savingsPercent(plan).map { AL.f(.paywallSave, $0) } ?? AL.s(.paywallBestValue))
                        .font(DS.Font.ui(11, weight: .bold))
                        .foregroundStyle(DS.Colors.paper)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(DS.Colors.accent, in: Capsule())
                        .offset(x: -14, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// Bugün → hatırlatma (bitişten 2 gün önce) → ücretlendirme
    private func trialTimeline(days: Int) -> some View {
        let steps: [(String, String, String)] = [
            ("lock.open", AL.s(.paywallTLToday), AL.s(.paywallTLTodaySub)),
            ("bell", AL.f(.paywallTLDay, days - 2), AL.s(.paywallTLReminderSub)),
            ("creditcard", AL.f(.paywallTLDay, days), AL.s(.paywallTLChargeSub)),
        ]
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Image(systemName: step.0)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(index == 0 ? DS.Colors.paper : DS.Colors.inkSoft)
                            .frame(width: 30, height: 30)
                            .background(index == 0 ? DS.Colors.accent : DS.Colors.paperSunken, in: Circle())
                        if index < steps.count - 1 {
                            Rectangle().fill(DS.Colors.line).frame(width: 1.5, height: 22)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.1)
                            .font(DS.Font.ui(15, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                        Text(step.2)
                            .font(DS.Font.ui(13))
                            .foregroundStyle(DS.Colors.muted)
                    }
                    .padding(.top, 5)
                    Spacer(minLength: 0)
                }
            }
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
            }
        }
    }

    private func purchaseSelected() {
        guard let plan = selectedPlan else { return }
        let tag = plan.isAnnual ? "annual" : "weekly"
        isLoading = true
        EventManager.shared.logPaywallEvent("purchase_tapped_\(tag)")
        InAppPurchaseManager.shared.purchase(product: plan.product) { outcome in
            DispatchQueue.main.async { self.isLoading = false }
            switch outcome {
            case .success:
                EventManager.shared.logPaywallEvent("purchase_success_\(tag)")
                if let days = plan.trialDays { scheduleTrialReminder(trialDays: days) }
                DispatchQueue.main.async { self.showWelcomePro = true }
            case .cancelled:
                EventManager.shared.logPaywallEvent("purchase_cancelled_\(tag)")
            case .failed:
                EventManager.shared.logPaywallEvent("purchase_failed_\(tag)")
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
        EventManager.shared.logPaywallEvent("restore_tapped")
        InAppPurchaseManager.shared.restorePurchases { result in
            DispatchQueue.main.async { self.isLoading = false }
            switch result {
            case .success:
                EventManager.shared.logPaywallEvent("restore_success")
                DispatchQueue.main.async {
                    self.showWelcomePro = true
                }
            case .failure:
                EventManager.shared.logPaywallEvent("restore_failed")
                DispatchQueue.main.async {
                    self.restoreMessage = langManager.s(.paywallRestoreNothing)
                }
            }
        }
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
}
