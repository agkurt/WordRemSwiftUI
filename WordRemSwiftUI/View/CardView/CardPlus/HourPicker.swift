//
//  HourPicker.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.04.2024.
//

import SwiftUI

struct HourPicker: View {
    @Binding var selectedHour: Int
    @State private var hours = Array(0..<24)
    
    var body: some View {
        Picker("Hour", selection: $selectedHour) {
            ForEach(hours, id: \.self) { hour in
                Text("\(hour):00")
                    .tag(hour)
            }
        }
        .pickerStyle(WheelPickerStyle())
    }
}
