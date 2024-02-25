//
//  PlusView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 20.02.2024.
//

import SwiftUI

struct PlusView: View {
    @Binding var cardName:String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    TextFieldView(text:$cardName, placeholder: "Card name")
                        .shadow(radius: 10)

                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Done")
                    })
                    .buttonStyle(LoginButtonStyle())
                }
                .navigationTitle("PlusView")
            }
        }
        
    }
}

#Preview {
    PlusView()
}
