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
    var targetLanguageCode: String = "EN"
    var nativeLanguageCode: String = "TR"
    /// Override which word gets highlighted in the example sentence.
    /// If nil, falls back to `wordName`. Pass the target-language word
    /// (wordMean) so the sentence highlights the correct term.
    var sentenceHighlightWord: String? = nil
    var onDelete: () -> Void
    var onEdit: (() -> Void)? = nil  // Edit callback
    
    func highlightMatches(word: String?, in text: String?) -> Text {
        guard let word = word, let text = text else {
            return Text(text ?? "")
                .foregroundColor(DS.Colors.inkSoft)
        }
        
        let words = text.split(separator: " ")
        var highlightedText = Text("")
        
        for currentWord in words {
            if currentWord.contains(word) {
                highlightedText = highlightedText + Text(currentWord)
                    .foregroundColor(DS.Colors.accent)
                    .fontWeight(.semibold) + Text(" ")
            } else {
                highlightedText = highlightedText + Text(currentWord)
                    .foregroundColor(DS.Colors.inkSoft) + Text(" ")
            }
        }
        
        return highlightedText
    }

    private var isFront: Bool { (wordName ?? "").isEmpty == false }

    private var languageLabel: String {
        let code = (isFront ? targetLanguageCode : nativeLanguageCode).lowercased()
        return Locale.current.localizedString(forLanguageCode: code) ?? code.uppercased()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Eyebrow + actions
            HStack(alignment: .center, spacing: 4) {
                Eyebrow(text: languageLabel, color: isFront ? DS.Colors.accent : DS.Colors.muted)
                Spacer()
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                }
                if isEditing {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(DS.Colors.danger)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 34)

            // Word / meaning
            Group {
                if let name = wordName, !name.isEmpty {
                    Text(name)
                        .font(DS.Font.display(34, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                }
                if let mean = wordMean, !mean.isEmpty {
                    Text(mean)
                        .font(DS.Font.display(30, weight: .regular))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
            }
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .padding(.top, 10)

            Rectangle()
                .fill(isFront ? DS.Colors.accent : DS.Colors.line)
                .frame(width: 32, height: 2)
                .padding(.top, 14)

            // Interactive sentence with audio
            if let desc = wordDescription, !desc.isEmpty, let word = wordName, !word.isEmpty {
                InteractiveSentenceView(
                    sentence: desc,
                    highlightedWord: sentenceHighlightWord ?? word,
                    targetLanguageCode: targetLanguageCode,
                    nativeLanguageCode: nativeLanguageCode
                )
                .padding(.top, 14)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: .infinity, alignment: .topLeading)
        .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(DS.Colors.line, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct CardDetailDesignView_Previews: PreviewProvider {
    static var previews: some View {
        CardDetailDesignView(
            wordName: .constant("cousin"),
            wordMean: .constant("kuzen"),
            wordDescription: .constant("Mon cousin habite à Paris."),
            isEditing: .constant(false),
            targetLanguageCode: "FR",
            nativeLanguageCode: "TR",
            onDelete: {}
        )
    }
}
    

