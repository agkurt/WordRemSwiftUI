//
//  View+Ext.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 1.03.2024.
//

import SwiftUI

extension View {
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }

        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        return root
    }
}

