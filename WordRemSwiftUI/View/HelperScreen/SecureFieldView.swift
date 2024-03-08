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

    var body: some View {
        VStack {
            SecureField("Password", text:$text)
                .padding()
                .autocapitalization(.none)
                .background(getColorBasedOnScheme())
                .disableAutocorrection(true)
                .font(Font.system(size: 18, weight: .regular))
                .opacity(0.85)
                .foregroundStyle(.primary)
                .clipShape(.rect(cornerRadius: 10))
                .cornerRadius(30)
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
    let text: Binding<String> = .constant("random")
    return SecureFieldView(text:text )
}
