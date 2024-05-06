//
//  ReminderViewModel.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.04.2024.
//

import SwiftUI

@MainActor
class ReminderViewModel: ObservableObject {
    
    @ObservedObject private var notificationManager = NotificationManager()
    @Published var date = Date()
    @Published var numberOfReminders = 1
    @Published var repeatOption = "None"
    @Published var repeatValue = 1
    
    // Computed property to access repeat options
    var repeatOptions: [String] {
        ["None", "Weekly", "Monthly"]
    }

    func sendNotifications(title: String, body: String) {
        Task {
            notificationManager.sendNotifications(title: title, body: body, repeatOption: repeatOption, repeatValue: repeatValue)
        }
    }
}


