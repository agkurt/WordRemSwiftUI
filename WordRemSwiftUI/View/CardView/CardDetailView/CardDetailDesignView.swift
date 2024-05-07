//
//  CardDetaillDesignView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 13.03.2024.
//

import SwiftUI

struct CardDetailDesignView: View {
    
    @Binding var wordName: String?
    @Binding var wordMean:String?
    @Binding var wordDescription:String?
    @Binding var isEditing: Bool
    var onDelete: () -> Void
   
    var body: some View {
        NavigationStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.init(hex:"#313a45")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 200,height: 300)
                        .shadow(radius: 20)
                    VStack(alignment: .center) {
                        Text(wordName ?? "")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(wordMean ?? "")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(wordDescription ?? "")
                            .font(.subheadline)
                            .foregroundColor(.white)
                      
                    }
                   
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
        }
    }
}

