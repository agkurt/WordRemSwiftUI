//
//  CardDetaillDesignView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 13.03.2024.
//

import SwiftUI

struct CardDetailDesignView: View {
    
    @Binding var wordName: String
    @Binding var wordMean:String
    @Binding var wordDescription:String
    @Binding var isEditing: Bool
    var onDelete: () -> Void

    var body: some View {
        NavigationStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .circular)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.init(hex:"#313a45")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(radius: 20)
                    VStack(alignment: .center) {
                        Text(wordName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                        Text(wordMean)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                        Text(wordDescription)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding([.leading, .bottom, .trailing])
                      
                    }
                    .frame(maxWidth: .infinity,minHeight: 150)
                    .padding()
                    if isEditing {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: onDelete) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.white)
                                }
                                .padding()
                            }
                            Spacer()
                        }
                    }
                }
                .onTapGesture {
                    UIApplication.shared.hideKeyboard()
                }
        }
        .padding()
    }
}

