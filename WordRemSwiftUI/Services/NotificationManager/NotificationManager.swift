//
//  NotificationManager.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 17.03.2024.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    
    @Published private(set) var hasPermission = false
    @Published var numberOfReminders = 1
    @Published var date = Date()
    
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
        
        // Initialize trigger components with the provided date and time
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        // Create the trigger date from the modified components
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeatOption != "None")
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding initial notification request: \(error.localizedDescription)")
            } else {
                print("Initial notification request added successfully")
                
                // If repeat is requested, schedule additional notifications
                if repeatOption != "None" {
                    for i in 1..<repeatValue {
                        // Calculate the next reminder date within 2 hours from the initial date
                        let nextDate = calendar.date(byAdding: .hour, value: 2 * i, to: self.date)!
                        let nextComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
                        
                        // Create the trigger for the next reminder
                        let nextTrigger = UNCalendarNotificationTrigger(dateMatching: nextComponents, repeats: true)
                        let nextRequest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nextTrigger)
                        UNUserNotificationCenter.current().add(nextRequest) { error in
                            if let error = error {
                                print("Error adding notification request \(i): \(error.localizedDescription)")
                            } else {
                                print("Notification request \(i) added successfully")
                            }
                        }
                    }
                }
            }
        }
    }


}

