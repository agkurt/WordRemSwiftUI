//
//  CardPlusView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardPlusView: View {
    
    @StateObject private var viewModel = CardPlusViewModel()
    @StateObject private var reminderViewModel = ReminderViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var cardId: String
    var completion: () -> Void
    @State private var isOnToggle = false
    
    init(completion: @escaping () -> Void, cardId: String) {
        self.completion = completion
        self.cardId = cardId
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    Text("Create Your Word")
                        .font(.custom("Poppins-Medium", size: 25))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 20) {
                        CardTextField(text: $viewModel.wordName, placeholder: "Word")
                        Button {
                            Task {
                                await viewModel.translateForWordName(targetLang: viewModel.targetLang.first ?? "", sourceLang: viewModel.sourceLang.first ?? "", text: viewModel.wordName)
                            }
                        } label: {
                            Text("Translate to word")
                        }

                        CardTextField(text: $viewModel.translatedText, placeholder: "Word Mean ")
                        Button(action: {
                            Task {
                                await viewModel.createSentenceUseToWord(name: viewModel.wordName)
                                viewModel.wordDescription = viewModel.examplesWord?.examples.prefix(1).first ?? ""
                            }
                        }, label: {
                            Text("Create example sentence")
                            
                        })
                        CardTextField(text: $viewModel.wordDescription, placeholder: "Example Sentence")
                    }
                    .padding()
                    
                    Toggle(isOn: $isOnToggle, label: {
                        Text("Reminder")
                    })
                    .padding()
                    if isOnToggle {
                        Picker("Repeat", selection: $reminderViewModel.repeatOption) {
                            ForEach(reminderViewModel.repeatOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        if reminderViewModel.repeatOption != "None" {
                            Stepper(value: $reminderViewModel.repeatValue, in: 1...5, label: {
                                Text("Repeat Every \(reminderViewModel.repeatValue) \(reminderViewModel.repeatOption)")
                            })
                            .padding()
                        }
                        
                        DatePicker(
                            "Date",
                            selection: $reminderViewModel.date,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .padding()
                        .datePickerStyle(.compact)
                    }
                    Spacer()
                }
                .onTapGesture {
                    UIApplication.shared.hideKeyboard()
                }
                .onAppear {
                    Task {
                        await viewModel.fetchLanguageInfo(cardId: cardId)
                    }
                }
                .onDisappear {
                    self.completion()
                }
            }
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button(action: {
                        Task {
                            if isOnToggle {
                                reminderViewModel.sendNotifications(title: viewModel.wordName, body: viewModel.wordDescription)
                            }
                            await viewModel.addWordToCard(cardId: cardId)
                        }
                        dismiss()
                    }, label: {
                        Text("Done")
                    })
                    .disabled(viewModel.wordName.isEmpty || viewModel.translatedText.isEmpty || viewModel.wordDescription.isEmpty)
                }
            }
        }
    }
}


