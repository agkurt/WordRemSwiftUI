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
                    .autocapitalization(.none)
                    .background(Color.init(hex: "EEEEEE"))
                    .disableAutocorrection(true)
                    .font(Font.system(size: 18, weight: .regular))
                    .opacity(0.85)
                    .foregroundStyle(Color(hex: "393E46"))
                    .submitLabel(.next)
            }
            .padding()
        }
    }
}

struct TextFieldView_Previews: PreviewProvider {
    static var previews: some View {
        let text: Binding<String> = .constant("random")
        return TextFieldView(text: text)
    }
}


