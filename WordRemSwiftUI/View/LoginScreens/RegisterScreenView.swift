//
//  RegisterScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI

import SwiftUI

struct RegisterScreenView: View {
    
    @State var isRegisterSuccess = false
    @StateObject var registerScreenViewModel = RegisterScreenViewModel()
    
    var body: some View {
        
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.init(hex:"#00b4d8")]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    VStack(spacing:0) {
                        IconImageView()
                        VStack(spacing:-120) {
                            TextFieldView(text: $registerScreenViewModel.email, placeholder: "Email")
                            TextFieldView(text: $registerScreenViewModel.userName, placeholder: "Username")
                            TextFieldView(text: $registerScreenViewModel.password, placeholder: "Password")
                        }

                        Button ("Register") {
                            registerScreenViewModel.registerRequest()
                        }
                        .buttonStyle(LoginButtonStyle())
                        .onTapGesture {
                            if registerScreenViewModel.isRegisterSuccess {
                                isRegisterSuccess = true
                            }
                        }
                        NavigationLink(destination:LoginScreenView(), isActive: $isRegisterSuccess) {
                            Text("I have already account")
                                .font(.caption)
                        }
                        .padding()
                        
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .navigationTitle("RegisterScreen")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}


#Preview {
    RegisterScreenView()
}
