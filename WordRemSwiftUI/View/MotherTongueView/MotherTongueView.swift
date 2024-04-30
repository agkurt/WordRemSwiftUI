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

