//
//  NewsDetailView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.03.2024.
//

import SwiftUI

struct NewsDetailView: View {
    let result: ResultClass
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    if let imageUrl = URL(string: result.image) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(30)
                                    .padding()
                            default:
                                Color.gray
                                    .frame(width: 80, height: 80)
                                    .opacity(0.5)
                                    .cornerRadius(30)
                            }
                        }
                    }
                    VStack(alignment: .center, spacing: 15) {
                        Text(result.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(result.description)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Link(destination: URL(string: result.url)!) {
                            Text("\(result.url)")
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
