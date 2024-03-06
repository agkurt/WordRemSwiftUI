//
//  NewsView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.03.2024.
//

import SwiftUI

struct NewsView: View {
    @ObservedObject var viewModel = NewsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearBackgroundView()
                VStack {
                    if viewModel.newsModel != nil {
                        List(viewModel.newsModel?.result ?? [], id: \.self) { resultElement in
                            if case .resultClass(let result) = resultElement {
                                VStack(alignment: .leading) {
                                    if let imageUrl = URL(string: result.image) {
                                        AsyncImage(url: imageUrl) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    
                                            default:
                                                Color.gray
                                                    .frame(width: 50, height: 50)
                                                    .opacity(0.5)
                                            }
                                        }
                                    }
                                    Text(result.name)
                                        .font(.headline)
                                    Text(result.description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            } else if case .string(let string) = resultElement {
                                Text(string)
                            }
                        }
                    } else {
                        Text("Loading news...")
                    }
                }
                .navigationTitle("News")
            }
        }
        .onAppear {
            viewModel.getNews()
        }
    }
}


#Preview {
    NewsView()
}
