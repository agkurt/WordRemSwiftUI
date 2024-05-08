//
//  SecureFieldView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 14.02.2024.
//

import SwiftUI

struct SecureFieldView: View {
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme
    @FocusState var focused: Bool
    @State private var isSecureTextEntry: Bool = true
    var placeholder: String = ""
    
    var body: some View {
        let isActive = focused || text.count > 0
        ZStack {
            if isSecureTextEntry {
                SecureField("", text:$text)
                    .font(.custom("Poppins-Light", size: 15))
                    .padding()
                    .autocorrectionDisabled(true)
                    .foregroundColor(.primary)
                    .cornerRadius(30)
                    .focused($focused)
                    .offset(y:15)
                    .opacity(isActive ? 1 : 0)
                    .textInputAutocapitalization(.never)
            } else {
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
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    isSecureTextEntry.toggle()
                }) {
                    if isSecureTextEntry {
                        Image(systemName: "eye")
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.gray)
                    }
                }
            }
            HStack {
                Text(placeholder)
                    .foregroundColor(.gray.opacity(5.0))
                    .frame(height: 14)
                    .font(.system(size: isActive ? 10 : 14, weight: .regular))
                    .offset(y: isActive ? -7 : 0)
                
                Spacer()
            }
        }
        .animation(.linear(duration: 0.2), value: focused)
        .frame(maxWidth: .infinity,alignment:.center)
        .padding(.horizontal, 16)
        .background(getColorBasedOnScheme())
        .cornerRadius(30)
        .onTapGesture {
            focused = true
        }
    }
    
    private func getColorBasedOnScheme() -> Color  {
        switch colorScheme {
        case .light:
            return Color.init(hex: "#a2a7ac")
        case .dark:
            return Color.init(hex: "#1c2127")
            
        default:
            return Color.init(hex:"")
        }
    }
}

#Preview {
    SecureFieldView(text: .constant(""),placeholder: "Password")
}

