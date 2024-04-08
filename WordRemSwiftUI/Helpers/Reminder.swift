//
//  Reminder.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.04.2024.
//

import Foundation

struct Reminder {
    
   static let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2024, month: 4, day: 5)
        let endComponents = DateComponents(year: 2030, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        return calendar.date(from:startComponents)!
            ...
            calendar.date(from:endComponents)!
    }()

}
