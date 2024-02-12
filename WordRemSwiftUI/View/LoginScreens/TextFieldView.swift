//
//  TextFieldView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 11.01.2024.
//

import SwiftUI

struct TextFieldView: View {
    @ObservedObject var registerScreenViewModel = RegisterScreenViewModel()
    @Binding var text : String
    var placeholder:String = ""

    var body: some View {
        GeometryReader { geometry in
            VStack{
                TextField(placeholder, text: $text)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#00a2d8")))
                    .font(Font.system(size: 18, weight: .regular))
                
            }
           
            .padding()
        }
    }
}
