//
//  CardTextField.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardTextField: View {
    @Binding public var text:String
    var placeholder:String = ""
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .autocapitalization(.none)
            .background(Color.init(hex: "EEEEEE"))
            .disableAutocorrection(true)
            .font(Font.system(size: 18, weight: .regular))
            .opacity(0.85)
            .submitLabel(.next)
            .clipShape(.rect(cornerRadius: 10))
    }
}

struct CardTextField_Previews: PreviewProvider {
    static var previews: some View {
        let text: Binding<String> = .constant("random")
        return TextFieldView(text: text)
    }
}


