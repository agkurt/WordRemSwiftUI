//
//  OnboardingPaywallView.swift
//  WordRemSwiftUI
//

import SwiftUI
import RevenueCat
import SafariServices

struct OnboardingPaywallView: View {

    var onContinue: () -> Void

    @Environment(\.presentationMode) var presentationMode

    @State private var weeklyPackage: Package?
    @State private var fetchFailed: Bool = false
    @State private var isLoading: Bool = false
    @State private var isCloseVisible: Bool = true
    @State private var showPrivacy: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPurchaseErrorAlert: Bool = false

    private let proColor     = Color(hex: "#8b5cf6")
    private let proColorDark = Color(hex: "#7c3aed")

    // (asset, title, subtitle)
    private var features: [(String, String, String)] {[
        ("paywall1", AL.s(.paywallFeature1), AL.s(.paywallFeature1Sub)),
        ("paywall2", AL.s(.paywallFeature2), AL.s(.paywallFeature2Sub)),
        ("paywall3", AL.s(.paywallFeature3), AL.s(.paywallFeature3Sub)),
        ("paywall4", AL.s(.paywallFeature4), AL.s(.paywallFeature4Sub)),
    ]}

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [proColor.opacity(0.15), Color(hex: "#f8fafc")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLoading {
                    Color.black.opacity(0.35).ignoresSafeArea()
                        .overlay(ProgressView().tint(.white).scaleEffect(1.5))
                }

                VStack(spacing: 0) {

                    // ── Hero ───────────────────────────────────────────
                    VStack(spacing: 8) {
                        MascotAnimationView(width: 110, height: 110)
                            .padding(.top, 8)

                        Text("WordRem Pro")
                            .font(.custom("Feather-Bold", size: 26))
                            .foregroundStyle(
                                LinearGradient(colors: [proColor, proColorDark],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                        Text(AL.s(.paywallSubtitle))
                            .font(.custom("Feather-Bold", size: 14))
                            .foregroundStyle(Color(hex: "#64748b"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 24)

                    // ── Features ───────────────────────────────────────
                    VStack(spacing: 16) {
                        ForEach(features, id: \.0) { asset, title, subtitle in
                            HStack(spacing: 16) {
                                // Icon: white circle bg
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 52, height: 52)
                                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                                    Image(asset)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title)
                                        .font(.custom("Feather-Bold", size: 15))
                                        .foregroundStyle(Color(hex: "#1e293b"))
                                    Text(subtitle)
                                        .font(.custom("Feather-Bold", size: 12))
                                        .foregroundStyle(Color(hex: "#64748b"))
                                }

                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)

                    // ── Plan Card ──────────────────────────────────────
                    Group {
                        if let pkg = weeklyPackage {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(AL.s(.paywallWeeklyPro))
                                        .font(.custom("Feather-Bold", size: 17))
                                        .foregroundStyle(.white)
                                    Text(AL.f(.paywallPerWeek, pkg.storeProduct.localizedPriceString))
                                        .font(.custom("Feather-Bold", size: 14))
                                        .foregroundStyle(.white.opacity(0.88))
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(colors: [proColor, proColorDark],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: proColor.opacity(0.35), radius: 10, y: 5)
                            .overlay(alignment: .topTrailing) {
                                Text(AL.s(.paywallRecommended))
                                    .font(.custom("Feather-Bold", size: 10))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.Colors.primaryOrange)
                                    .clipShape(Capsule())
                                    .offset(x: -14, y: -10)
                            }
                        } else if fetchFailed {
                            VStack(spacing: 8) {
                                Text(AL.s(.paywallPriceFailed))
                                    .font(.custom("Feather-Bold", size: 14))
                                    .foregroundStyle(Color(hex: "#64748b"))
                                Button { fetchPackage() } label: {
                                    Text(AL.s(.paywallRetry))
                                        .font(.custom("Feather-Bold", size: 13))
                                        .foregroundStyle(proColor)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(proColor.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(proColor.opacity(0.1))
                                .frame(height: 72)
                                .overlay(ProgressView().tint(proColor))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    // ── Purchase Button ────────────────────────────────
                    Button(action: purchaseWeekly) {
                        Text(AL.s(.paywallContinue))
                            .font(.custom("Feather-Bold", size: 17))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(colors: [proColor, proColorDark],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: proColor.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .disabled(weeklyPackage == nil || isLoading)
                    .opacity(weeklyPackage == nil ? 0.5 : 1)

                    // ── Legal ──────────────────────────────────────────
                    HStack(spacing: 20) {
                        legalButton(AL.s(.paywallPrivacy)) { showPrivacy = true }
                        legalButton(AL.s(.paywallTerms))   { showTerms = true }
                        legalButton(AL.s(.paywallRestore)) { restorePurchases() }
                    }
                    .padding(.bottom, 8)
                }
                .padding(.top, 4)
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
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#64748b"))
                                .padding(8)
                                .background(Color(hex: "#e2e8f0"))
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchPackage()
        }
        .alert(AL.s(.paywallPurchaseFailed), isPresented: $showPurchaseErrorAlert) {
            Button(AL.s(.paywallOk), role: .cancel) {}
        } message: {
            Text(AL.s(.paywallPurchaseError))
        }
        .sheet(isPresented: $showPrivacy) {
            SafariWebView(url: URL(string: "https://sites.google.com/view/wordremprivacy/home")!)
        }
        .sheet(isPresented: $showTerms) {
            SafariWebView(url: URL(string: "https://sites.google.com/view/wordremterms/home")!)
        }
    }

    // MARK: - Legal Button
    private func legalButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Feather-Bold", size: 11))
                .foregroundStyle(Color(hex: "#94a3b8"))
        }
    }

    // MARK: - Actions
    private func fetchPackage() {
        fetchFailed = false
        InAppPurchaseManager.shared.fetchWeeklyPackage { pkg in
            if let pkg { weeklyPackage = pkg } else { fetchFailed = true }
        }
    }

    private func purchaseWeekly() {
        guard let pkg = weeklyPackage else { return }
        isLoading = true
        EventManager.shared.logPaywallEvent("purchase_tapped_weekly")
        InAppPurchaseManager.shared.purchase(package: pkg) { isSuccessful in
            DispatchQueue.main.async { self.isLoading = false }
            if isSuccessful {
                EventManager.shared.logPaywallEvent("purchase_success_weekly")
                DispatchQueue.main.async {
                    self.presentationMode.wrappedValue.dismiss()
                    self.onContinue()
                }
            } else {
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
                    self.presentationMode.wrappedValue.dismiss()
                    self.onContinue()
                }
            case .failure:
                EventManager.shared.logPaywallEvent("restore_failed")
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
