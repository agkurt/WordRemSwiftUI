//
//  SentenceScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import SwiftUI

struct SentenceScreenView: View {
    @EnvironmentObject var sentenceViewModel: SentenceViewModel
    @State private var showAlert = false
    @State private var selectedExample: String?
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: - Header Card
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "book.pages")
                                    .font(.system(size: 24))
                                    .foregroundStyle(AppTheme.Colors.primaryOrange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Learn with Examples")
                                        .font(.custom("Poppins-Bold", size: 20))
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                    Text("Enter an English word to see real-world usage")
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }
                            
                            // Modern Search Input
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(isInputFocused ? AppTheme.Colors.primaryOrange : AppTheme.Colors.textSecondary)
                                    .font(.system(size: 16, weight: .medium))
                                
                                TextField("Type a word (e.g., beautiful, journey)", text: $sentenceViewModel.word)
                                    .font(.custom("Poppins-Regular", size: 16))
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($isInputFocused)
                                    .onSubmit {
                                        fetchExamples()
                                    }
                                
                                if !sentenceViewModel.word.isEmpty {
                                    Button(action: { sentenceViewModel.word = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.Colors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isInputFocused ? AppTheme.Colors.primaryOrange.opacity(0.5) : AppTheme.Colors.inputBorder, lineWidth: 1.5)
                                    )
                            )
                            
                            // Fetch Button
                            Button(action: fetchExamples) {
                                HStack(spacing: 10) {
                                    if sentenceViewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.9)
                                    } else {
                                        Image(systemName: "sparkles")
                                        Text("Generate Examples")
                                            .font(.custom("Poppins-SemiBold", size: 16))
                                    }
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: sentenceViewModel.word.isEmpty ? [Color.gray.opacity(0.5)] : [Color(hex: "#f97316"), Color(hex: "#ea580c")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(
                                    color: sentenceViewModel.word.isEmpty ? .clear : Color(hex: "#f97316").opacity(0.4),
                                    radius: 12,
                                    y: 6
                                )
                            }
                            .disabled(sentenceViewModel.word.isEmpty || sentenceViewModel.isLoading)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.Colors.cardBackground)
                                .shadow(color: AppTheme.Shadows.cardColor, radius: 8, y: 4)
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // MARK: - Results Section
                        if sentenceViewModel.isLoading {
                            LoadingExamplesView()
                        } else if let exampleWords = sentenceViewModel.exampleWords, !exampleWords.examples.isEmpty {
                            VStack(spacing: 20) {
                                // Word Header
                                WordHeaderCard(word: exampleWords.word)
                                
                                // Examples List
                                VStack(spacing: 12) {
                                    ForEach(Array(exampleWords.examples.enumerated()), id: \.offset) { index, example in
                                        ExampleSentenceCard(
                                            example: example,
                                            index: index + 1,
                                            word: exampleWords.word
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else if sentenceViewModel.exampleWords?.examples.isEmpty == true {
                            EmptyResultsView()
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
            .navigationTitle("Example Sentences")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid English word")
            }
        }
        .onReceive(sentenceViewModel.$errorMessage) { errorMessage in
            if errorMessage != nil {
                showAlert = true
            }
        }
    }
    
    private func fetchExamples() {
        UIApplication.shared.hideKeyboard()
        isInputFocused = false
        sentenceViewModel.fetchAllWords()
    }
}

// MARK: - Word Header Card
private struct WordHeaderCard: View {
    let word: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primaryOrange.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(word.prefix(1).uppercased())
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundStyle(AppTheme.Colors.primaryOrange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(word.capitalized)
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                HStack(spacing: 8) {
                    Image(systemName: "text.badge.checkmark")
                        .font(.system(size: 12))
                    Text("\(word.count) letters")
                        .font(.custom("Poppins-Regular", size: 13))
                }
                .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
        )
    }
}

// MARK: - Example Sentence Card
private struct ExampleSentenceCard: View {
    let example: String
    let index: Int
    let word: String
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("#\(index)")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundStyle(AppTheme.Colors.primaryOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.primaryOrange.opacity(0.15))
                        )
                    
                    Text("Example")
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = example
                    withAnimation {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        if isCopied {
                            Text("Copied")
                                .font(.custom("Poppins-Medium", size: 12))
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(isCopied ? .green : AppTheme.Colors.primaryOrange)
                }
            }
            
            Text(highlightWord(in: example, word: word))
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.Colors.inputBorder, lineWidth: 1)
                )
                .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
        )
    }
    
    private func highlightWord(in sentence: String, word: String) -> AttributedString {
        var attributedString = AttributedString(sentence)
        
        if let range = attributedString.range(of: word, options: .caseInsensitive) {
            attributedString[range].foregroundColor = AppTheme.Colors.primaryOrange
            attributedString[range].font = .custom("Poppins-SemiBold", size: 15)
        }
        
        return attributedString
    }
}

// MARK: - Loading View
private struct LoadingExamplesView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(AppTheme.Colors.primaryOrange)
                .scaleEffect(1.3)
            
            VStack(spacing: 8) {
                Text("Generating Examples...")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text("Finding the best usage examples")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Empty Results View
private struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primaryOrange.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.Colors.primaryOrange)
            }
            
            VStack(spacing: 8) {
                Text("No Examples Found")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text("Please try a different English word")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: AppTheme.Shadows.softColor, radius: 4, y: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    SentenceScreenView()
        .environmentObject(SentenceViewModel())
}

