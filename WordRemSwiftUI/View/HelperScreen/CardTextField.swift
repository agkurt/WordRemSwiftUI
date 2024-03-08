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
    @Environment(\.colorScheme) private var colorScheme

    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .autocapitalization(.none)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(getColorBasedOnScheme())
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1) // Çerçeve rengini ayarlayın
                    )
            )
            .disableAutocorrection(true)
            .font(Font.system(size: 18, weight: .regular))
            .opacity(0.85)
            .submitLabel(.next)
            .clipShape(.rect(cornerRadius: 10))
    }
    
    private func getColorBasedOnScheme() -> LinearGradient {
        switch colorScheme {
        case .light:
            return LinearGradient(
                gradient: Gradient(colors: [Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .dark:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#222831"),
                    Color(hex: "#171A20")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [.gray, .black]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct CardTextField_Previews: PreviewProvider {
    static var previews: some View {
        let text: Binding<String> = .constant("random")
        return TextFieldView(text: text)
    }
}


