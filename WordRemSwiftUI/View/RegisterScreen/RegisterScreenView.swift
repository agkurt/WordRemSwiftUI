//
//  RegisterScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI

struct RegisterScreenView: View {
    
    @StateObject var viewModel = RegisterScreenViewModel()
    @StateObject var homeScreenViewModel = HomeScreenViewModel()
    @FocusState var focusedField: FocusableField?
    @Environment(\.colorScheme) private var colorScheme
    @State var isRegisterSuccess: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                GeometryReader { geometry in
                    VStack() {
                        Spacer()
                        VStack {
                            VStack(alignment:.leading,spacing: 15) {
                                Text(" Welcome")
                                    .frame(maxWidth: .infinity,alignment:.leading)
                                    .font(.custom("Poppins-Medium", size: 25))
                                Text(" Sign Up")
                                    .frame(maxWidth: .infinity,alignment:.leading)
                                    .font(.custom("Poppins-Bold", size: 25))
                            }
                            .padding(.bottom,30)
                            
                            Text("Sign up with email")
                                .font(.custom("Poppins-Light", size: 15))
                                .frame(maxWidth: .infinity,alignment:.leading)
                                .padding(.leading)
                            
                            VStack(spacing:20) {
                                
                                TextFieldView(text: $viewModel.email, placeholder: "Email")
                                    .focused($focusedField, equals: .email)
                                    .keyboardType(.emailAddress)
                                
                                TextFieldView(text: $viewModel.userName, placeholder: "Username")
                                    .focused($focusedField, equals: .username)
                                
                                SecureFieldView(text: $viewModel.password,placeholder: "Password")
                                    .focused($focusedField, equals: .password)
                                    .padding(.bottom,10)
                                
                            }
                            
                            VStack {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("I have an already account")
                                }
                                
                                Button(action: {
                                    Task {
                                        await viewModel.registerRequest()
                                    }
                                }) {
                                    Text("Sign Up")
                                        .font(.custom("Poppins-Light", size: 15))
                                        .frame(maxWidth: .infinity,alignment:.center)
                                        .padding()
                                        .background(Color(hex: "#313a45"))
                                        .foregroundColor(.white)
                                        .cornerRadius(30)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding()
                            }
                            
                        }
                        
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                        .cornerRadius(20)
                        .padding()
                        .animation(.easeOut(duration: 0.35),value: 0)
                        Spacer()
                    }
                }
            }
            .onSubmit {
                viewModel.focusNextField()
            }
            .onTapGesture() {
                UIApplication.shared.hideKeyboard()
            }
            .onReceive(viewModel.$isRegisterSuccess) { success in
                if success {
                    _ = HomeScreenView(viewModel: homeScreenViewModel)
                }
            }
        }
        
    }
    
}



