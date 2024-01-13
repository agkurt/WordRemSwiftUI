//
//  ExampleView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 13.01.2024.
//

import SwiftUI

struct ExampleView: View {
    
    @StateObject var viewModel = ExampleViewModel(exampleApiService: .init(apiService: UrlSessionApiService.shared))
    
    var body: some View {
        List(viewModel.example) { example in
            NavigationLink(destination: )
            HStack {
                Text("\(example.word)")
                    .padding()
                    .foregroundColor(.white)
                    .background(.blue)
                    .clipShape(.circle)
            }
            VStack(alignment: .leading) {
                Text("\(example.id)")
                    .bold()
                    .font(.subheadline)
            }
        }
        .onAppear {
            viewModel.fetchExample()
        }
    }
}



#Preview {
    ExampleView()
}
