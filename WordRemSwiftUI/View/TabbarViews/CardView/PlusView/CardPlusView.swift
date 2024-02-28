//
//  CardPlusView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardPlusView: View {
    @StateObject private var viewModel = CardTextFieldViewModel()
    @State private var isOnToggle = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    Text("Create Your Word")
                        .font(.custom("Poppins-Medium", size: 25))
                        .padding()
                        .frame(maxWidth: .infinity,alignment:.leading)
                    
                    VStack(spacing:20) {
                        CardTextField(text: $viewModel.wordName, placeholder: "Word name")
                        CardTextField(text: $viewModel.wordMean, placeholder: "Word mean ")
                        CardTextField(text: $viewModel.wordDescription, placeholder: "Word description")
                    }
                    .padding()
                    
                    LineView(textPlace: "Set your reminder")
                    
                    Toggle(isOn:$isOnToggle , label: {
                        Text("Reminder")
                           
                    })
                    .padding()
                    
                    
                    
                    Spacer()
                    VStack {
                        Button(action: {
                            
                        }, label: {
                            Text("Done")
                        })
                        .buttonStyle(LoginButtonStyle())
                    }
                }
            }
        }
    }
}


#Preview {
    CardPlusView()
}
