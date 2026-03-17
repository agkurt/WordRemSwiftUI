//
//  NotificationManager.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 17.03.2024.
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    
    @Published private(set) var hasPermission = false
    @Published var numberOfReminders = 1
    @Published var date = Date()
    @Published var notificationIDs : [String] = []
    
    init() {
        Task {
            await getAuthStatus()
        }
    }
    
    func request() async {
        do {
            self.hasPermission = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print(error)
        }
    }
    
   
    func getAuthStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            self.hasPermission = true
        default:
            self.hasPermission = false
        }
    }
    
    func sendNotifications(title: String, body: String, repeatOption: String, repeatValue: Int) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let calendar = Calendar.current
        
        // Clear previous notification IDs for this word
        notificationIDs.removeAll()
        
        switch repeatOption {
        case "None":
            // Single notification
            let id = UUID().uuidString
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { [weak self] error in
                if let error = error {
                    print("Error adding notification: \(error.localizedDescription)")
                } else {
                    print("Notification added successfully")
                    Task { @MainActor in
                        self?.notificationIDs.append(id)
                    }
                }
            }
            
        case "Weekly":
            // Repeat every N weeks
            for i in 0..<5 { // Create up to 5 future notifications
                let id = UUID().uuidString
                let nextDate = calendar.date(byAdding: .weekOfYear, value: repeatValue * i, to: self.date)!
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { [weak self] error in
                    if let error = error {
                        print("Error adding notification \(i): \(error.localizedDescription)")
                    } else {
                        print("Notification \(i) added successfully for date: \(nextDate)")
                        Task { @MainActor in
                            self?.notificationIDs.append(id)
                        }
                    }
                }
            }
            
        case "Monthly":
            // Repeat every N months
            for i in 0..<5 { // Create up to 5 future notifications
                let id = UUID().uuidString
                let nextDate = calendar.date(byAdding: .month, value: repeatValue * i, to: self.date)!
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { [weak self] error in
                    if let error = error {
                        print("Error adding notification \(i): \(error.localizedDescription)")
                    } else {
                        print("Notification \(i) added successfully for date: \(nextDate)")
                        Task { @MainActor in
                            self?.notificationIDs.append(id)
                        }
                    }
                }
            }
            
        default:
            break
        }
    }
    
    func removeNotification(_ id: String) async {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        if let index = notificationIDs.firstIndex(of: id) {
            notificationIDs.remove(at: index)
        }
    }
    
    func removeAllNotifications() async {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        notificationIDs.removeAll()
    }
}

