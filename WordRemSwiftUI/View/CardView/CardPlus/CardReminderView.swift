//
//  CardReminderView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.04.2024.
//

import SwiftUI

struct CardReminderView: View {
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2023, month: 1, day: 1)
        let endComponents = DateComponents(year: 2024, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        return calendar.date(from:startComponents)!
            ...
            calendar.date(from:endComponents)!
    }()
    
    @State private var date = Date() // Seçilen tarih
    @State private var showDatePicker = false
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    CardReminderView()
}
