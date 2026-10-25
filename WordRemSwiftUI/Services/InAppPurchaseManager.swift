//
//  InAppPurchaseManager.swift
//  WordRemSwiftUI
//

import Foundation
import RevenueCat

// MARK: - Product Identifier
/// App Store Connect'te aynı abonelik grubunda olmalı; yıllıkta 7 günlük ücretsiz deneme tanımlı.
enum ProductIdentifier: String, CaseIterable {
    case annual = "wordrem_annual_subscription"
    case weekly = "wordrem_weekly_subscription"

    static var all: [String] { allCases.map(\.rawValue) }
}

// MARK: - Plan (paywall'da gösterilen tek seçenek)
struct SubscriptionPlan: Identifiable {
    let product: StoreProduct
    /// Kullanıcı ücretsiz denemeye uygunsa deneme gün sayısı
    var trialDays: Int?

    var id: String { product.productIdentifier }
    var isAnnual: Bool { product.subscriptionPeriod?.unit == .year }

    static func freeTrialDays(of product: StoreProduct) -> Int? {
        guard let intro = product.introductoryDiscount, intro.paymentMode == .freeTrial else { return nil }
        let p = intro.subscriptionPeriod
        let days: Int
        switch p.unit {
        case .day:   days = p.value
        case .week:  days = p.value * 7
        case .month: days = p.value * 30
        case .year:  days = p.value * 365
        @unknown default: return nil
        }
        return days * max(intro.numberOfPeriods, 1)
    }
}

// MARK: - Purchase Result
enum PurchaseResult {
    case success
    case failure
}

enum PurchaseOutcome {
    case success
    case cancelled
    case failed
}

// MARK: - InAppPurchaseManager
final class InAppPurchaseManager: ObservableObject {

    static let shared = InAppPurchaseManager()

    private let premiumKey = "isPremium"

    @Published var failCount: Int = 0

    /// Cache'ten başlatılır. set edilince UserDefaults'a da yazar.
    @Published var isPremium: Bool {
        didSet {
            UserDefaults.standard.set(isPremium, forKey: premiumKey)
            DailyLimitManager.shared.isPremium = isPremium
        }
    }

    private init() {
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }

    private func isActive(_ info: CustomerInfo?) -> Bool {
        guard let info else { return false }
        // RevenueCat'teki yetki "premium"; eski sürümler "pro" kullanıyordu
        return info.entitlements["premium"]?.isActive == true
            || info.entitlements["pro"]?.isActive == true
            || !info.activeSubscriptions.isDisjoint(with: ProductIdentifier.all)
    }

    // MARK: - Configure
    static func configure(apiKey: String) {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: apiKey)
    }

    // MARK: - Sync Premium Status (uygulama açılışında çağır)
    func syncPremiumStatus() async {
        // customerInfo alınamazsa (ağ hatası vb.) — cache'teki değeri koru
        guard let info = try? await Purchases.shared.customerInfo() else {
            print("⚠️ [IAP] customerInfo alınamadı — cache korundu: \(isPremium)")
            return
        }
        let active = self.isActive(info)
        await MainActor.run {
            isPremium = active   // didSet → UserDefaults + DailyLimitManager
        }
        print("✅ [IAP] Premium sync: \(active)")
    }

    // MARK: - Fetch Plans
    /// Önce RevenueCat offering'i, boşsa ürünleri doğrudan StoreKit'ten çeker.
    /// Yıllık önce gelir; deneme uygunluğu kullanıcı bazında kontrol edilir.
    func fetchPlans() async -> [SubscriptionPlan] {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-MockPaywall") { return Self.mockPlans }
        #endif
        var products: [StoreProduct] = []
        if let offerings = try? await Purchases.shared.offerings(),
           let packages = offerings.current?.availablePackages, !packages.isEmpty {
            products = packages.map(\.storeProduct).filter { $0.subscriptionPeriod != nil }
        }
        if products.isEmpty {
            products = await Purchases.shared.products(ProductIdentifier.all)
        }
        guard !products.isEmpty else {
            print("❌ [IAP] No products from offering or StoreKit")
            return []
        }
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(
            productIdentifiers: products.map(\.productIdentifier))
        return products
            .map { p in
                let eligible = eligibility[p.productIdentifier]?.status != .ineligible
                return SubscriptionPlan(product: p, trialDays: eligible ? SubscriptionPlan.freeTrialDays(of: p) : nil)
            }
            .sorted { ($0.isAnnual ? 0 : 1) < ($1.isAnnual ? 0 : 1) }
    }

    // MARK: - Purchase
    func purchase(product: StoreProduct, completion: @escaping (PurchaseOutcome) -> Void) {
        Purchases.shared.purchase(product: product) { [weak self] _, customerInfo, error, userCancelled in
            if userCancelled { completion(.cancelled); return }
            if let error {
                print("❌ [IAP] Purchase error: \(error.localizedDescription)")
                DispatchQueue.main.async { self?.failCount += 1 }
                completion(.failed)
                return
            }
            let isActive = self?.isActive(customerInfo) == true
            DispatchQueue.main.async {
                self?.isPremium = isActive   // didSet → UserDefaults + DailyLimitManager
            }
            completion(isActive ? .success : .failed)
        }
    }

    func purchase(package: Package, completion: @escaping (Bool) -> Void) {
        Purchases.shared.purchase(package: package) { [weak self] _, customerInfo, error, userCancelled in
            if userCancelled { completion(false); return }
            if let error {
                print("❌ [IAP] Purchase error: \(error.localizedDescription)")
                DispatchQueue.main.async { self?.failCount += 1 }
                completion(false)
                return
            }
            let isActive = self?.isActive(customerInfo) == true
            DispatchQueue.main.async {
                self?.isPremium = isActive   // didSet → UserDefaults + DailyLimitManager
            }
            completion(isActive)
        }
    }

    // MARK: - Restore
    func restorePurchases(completion: @escaping (PurchaseResult) -> Void) {
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            if let error {
                print("❌ [IAP] Restore error: \(error.localizedDescription)")
                completion(.failure)
                return
            }
            let isActive = self?.isActive(customerInfo) == true
            DispatchQueue.main.async {
                self?.isPremium = isActive   // didSet → UserDefaults + DailyLimitManager
            }
            completion(isActive ? .success : .failure)
        }
    }

    // MARK: - Check Active Entitlement
    func isPro() async -> Bool {
        guard let info = try? await Purchases.shared.customerInfo() else { return false }
        return isActive(info)
    }

    #if DEBUG
    /// Simülatörde/ekran görüntüsü için sahte planlar: `-MockPaywall` argümanıyla açılır
    private static var mockPlans: [SubscriptionPlan] {
        let trial = TestStoreProductDiscount(identifier: "trial", price: 0, localizedPriceString: "$0.00",
                                             paymentMode: .freeTrial,
                                             subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .week),
                                             numberOfPeriods: 1, type: .introductory)
        let annual = TestStoreProduct(localizedTitle: "WordRem Pro Annual", price: 29.99, localizedPriceString: "$29.99",
                                      productIdentifier: ProductIdentifier.annual.rawValue, productType: .autoRenewableSubscription,
                                      localizedDescription: "", subscriptionGroupIdentifier: "pro",
                                      subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .year),
                                      introductoryDiscount: trial, locale: Locale(identifier: "en_US")).toStoreProduct()
        let weekly = TestStoreProduct(localizedTitle: "WordRem Pro Weekly", price: 2.99, localizedPriceString: "$2.99",
                                      productIdentifier: ProductIdentifier.weekly.rawValue, productType: .autoRenewableSubscription,
                                      localizedDescription: "", subscriptionGroupIdentifier: "pro",
                                      subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .week),
                                      locale: Locale(identifier: "en_US")).toStoreProduct()
        return [SubscriptionPlan(product: annual, trialDays: 7), SubscriptionPlan(product: weekly, trialDays: nil)]
    }
    #endif
}
