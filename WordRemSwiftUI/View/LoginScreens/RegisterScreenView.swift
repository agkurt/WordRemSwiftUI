//
//  RegisterScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI

struct RegisterScreenView: View {
    @StateObject var viewModel = RegisterScreenViewModel()
    @ObservedObject private var keyboard = KeyboardResponder()

    var body: some View {
        NavigationView {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack {
                        IconImageView()
                        VStack {
                            TextFieldView(text: $viewModel.email, placeholder: "Email")
                            TextFieldView(text: $viewModel.userName, placeholder: "Username")
                            SecureFieldView(text: $viewModel.password)
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .padding()
                        .frame(width: geometry.size.width * 1,height: geometry.size.height * 0.60)
                        .padding(.bottom, keyboard.currentHeight)
                        .animation(.easeOut(duration: 0.16))

                        VStack {
                            NavigationLink(destination: LoginScreenView(), isActive: $viewModel.isRegisterSuccess) {
                                Text("I have already have an account")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            Button(action: {
                                if viewModel.registerRequest() {
                                    viewModel.isRegisterSuccess = true
                                }
                            }) {
                                Text("Register")
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: "393E46"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    RegisterScreenView()
}

