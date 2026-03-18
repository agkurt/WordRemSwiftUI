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
    @State private var isFetchingPackage: Bool = false
    @State private var fetchFailed: Bool = false
    @State private var isLoading: Bool = false
    @State private var isCloseVisible: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var reviewTimer: Timer?
    @State private var showPrivacy: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPurchaseErrorAlert: Bool = false

    private let proColor     = Color(hex: "#8b5cf6")
    private let proColorDark = Color(hex: "#7c3aed")

    private let features: [(String, String)] = [
        ("bolt.fill",       "Reklamsız, kesintisiz öğrenme"),
        ("star.fill",       "Öncelikli yeni içeriklere erişim"),
        ("chart.bar.fill",  "Detaylı ilerleme & istatistikler"),
        ("bell.badge.fill", "Akıllı hatırlatıcılar"),
    ]

    private let reviews: [(String, String)] = [
        ("3 ayda geçtiğimi düşündüğüm kelimeleri 3 haftada öğrendim!", "Mehmet K."),
        ("Reklamsız deneyim inanılmaz fark yaratıyor.", "Ayşe T."),
        ("İstatistikler motivasyonumu artırıyor, tavsiye ederim.", "Can Ö."),
        ("Her gün birkaç dakika ile B2'ye ulaştım.", "Selin A."),
        ("Pro olmadan düşünemiyorum artık.", "Burak Y."),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                background
                if isLoading { loadingOverlay }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        featuresSection
                        reviewsSection
                        weeklyPlanCard
                        purchaseButton
                        legalSection
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { closeButton }
            }
        }
        .onAppear {
            fetchPackage()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { isCloseVisible = true }
            }
        }
        .onDisappear { reviewTimer?.invalidate() }
        .alert("Satın alma başarısız", isPresented: $showPurchaseErrorAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Bir hata oluştu. Lütfen tekrar dene veya restore kullan.")
        }
        .sheet(isPresented: $showPrivacy) {
            SafariWebView(url: URL(string: "https://wordrem.app/privacy")!)
        }
        .sheet(isPresented: $showTerms) {
            SafariWebView(url: URL(string: "https://wordrem.app/terms")!)
        }
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: [proColor.opacity(0.15), Color(hex: "#f8fafc")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.35)
            .ignoresSafeArea()
            .overlay(ProgressView().tint(.white).scaleEffect(1.5))
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Group {
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            MascotAnimationView(width: 100, height: 100)
                .padding(.top, 24)

            VStack(spacing: 8) {
                Text("WordRem Pro")
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundStyle(
                        LinearGradient(colors: [proColor, proColorDark],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                Text("Öğrenmeyi bir üst seviyeye taşı")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundStyle(Color(hex: "#64748b"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(features, id: \.0) { icon, text in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(proColor)
                        .frame(width: 32, height: 32)
                        .background(proColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text(text)
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundStyle(Color(hex: "#1e293b"))
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
    }

    // MARK: - Reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kullanıcılar ne diyor?")
                .font(.custom("Poppins-Bold", size: 15))
                .foregroundStyle(Color(hex: "#1e293b"))
                .padding(.horizontal, 28)

            GeometryReader { _ in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0 ..< reviews.count * 20, id: \.self) { i in
                            reviewCard(reviews[i % reviews.count])
                        }
                    }
                    .padding(.horizontal, 28)
                    .offset(x: scrollOffset)
                    .onAppear { startScrollTimer() }
                }
            }
            .frame(height: 110)
        }
        .padding(.bottom, 28)
    }

    private func reviewCard(_ review: (String, String)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                }
            }
            Text(review.0)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundStyle(Color(hex: "#1e293b"))
                .lineLimit(3)
            Text("— \(review.1)")
                .font(.custom("Poppins-Bold", size: 11))
                .foregroundStyle(Color(hex: "#64748b"))
        }
        .frame(width: 200)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }

    // MARK: - Weekly Plan Card

    private var weeklyPlanCard: some View {
        Group {
            if let pkg = weeklyPackage {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Haftalık Pro")
                            .font(.custom("Poppins-Bold", size: 17))
                            .foregroundStyle(.white)
                        Text("\(pkg.storeProduct.localizedPriceString) / hafta")
                            .font(.custom("Poppins-Regular", size: 14))
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
                    Text("TAVSİYE EDİLEN")
                        .font(.custom("Poppins-Bold", size: 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.primaryOrange)
                        .clipShape(Capsule())
                        .offset(x: -14, y: -10)
                }
            } else if fetchFailed {
                // Ağ hatası — tekrar dene
                VStack(spacing: 10) {
                    Text("Fiyat yüklenemedi")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundStyle(Color(hex: "#64748b"))
                    Button {
                        fetchPackage()
                    } label: {
                        Text("Tekrar Dene")
                            .font(.custom("Poppins-Bold", size: 13))
                            .foregroundStyle(proColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(proColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // Yükleniyor
                RoundedRectangle(cornerRadius: 16)
                    .fill(proColor.opacity(0.1))
                    .frame(height: 72)
                    .overlay(ProgressView().tint(proColor))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button(action: purchaseWeekly) {
            Text("Devam Et")
                .font(.custom("Poppins-Bold", size: 17))
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
        .padding(.bottom, 16)
        .disabled(weeklyPackage == nil || isLoading)
        .opacity(weeklyPackage == nil ? 0.5 : 1)
    }

    // MARK: - Legal

    private var legalSection: some View {
        HStack(spacing: 20) {
            legalButton("Gizlilik") { showPrivacy = true }
            legalButton("Kullanım Şartları") { showTerms = true }
            legalButton("Geri Yükle") { restorePurchases() }
        }
        .padding(.bottom, 32)
    }

    private func legalButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundStyle(Color(hex: "#94a3b8"))
        }
    }

    // MARK: - Actions

    private func fetchPackage() {
        isFetchingPackage = true
        fetchFailed = false
        InAppPurchaseManager.shared.fetchWeeklyPackage { pkg in
            isFetchingPackage = false
            if let pkg {
                weeklyPackage = pkg
            } else {
                fetchFailed = true
            }
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

    private func startScrollTimer() {
        reviewTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            DispatchQueue.main.async {
                self.scrollOffset -= 0.5
                if abs(self.scrollOffset) >= 220 * CGFloat(self.reviews.count) {
                    self.scrollOffset = 0
                }
            }
        }
    }
}

// MARK: - SafariWebView

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    OnboardingPaywallView(onContinue: {})
}
