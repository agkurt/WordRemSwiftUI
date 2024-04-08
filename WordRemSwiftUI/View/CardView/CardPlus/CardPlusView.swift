//
//  CardPlusView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 28.02.2024.
//

import SwiftUI

struct CardPlusView: View {
    @ObservedObject private var viewModel = CardPlusViewModel()
    @ObservedObject private var reminderViewModel = ReminderViewModel()
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
                        CardTextField(text: $viewModel.wordName, placeholder: "Word name")
                        CardTextField(text: $viewModel.wordMean, placeholder: "Word mean ")
                        CardTextField(text: $viewModel.wordDescription, placeholder: "Word description")
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
                    .disabled(viewModel.wordName.isEmpty || viewModel.wordMean.isEmpty || viewModel.wordDescription.isEmpty)
                }
            }
        }
    }
}

