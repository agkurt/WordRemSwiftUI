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
    @FocusState var focused: Bool
    
    var body: some View {
        let isActive = focused || text.count > 0
        ZStack {
            TextField("", text: $text)
                .font(.custom("Poppins-Light", size: 15))
                .padding()
                .autocorrectionDisabled(true)
                .foregroundColor(.primary)
                .cornerRadius(30)
                .focused($focused)
                .offset(y:10)
                .opacity(isActive ? 1 : 0)
                .textInputAutocapitalization(.never)
            HStack {
                Text(placeholder)
                    .foregroundColor(.gray.opacity(5.0))
                    .frame(height: 14)
                    .font(.system(size: isActive ? 10 : 14, weight: .regular))
                    .offset(y: isActive ? -7 : 0)
                Spacer()
            }
        }
        .onTapGesture {
            focused = true
        }
        .animation(.linear(duration: 0.2), value: focused)
        .frame(maxWidth: .infinity,alignment:.center)
        .padding(.horizontal, 16)
        .background(getColorBasedOnScheme())
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



