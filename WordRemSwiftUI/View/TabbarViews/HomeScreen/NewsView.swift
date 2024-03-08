//
//  NewsView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.03.2024.
//

import SwiftUI

struct NewsView: View {
  @ObservedObject var viewModel = NewsViewModel()

  @State private var selectedNews: ResultClass?

  var body: some View {
    ZStack {
      LinearBackgroundView()
      ScrollView {
        LazyVGrid(columns: [GridItem(.flexible())]) {
          if viewModel.isLoading {
            ProgressView()
              .frame(maxWidth: .infinity)
          } else {
            if let results = viewModel.newsModel?.result {
                ForEach(results, id:\.self) { result in
                NewsRowView(result: result, onTap: {
                  selectedNews = result
                })
              }
            } else {
              Text("Error fetching news")
            }
          }
        }
      }
      .padding(.leading, 15)
      .padding(.trailing, 15)
    }
    .navigationTitle("News")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      viewModel.getNews()
    }
    .sheet(isPresented: Binding(get: { selectedNews != nil }, set: { _ in selectedNews = nil })) { // Fix for isNotNil binding
      NewsDetailView(result: selectedNews!)
    }
  }
}

#Preview {
  NewsView()
}



