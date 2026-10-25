//
//  OnboardingPaywallView.swift
//  WordRemSwiftUI
//

import SwiftUI
import RevenueCat
import SafariServices

struct OnboardingPaywallView: View {

    @EnvironmentObject var langManager: LanguageManager
    var onContinue: () -> Void

    @Environment(\.presentationMode) var presentationMode

    @State private var weeklyProduct: StoreProduct?
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
    private var features: [(String, String, String)] {[
        ("infinity",              langManager.s(.paywallFeature1), langManager.s(.paywallFeature1Sub)),
        ("lightbulb",             langManager.s(.paywallFeature2), langManager.s(.paywallFeature2Sub)),
        ("list.bullet.rectangle", langManager.s(.paywallFeature3), langManager.s(.paywallFeature3Sub)),
        ("waveform",              langManager.s(.paywallFeature4), langManager.s(.paywallFeature4Sub)),
    ]}

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

                    // ── Plan Card ──────────────────────────────────────
                    Group {
                        if let product = weeklyProduct {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(langManager.s(.paywallWeeklyPro))
                                        .font(DS.Font.ui(17, weight: .semibold))
                                        .foregroundStyle(DS.Colors.ink)
                                    Text(langManager.s(.paywallWeeklyTerm))
                                        .font(DS.Font.ui(13))
                                        .foregroundStyle(DS.Colors.muted)
                                }
                                Spacer()
                                Text(langManager.f(.paywallPerWeek, product.localizedPriceString))
                                    .font(DS.Font.display(20, weight: .bold))
                                    .foregroundStyle(DS.Colors.ink)
                            }
                            .padding(20)
                            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.ink, lineWidth: 1.5))
                        } else if fetchFailed {
                            VStack(spacing: 8) {
                                Text(langManager.s(.paywallPriceFailed))
                                    .font(DS.Font.ui(15, weight: .medium))
                                    .foregroundStyle(DS.Colors.inkSoft)
                                Button { fetchAttempts = 0; fetchPackage() } label: {
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
                                .frame(height: 80)
                                .overlay(ProgressView().tint(DS.Colors.muted))
                        }
                    }
                    .padding(.bottom, 16)

                    // ── Purchase Button ────────────────────────────────
                    Button(langManager.s(.paywallContinue), action: purchaseWeekly)
                        .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
                        .disabled(weeklyProduct == nil || isLoading)
                        .opacity(weeklyProduct == nil ? 0.4 : 1)
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
            fetchPackage()
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

    // MARK: - Actions
    private func fetchPackage() {
        fetchFailed = false
        fetchAttempts += 1
        InAppPurchaseManager.shared.fetchWeeklyProduct { product in
            if let product {
                weeklyProduct = product
            } else if fetchAttempts < 3 {
                // Ağ / StoreKit geçici hatalarında sessizce tekrar dene
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { fetchPackage() }
            } else {
                fetchFailed = true
            }
        }
    }

    private func purchaseWeekly() {
        guard let product = weeklyProduct else { return }
        isLoading = true
        EventManager.shared.logPaywallEvent("purchase_tapped_weekly")
        InAppPurchaseManager.shared.purchase(product: product) { outcome in
            DispatchQueue.main.async { self.isLoading = false }
            switch outcome {
            case .success:
                EventManager.shared.logPaywallEvent("purchase_success_weekly")
                DispatchQueue.main.async { self.showWelcomePro = true }
            case .cancelled:
                EventManager.shared.logPaywallEvent("purchase_cancelled_weekly")
            case .failed:
                EventManager.shared.logPaywallEvent("purchase_failed_weekly")
                DispatchQueue.main.async { self.showPurchaseErrorAlert = true }
            }
        }
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
