//
//  InAppPurchaseManager.swift
//  WordRemSwiftUI
//

import Foundation
import RevenueCat

// MARK: - Product Identifier
enum ProductIdentifier: String {
    case weekly = "wordrem_weekly_subscription"
}

// MARK: - Purchase Result
enum PurchaseResult {
    case success
    case failure
}

// MARK: - InAppPurchaseManager
final class InAppPurchaseManager: ObservableObject {

    static let shared = InAppPurchaseManager()

    private let premiumKey = "isPremium"

    @Published var weeklyPackage: Package?
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

    // MARK: - Configure
    static func configure(apiKey: String) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
    }

    // MARK: - Sync Premium Status (uygulama açılışında çağır)
    func syncPremiumStatus() async {
        // customerInfo alınamazsa (ağ hatası vb.) — cache'teki değeri koru
        guard let info = try? await Purchases.shared.customerInfo() else {
            print("⚠️ [IAP] customerInfo alınamadı — cache korundu: \(isPremium)")
            return
        }
        let active = info.entitlements["pro"]?.isActive == true
            || info.activeSubscriptions.contains(ProductIdentifier.weekly.rawValue)
        await MainActor.run {
            isPremium = active   // didSet → UserDefaults + DailyLimitManager
        }
        print("✅ [IAP] Premium sync: \(active)")
    }

    // MARK: - Fetch Weekly Package
    func fetchWeeklyPackage(completion: @escaping (Package?) -> Void) {
        Purchases.shared.getOfferings { [weak self] offerings, error in
            if let error {
                print("❌ [IAP] Offerings fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            let pkg = offerings?.current?.weekly
                ?? offerings?.current?.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier == ProductIdentifier.weekly.rawValue
                })
            DispatchQueue.main.async {
                self?.weeklyPackage = pkg
                completion(pkg)
            }
        }
    }

    // MARK: - Purchase
    func purchase(package: Package, completion: @escaping (Bool) -> Void) {
        Purchases.shared.purchase(package: package) { [weak self] _, customerInfo, error, userCancelled in
            if userCancelled { completion(false); return }
            if let error {
                print("❌ [IAP] Purchase error: \(error.localizedDescription)")
                DispatchQueue.main.async { self?.failCount += 1 }
                completion(false)
                return
            }
            let isActive = customerInfo?.entitlements["pro"]?.isActive == true
                || customerInfo?.activeSubscriptions.contains(ProductIdentifier.weekly.rawValue) == true
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
            let isActive = customerInfo?.entitlements["pro"]?.isActive == true
                || customerInfo?.activeSubscriptions.contains(ProductIdentifier.weekly.rawValue) == true
            DispatchQueue.main.async {
                self?.isPremium = isActive   // didSet → UserDefaults + DailyLimitManager
            }
            completion(isActive ? .success : .failure)
        }
    }

    // MARK: - Check Active Entitlement
    func isPro() async -> Bool {
        guard let info = try? await Purchases.shared.customerInfo() else { return false }
        return info.entitlements["pro"]?.isActive == true
            || info.activeSubscriptions.contains(ProductIdentifier.weekly.rawValue)
    }
}
