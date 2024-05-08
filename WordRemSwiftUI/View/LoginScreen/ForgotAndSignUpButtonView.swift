//
//  ForgotAndSignUpButtonView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.05.2024.
//

import SwiftUI

struct ForgotAndSignUpButtonView: View {
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    
                }) {
                    Text("Forgot Your Password?")
                }
                Spacer()
                
                NavigationLink("Sign up") {
                    RegisterScreenView().navigationBarBackButtonHidden()
                }
            }
        }
    }
}

#Preview {
    ForgotAndSignUpButtonView()
}
