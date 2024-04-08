//
//  ReminderCalculator.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.04.2024.
//

import Foundation

struct ReminderCalculator {
    static func calculateMonthlyReminders(initialDate: Date, repeatValue: Int, numberOfReminders: Int) -> [Date] {
        var reminderDates = [Date]()
        var currentDate = initialDate
        
        // Calculate the initial reminder date
        reminderDates.append(currentDate)
        
        // Calculate subsequent reminder dates
        for _ in 1..<numberOfReminders {
            if let nextDate = Calendar.current.date(byAdding: .month, value: repeatValue, to: currentDate) {
                reminderDates.append(nextDate)
                currentDate = nextDate
            }
        }
        
        return reminderDates
    }
}

