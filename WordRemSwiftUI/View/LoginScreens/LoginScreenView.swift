//
//  LoginScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 12.02.2024.
//

import SwiftUI

struct LoginScreenView: View {
    
    @StateObject var viewModel = LoginScreenViewModel()
    @State var isLoggedIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack {
                        IconImageView()
                        
                        VStack(spacing: 0) {
                            TextFieldView(text: $viewModel.email, placeholder: "Email")
                            TextFieldView(text: $viewModel.password, placeholder: "Password")
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .padding()
                        .frame(height: geometry.size.height * 0.55) // Aynı yükseklikte olmasını sağlar
                        VStack {
                            NavigationLink(destination: GetWordsView().navigationBarBackButtonHidden(true), isActive: $isLoggedIn)  {
                                Text("Continue as guest")
                                    .font(.caption)
                                    .foregroundColor(.white)

                            }
                            
                            Button(action: {
                                viewModel.loginRequest()

                            }, label: {
                                Text("Login")
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: "393E46"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            })
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 10)
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    LoginScreenView()
}
