//
//  CardView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 24.02.2024.
//

import SwiftUI

struct CardView: View {
    @Binding var isEditing: Bool
    @StateObject var viewModel = PlusViewModel()
    var title: String
    var image:String
    var onDelete: () -> Void  
    var body: some View {
        
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.init(hex:"#313a45")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(radius: 20)
                .overlay(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 20)
                        .trim(from:0,to: 0.20)
                        .frame(width: 220,height: 200)
                        .foregroundStyle(.orange)
                }
            VStack(spacing: 15) {
                Spacer()
                HStack {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 100,maxHeight: 100)
                }
                
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            
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
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1c2127"))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        .padding()
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(isEditing: .constant(false), title: "Title", image: "imageName", onDelete: {})
    }
}
