//
//  ToolBarContentView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.05.2024.
//

import SwiftUI

struct ToolbarContentView: View {
    
    @ObservedObject var viewModel: HomeScreenViewModel
    @Binding var isSheetPresented: Bool
    @Binding var isEditing: Bool
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
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
                    PlusView(completion: {
                        Task {
                            await viewModel.fetchCardName()
                        }
                    })
                }
            }
            
            ToolbarItem(placement:.topBarTrailing) {
                NavigationLink(destination: {
                    WordGameView(deckId: "", cardId: "cardId")
                }, label: {
                    Text("")
                })
            }
        }
    }
    
}
