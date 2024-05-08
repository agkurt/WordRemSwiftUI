//
//  LoginTextFields.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.05.2024.
//

import SwiftUI

struct LoginTextFields: View {
    @Binding var emailText:String
    @Binding var passwordText:String

    var body: some View {
        VStack(alignment:.leading,spacing: 15) {
            Text(" Welcome")
                .frame(maxWidth: .infinity,alignment:.leading)
                .font(.custom("Poppins-Medium", size: 25))
            Text(" Login")
                .frame(maxWidth: .infinity,alignment:.leading)
                .font(.custom("Poppins-Bold", size: 25))
        }
        .padding(.bottom,30)
        
        Text("Sign in with email")
            .font(.custom("Poppins-Light", size: 15))
            .frame(maxWidth: .infinity,alignment:.leading)
            .padding()
        VStack(spacing:20) {
            TextFieldView(text: $emailText, placeholder: "Email")
                .keyboardType(.emailAddress)
            SecureFieldView(text: $passwordText,placeholder: "Password")
        }
    }
}

#Preview {
    LoginTextFields(emailText: .constant(""), passwordText: .constant(""))
}
