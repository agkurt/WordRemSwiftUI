//
//  ReminderViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.04.2024.
//

import SwiftUI

@MainActor
final class ReminderViewModel: ObservableObject {
    
    @ObservedObject var notificationManager = NotificationManager()
    @Published var date = Date()
    @Published var numberOfReminders = 1
    @Published var repeatOption = "None"
    @Published var repeatValue = 1
    
    var repeatOptions: [String] {
        ["None", "Weekly", "Monthly"]
    }
    
    func sendNotifications(title: String, body: String) async {
        // Update the notification manager's date before sending
        notificationManager.date = self.date
        // Use the notification manager synchronously since it updates on main thread
        notificationManager.sendNotifications(title: title, body: body, repeatOption: repeatOption, repeatValue: repeatValue)
    }
    
    func deleteNotification() async {
        await notificationManager.removeNotification(notificationManager.notificationIDs.first ?? "")
    }
    
    func deleteAllNotifications() async {
        await notificationManager.removeAllNotifications()
    }
}



