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

    @Published var weeklyPackage: Package?
    @Published var failCount: Int = 0

    private init() {}

    // MARK: - Configure (WordRemSwiftUIApp init'te çağır)
    static func configure(apiKey: String) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
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
            completion(isActive)
        }
    }

    // MARK: - Restore
    func restorePurchases(completion: @escaping (PurchaseResult) -> Void) {
        Purchases.shared.restorePurchases { customerInfo, error in
            if let error {
                print("❌ [IAP] Restore error: \(error.localizedDescription)")
                completion(.failure)
                return
            }
            let isActive = customerInfo?.entitlements["pro"]?.isActive == true
            completion(isActive ? .success : .failure)
        }
    }

    // MARK: - Check Active Entitlement
    func isPro() async -> Bool {
        guard let info = try? await Purchases.shared.customerInfo() else { return false }
        return info.entitlements["pro"]?.isActive == true
    }
}
