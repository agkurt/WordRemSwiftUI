//
//  TextFieldView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 11.01.2024.
//

import SwiftUI

struct TextFieldView: View {
    @ObservedObject var registerScreenViewModel = RegisterScreenViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                TextField("Email", text: $registerScreenViewModel.email)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#00a2d8")))
                    .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.10)
                    .font(Font.system(size: 18, weight: .regular))
                
                TextField("Username", text: $registerScreenViewModel.userName)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#00a2d8")))
                    .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.10)
                    .font(Font.system(size: 18, weight: .regular))
                
                SecureField("Password", text: $registerScreenViewModel.password)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#00a2d8")))
                    .frame(width: geometry.size.width * 0.90, height: geometry.size.height * 0.10)
                    .font(Font.system(size: 18, weight: .regular))
            }
            .padding()
        }
    }
}

#Preview {
    TextFieldView()
}
