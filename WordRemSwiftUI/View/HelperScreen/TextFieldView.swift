//
//  TextFieldView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 11.01.2024.
//
import SwiftUI

struct TextFieldView: View {
    @ObservedObject var registerScreenViewModel = RegisterScreenViewModel()
    @Binding var text: String
    var placeholder: String = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .autocapitalization(.none)
            .background(getColorBasedOnScheme())
            .disableAutocorrection(true)
            .font(Font.system(size: 18, weight: .regular))
            .opacity(0.85)
            .submitLabel(.next)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.primary)
            .cornerRadius(30)
    }
    
    private func getColorBasedOnScheme() -> Color  {
        switch colorScheme {
        case .light:
            return Color.init(hex: "#a2a7ac")

        case .dark:
            return Color.init(hex: "#1c2127")
            
        default:
            return Color.init(hex:"#313a45")
        }
    }
}



