//
//  EventManager.swift
//  WordRemSwiftUI
//
//  Ürün olayları. Üçüncü taraf analitik SDK'sı yok; olaylar yalnızca cihaz
//  log'una yazılır (gizlilik etiketi: veri toplanmıyor).
//

import Foundation
import os

final class EventManager {

    static let shared = EventManager()
    private let log = Logger(subsystem: "com.twinflare.WordRemSwiftUI", category: "events")
    private init() {}

    func logPaywallEvent(_ name: String) {
        log.info("paywall_\(name, privacy: .public)")
    }
}
