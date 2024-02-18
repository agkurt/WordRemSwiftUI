//
//  HideKeyboard.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 14.02.2024.
//

import SwiftUI

extension UIApplication {
    func hideKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

