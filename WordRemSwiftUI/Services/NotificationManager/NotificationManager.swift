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
    
    func calculateRepeatInterval(type: String, repeatCount: Int) -> Int {
        var totalHours: Int
        switch type {
        case "Daily":
            totalHours = 24
        case "Weekly":
            totalHours = 24 * 7
        case "Monthly":
            totalHours = 24 * 30
        default:
            totalHours = 24
        }
        
        return totalHours / repeatCount
    }

    func sendNotifications(title: String, body: String, repeatOption: String, repeatValue: Int) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let calendar = Calendar.current
        let repeatInterval = calculateRepeatInterval(type: repeatOption, repeatCount: repeatValue)
        
        for i in 0..<repeatValue {
            let id = UUID().uuidString
            let nextDate = calendar.date(byAdding: .hour, value: repeatInterval * i, to: self.date)!
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
           
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error adding notification request \(i): \(error.localizedDescription)")
                } else {
                    print("Notification request \(i) added successfully")
                }
            }
            
        }
    }
    
    func removeNotification(_ id: String) async {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
//        if let index = notificationIDs.firstIndex(of: id) {
//            notificationIDs.remove(at: index)
//        }
    }
}

