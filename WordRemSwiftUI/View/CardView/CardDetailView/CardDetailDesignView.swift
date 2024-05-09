//
//  CardDetaillDesignView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 13.03.2024.
//

import SwiftUI

struct CardDetailDesignView: View {
    
    @ObservedObject var notificationManager = NotificationManager()
    @Binding var wordName: String?
    @Binding var wordMean:String?
    @Binding var wordDescription:String?
    @Binding var isEditing: Bool
    var onDelete: () -> Void
    
    func highlightMatches(word: String?, in text: String?) -> Text {
        guard let word = word, let text = text else {
            return Text(text ?? "")
        }
        
        let words = text.split(separator: " ")
        var highlightedText = Text("")
        
        for currentWord in words {
            if currentWord.contains(word) {
                highlightedText = highlightedText + Text(currentWord).foregroundColor(.orange) + Text(" ")
            } else {
                highlightedText = highlightedText + Text(currentWord) + Text(" ")
            }
        }
        
        return highlightedText
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.init(hex:"#313a45")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(radius: 20)
                    .overlay(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 20)
                            .trim(from:0.80,to: 1)
                            .frame(width: 220,height: 200)
                            .foregroundStyle(.orange)
                    }
                
                VStack(alignment:.center) {
                    VStack {
                        ZStack {
                            Text(wordName ?? "")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            Text(wordMean ?? "")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                        .padding()
                        
                        highlightMatches(word: wordName, in: wordDescription)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
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
            .frame(height: 125)
            .padding()
        }
    }
}

struct CardDetailDesignView_Previews: PreviewProvider {
    static var previews: some View {
        CardDetailDesignView(wordName: .constant("Word"), wordMean: .constant("Meaning"), wordDescription: .constant("Description"), isEditing: .constant(false), onDelete: {})
    }
}
    

