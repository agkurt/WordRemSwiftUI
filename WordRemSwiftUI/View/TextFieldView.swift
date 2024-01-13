//
//  TextFieldView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 11.01.2024.
//

import SwiftUI

struct TextFieldView: View {
    
    @State var email:String = ""
    @State var userName:String = ""
    @State var password:String = ""
    
    var body: some View {
            VStack(spacing: 16) { // Alt alta sıralı, aralarında 16 birim boşluklu VStack
                TextField("Email", text: $email)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#00a2d8")))
                    .frame(width: 350, height: 50)
                    .font(Font.system(size: 18, weight: .regular))
                
                TextField("Username", text: $userName)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#00a2d8")))
                    .frame(width: 350, height: 50)
                    .font(Font.system(size: 18, weight: .regular))
                
                TextField("Password", text: $password)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#00a2d8")))
                    .frame(width: 350, height: 50)
                    .font(Font.system(size: 18, weight: .regular))
            }
            .padding()
        }
    }

#Preview {
    TextFieldView()
}
