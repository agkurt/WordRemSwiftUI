//
//  CheckBoxStyle.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 27.02.2024.
//

import SwiftUI

struct CheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}
