//
//  HomeScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//

import SwiftUI

struct HomeScreenView: View {
    
    @ObservedObject var viewModel = HomeScreenViewModel()
    @State private var currentPage: Int = 0
    @State private var selectedCard: String = ""
    @EnvironmentObject var authManager: AuthManager
    @State private var isSheetPresented = false
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                
                ScrollView {
                    VStack {
                        ForEach(viewModel.cardNames.indices, id: \.self) { index in
                            NavigationLink(destination: CardDetailView(cardName: viewModel.cardNames[index],
                                                                       cardId:viewModel.cardIds[index])) {
                                CardView(title: viewModel.cardNames[index],
                                         image: Image(systemName: "pencil"),
                                         isEditing: $isEditing)
                                
                                .foregroundStyle(.white)
                            }
                        }
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                        
                    }
                }
            }
            .navigationTitle("Cards")
            .onAppear {
                Task {
                    await viewModel.fetchCardName()
                }
            }
            
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button {
                        authManager.signOut()
                        
                    } label: {
                        Text("Signout")
                    }
                }
                
                ToolbarItem(placement:.topBarTrailing) {
                    Button {
                        isEditing.toggle()
                        
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                    }
                }
                
                ToolbarItem(placement:.topBarTrailing) {
                    Button {
                        isSheetPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $isSheetPresented) {
                        PlusView {
                            Task {
                                await viewModel.fetchCardName()
                            }
                        }
                    }
                }
                
            }
        }
    }
}
