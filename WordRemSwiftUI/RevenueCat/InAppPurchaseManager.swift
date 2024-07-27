//
//  InAppPurchaseManager.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 27.07.2024.
//

import Foundation
import KeychainSwift
import RevenueCat
import StoreKit
import SuperwallKit

enum ProductIdentifier: String, CaseIterable {
    case monthly = "AIMonthlySubscription"
    case sixMonths = "monthly_6"
    case weekly = "AIWeeklySubscription"

    var identifier: String {
        return rawValue
    }
}

class InAppPurchaseManager: NSObject, ObservableObject {
    static let shared = InAppPurchaseManager()
    var offerings: [String: Offering] = [:]
    @Published var isUserSubscribed: Bool = false
    var availableProducts: [RevenueCat.StoreProduct] = []

    override private init() {
        super.init()
    }

    func setupInAppPurchaseManager() {
        let rcConfig = RevenueCat.Configuration.Builder(withAPIKey: "appl_GhabaauyHGferCzyhaYegGigrrb")
            .with(appUserID: KeychainSwift().get(KeychainKeys.deviceID))
            .build()

        Purchases.configure(with: rcConfig)

        let purchaseController = RCPurchaseController()
        Superwall.configure(apiKey: "pk_744e55fb5cf47cd0b3817d2d19f7b6347090c7263c77d5cc",
                            purchaseController: purchaseController)
        purchaseController.syncSubscriptionStatus()

        Purchases.logLevel = .debug
        Purchases.shared.delegate = self

        InAppPurchaseManager.shared.hasActiveSubscription { state in
            DispatchQueue.main.async {
                InAppPurchaseManager.shared.isUserSubscribed = state
//                Superwall.shared.subscriptionStatus = state ? .active : .inactive
            }
        }

        fetchAvailableProducts { _ in }
        Purchases.shared.invalidateCustomerInfoCache()

        getAvailableOfferings()
    }

    // Purchase a product.
    func purchase(product: RevenueCat.StoreProduct, completion: @escaping (Bool) -> Void) {
        Purchases.shared.purchase(product: product) { _, _, error, userCancelled in
            guard userCancelled == false, error == nil else {
                completion(false)
                return
            }
            self.handleSuccessfulPurchaseOrRestore()
            completion(true)
        }
    }

    func fetchAvailableProducts(completion: @escaping (Swift.Result<[RevenueCat.StoreProduct], Error>) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                completion(.failure(error))
                Log.debug("\(#fileID) \n \(#function) \n \(#line) \n \(error.localizedDescription)")
            } else if let offerings = offerings, let currentOffering = offerings.current {
                let products = currentOffering.availablePackages.map { $0.storeProduct }
                self.availableProducts = products
                completion(.success(products))
            } else {
                completion(.failure(NSError(domain: "Mevcut teklif yok", code: 0, userInfo: nil)))
                Log.debug("\(#fileID) \n \(#function) \n \(#line) \n Mevcut teklif yok")
            }
        }
    }

    func getAvailableProducts(completion: @escaping ([RevenueCat.StoreProduct]) -> Void) {
        Purchases.shared.getProducts(ProductIdentifier.allCases.map { $0.identifier }) { products in
            let sortedProducts = products.sorted(by: { $0.price < $1.price })
            self.availableProducts = sortedProducts
            completion(sortedProducts)
        }
    }

    func hasActiveSubscription(completion: @escaping (Bool) -> Void) {
        Purchases.shared.getCustomerInfo { customerInfo, _ in
            if let customerInfo = customerInfo {
                let hasActiveSubscription = customerInfo.entitlements.active.isEmpty == false
                completion(hasActiveSubscription)
            } else {
                completion(false)
            }
        }
    }

    func restorePurchases(completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        Purchases.shared.restorePurchases { customerInfo, error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.handleCustomerInfo(customerInfo)
                self.handleSuccessfulPurchaseOrRestore()
                completion(.success(()))
            }
        }
    }

    func getAvailableOfferings() {
        Purchases.shared.getOfferings { offerings, _ in
            self.offerings = offerings?.all ?? [:]
        }
    }

    private func handleCustomerInfo(_ customerInfo: CustomerInfo?) {
        guard let customerInfo = customerInfo else { return }
        if !customerInfo.entitlements.active.isEmpty {
            for item in ProductIdentifier.allCases where customerInfo.entitlements[item.identifier]?.isActive == true {
                UserDefaults.standard.setValue(true, forKey: item.identifier)
                self.handleSuccessfulPurchaseOrRestore()
            }
        } else {
            clearAllSubscribers()
        }
    }

    private func clearAllSubscribers() {
        for item in ProductIdentifier.allCases {
            UserDefaults.standard.removeObject(forKey: item.identifier)
        }
    }

    private func handleSuccessfulPurchaseOrRestore() {
        isUserSubscribed = true
        Superwall.shared.subscriptionStatus = .active
        NotificationCenter.default.post(name: .paymentStateChanged, object: nil)
    }
}

extension InAppPurchaseManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        handleCustomerInfo(customerInfo)
    }
}
