//
//  ExampleDetailView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 13.01.2024.
//

import SwiftUI

struct ExampleDetailView: View {
    
    let example: Example
    
    var body: some View {
        NavigationStack {
            List {
                Text(example.word)
                    .bold()
                    .font(.subheadline)
                    
                Text(example.pronunciation)
                    .font(.footnote)
            }
            .navigationTitle("example: \(example.id)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PostDetailView(post: Post(userId: 1, id: 1, title: "Başlık", body: "Mesaj"))
}

