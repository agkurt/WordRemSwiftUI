//
//  RegisterScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

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
                    VStack {
                        IconImageView()
                        TextFieldView(registerScreenViewModel: registerScreenViewModel)
                        NavigationLink(destination: GetWordsView(), isActive: $isRegisterSuccess) {
                            EmptyView()
                        }
                        
                        Button ("Register") {
                            registerScreenViewModel.registerRequest()
                        }
                        .buttonStyle(LoginButtonStyle())
                        
                    }
                    .padding()
                    
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
