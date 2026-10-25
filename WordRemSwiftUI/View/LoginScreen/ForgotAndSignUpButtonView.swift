//
//  ForgotAndSignUpButtonView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.05.2024.
//

import SwiftUI

struct ForgotAndSignUpButtonView: View {
    @EnvironmentObject var langManager: LanguageManager
    var onForgotPassword: () -> Void = {}

    var body: some View {
        VStack {
            HStack {
                Button(action: onForgotPassword) {
                    Text(langManager.s(.loginForgotPassword))
                }
                Spacer()
                
                NavigationLink(langManager.s(.loginSignUp)) {
                    RegisterScreenView().navigationBarBackButtonHidden()
                }
            }
        }
    }
}

#Preview {
    ForgotAndSignUpButtonView()
        .environmentObject(LanguageManager.shared)
}
