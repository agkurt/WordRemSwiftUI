//
//  MotherTongueView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 25.04.2024.
//

import SwiftUI

struct MotherTongueView: View {
    
    @StateObject var viewModel = MotherTongueViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    Image("turkey")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                    
                    Button(action: {
                        Task {
                            await viewModel.addMotherTongue(motherTongue: viewModel.motherTongue.rawValue)
                        }
                    }, label: {
                        Text("Done")
                    })
                }
            }
        }
    }
}

#Preview {
    MotherTongueView()
}

