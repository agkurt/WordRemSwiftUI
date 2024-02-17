//
//  SecureFieldView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 14.02.2024.
//

import SwiftUI

struct SecureFieldView: View {
    @Binding var text: String
    
    var body: some View {
        VStack {
            SecureField("Password", text:$text)
                .padding()
                .autocapitalization(.none)
                .background(Color.init(hex: "EEEEEE"),in:.capsule)
                .disableAutocorrection(true)
                .font(Font.system(size: 18, weight: .regular))
                .opacity(0.85)
                .foregroundStyle(Color(hex: "393E46"))
            .keyboardType(.default)
        }
        .padding()
    }
}

#Preview {
    let text: Binding<String> = .constant("random")
    return SecureFieldView(text:text )
}
