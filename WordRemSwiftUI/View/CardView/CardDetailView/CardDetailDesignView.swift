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
    var onDelete: () -> Void
    var onEdit: (() -> Void)? = nil  // Edit callback
    
    func highlightMatches(word: String?, in text: String?) -> Text {
        guard let word = word, let text = text else {
            return Text(text ?? "")
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        
        let words = text.split(separator: " ")
        var highlightedText = Text("")
        
        for currentWord in words {
            if currentWord.contains(word) {
                highlightedText = highlightedText + Text(currentWord)
                    .foregroundColor(AppTheme.Colors.primaryOrange)
                    .fontWeight(.semibold) + Text(" ")
            } else {
                highlightedText = highlightedText + Text(currentWord)
                    .foregroundColor(AppTheme.Colors.textSecondary) + Text(" ")
            }
        }
        
        return highlightedText
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern gradient background - Light and colorful
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppTheme.Colors.cardBackground,
                                AppTheme.Colors.cardBackground.opacity(0.95),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.Colors.primaryOrange.opacity(0.2),
                                        AppTheme.Colors.inputBorder
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: AppTheme.Shadows.cardColor.opacity(0.3), radius: 12, y: 6)
                
                // Decorative orange accent - More subtle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                AppTheme.Colors.primaryOrange.opacity(0.15),
                                AppTheme.Colors.primaryOrange.opacity(0.05),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                    .offset(x: 70, y: -40)
                
                VStack(alignment: .center, spacing: 12) {
                    // Word/Meaning display
                    ZStack {
                        if let name = wordName, !name.isEmpty {
                            Text(name)
                                .font(.custom("Poppins-Bold", size: 32))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.Colors.textPrimary,
                                            AppTheme.Colors.textPrimary.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        if let mean = wordMean, !mean.isEmpty {
                            Text(mean)
                                .font(.custom("Poppins-Bold", size: 32))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.Colors.textPrimary,
                                            AppTheme.Colors.textPrimary.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    
                    // Interactive sentence with audio
                    if let desc = wordDescription, !desc.isEmpty, let word = wordName, !word.isEmpty {
                        InteractiveSentenceView(
                            sentence: desc,
                            highlightedWord: word,
                            targetLanguageCode: targetLanguageCode,
                            nativeLanguageCode: nativeLanguageCode
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                
                // Edit and Delete buttons
                VStack {
                    HStack {
                        Spacer()
                        
                        // Edit button (always visible)
                        if let onEdit = onEdit {
                            Button(action: onEdit) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.Colors.primaryOrange)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: AppTheme.Colors.primaryOrange.opacity(0.5), radius: 8, y: 2)
                                    
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.trailing, isEditing ? 8 : 16)
                            .padding(.top, 16)
                        }
                        
                        // Delete button (only when editing)
                        if isEditing {
                            Button(action: onDelete) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: Color.red.opacity(0.5), radius: 8, y: 2)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                        }
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 145)  // Min height, content grows as needed
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
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
    

