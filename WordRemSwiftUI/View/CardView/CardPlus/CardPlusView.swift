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
    @State var isLoading = false
    @State var cardId: String
    var completion: () -> Void
    @State private var isOnToggle = false
    
    init(cardId: String, completion: @escaping () -> Void) {
        self.cardId = cardId
        self.completion = completion
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
                    
                    VStack(alignment:.leading,spacing: 20) {
                        
                        CardTextField(text: $viewModel.wordName, placeholder: "Word")
                        VStack(alignment:.leading) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                                    .frame(width: 25,height: 25)
                            }else {
                                Button {
                                    Task {
                                        await viewModel.translateForWordName(targetLang: viewModel.targetLang.first ?? "", sourceLang: viewModel.sourceLang.first ?? "", text: viewModel.wordName)
                                    }
                                    
                                } label: {
                                    HStack {
                                        Image("translate")
                                            .resizable()
                                            .frame(width: 20,height: 20)
                                            .aspectRatio(contentMode: .fill)
                                        Text("Translate")
                                            .font(.headline)
                                        
                                    }
                                }
                            }
                            
                        }
                        CardTextField(text: $viewModel.wordMean, placeholder: "Word Mean ")
                        
                        if viewModel.isLoadingSentence {
                            ProgressView()
                                .padding()
                                .frame(width: 20,height: 20)
                        }else {
                            if viewModel.sourceLang.first != "EN" {
                                
                            }
                            Button(action: {
                                Task {
                                    if viewModel.sourceLang.first == "EN" {
                                        await viewModel.createSentenceUseToWord(name: viewModel.wordName)
                                    }
                                }
                                
                            }, label: {
                                HStack {
                                    Image("word")
                                        .resizable()
                                        .frame(width: 25,height: 25)
                                        .aspectRatio(contentMode: .fill)
                                    Text("Example Sentence")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                            })
                            .opacity(viewModel.sourceLang.first == "EN" ? 1.0 : 0.5)
                            .disabled(viewModel.sourceLang.first != "EN")
                        }
                        
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
                            await viewModel.addWordToCard(cardId: cardId)
                            completion()
                            if isOnToggle {
                                reminderViewModel.sendNotifications(title: viewModel.wordName, body: viewModel.wordDescription)
                            }
                        }
                        dismiss()
                    }, label: {
                        Text("Done")
                    })
                    .disabled(viewModel.wordName.isEmpty || viewModel.wordMean.isEmpty)
                }
            }
            
            
        }
    }
}


struct CardPlusView_Previews: PreviewProvider {
    static var previews: some View {
        CardPlusView(cardId: "your_card_id_here", completion: {})
    }
}


