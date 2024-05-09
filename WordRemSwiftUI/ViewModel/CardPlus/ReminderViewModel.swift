//
//  ReminderViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.04.2024.
//

import SwiftUI

@MainActor
class ReminderViewModel: ObservableObject {
    
    @ObservedObject var notificationManager = NotificationManager()
    @Published var date = Date()
    @Published var numberOfReminders = 1
    @Published var repeatOption = "None"
    @Published var repeatValue = 1
    
    var repeatOptions: [String] {
        ["None", "Weekly", "Monthly"]
    }
    
    func sendNotifications(title: String, body: String) async {
        Task {
            notificationManager.sendNotifications(title: title, body: body, repeatOption: repeatOption, repeatValue: repeatValue)
        }
       
    }
    
    func deleteNotification() {
        Task {
            await notificationManager.removeNotification(notificationManager.notificationIDs.first ?? "")
        }
    }
}



