//
//  HomeScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//

import SwiftUI

struct HomeScreenView: View {
    
    @ObservedObject var viewModel: HomeScreenViewModel
    @State private var currentPage: Int = 0
    @EnvironmentObject var authManager: AuthManager
    @State private var isSheetPresented = false
    @State var isEditing: Bool = false
    @State var isArcMenuExpanded: Bool = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                    VStack {
                        ScrollView {
                            ForEach(viewModel.cardNames.indices.filter { searchText.isEmpty ? true : viewModel.cardNames[$0].contains(searchText) }, id: \.self) { index in
                            NavigationLink(destination: CardDetailView(viewModel: CardDetailViewModel(), cardName: viewModel.cardNames[index],
                                                                       cardId:viewModel.cardIds[index])) {
                                CardView(isEditing: $isEditing,
                                         title:viewModel.cardNames[index],
                                         image: viewModel.selectedFlag[index],
                                          onDelete: {
                                    if isEditing {
                                        viewModel.deleteCard(at: index)
                                    }
                                })
                                .foregroundStyle(.white)
                            }
                        }
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    }
                    .searchable(text: $searchText)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            ArcMenuButton(buttons: ["text.word.spacing", "newspaper", "translate", "person.crop.circle"])
                                .padding(16)
                        }
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
                        Image(systemName: isEditing ? "checkmark":"trash")
                    }
                }
                
                ToolbarItem(placement:.topBarTrailing) {
                    Button {
                        isSheetPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    .sheet(isPresented: $isSheetPresented) {
                        PlusView(completion: {
                            Task {
                                await viewModel.fetchCardName()
                            }
                        })
                    }
                }
            }
        }
    }
}



