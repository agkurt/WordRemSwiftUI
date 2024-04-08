//
//  UserSettings.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 16.03.2024.
//

import SwiftUI

struct UserSettings: View {
    
    @StateObject private var manager = NotificationManager()
    
    var body: some View {
        VStack {
            Button {
                Task {
                    await manager.request()
                }
            } label: {
                Text("request notification permission")
            }
            .disabled(manager.hasPermission)
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    UserSettings()
}
