//
//  NewsRowView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import SwiftUI

struct NewsRowView: View {
  let result: ResultClass
  let onTap: () -> Void
    
  var body: some View {
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
      VStack(alignment: .center, spacing: 10) {
        Text(result.name)
          .font(.headline)
        Text(result.description)
          .font(.body)
          .foregroundColor(.white)
         
      }
    }
    .onTapGesture {
      onTap()
    }
  }
}
