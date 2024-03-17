//
//  NotificationManager.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 17.03.2024.
//

import Foundation
import UserNotifications

// main dispatch
@MainActor
class NotificationManager:ObservableObject {
    
    @Published private(set) var hasPermission = false
    
    init() {
        Task {
            await getAuthStatus()
        }
    }
    
    
    func request() async {
        do {
            self.hasPermission = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound])
        }catch {
            print(error)
        }
    }
    
    func getAuthStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized,
                .provisional,
                .ephemeral:
            self.hasPermission = true
        default:
            self.hasPermission = false
        }
    }
}
