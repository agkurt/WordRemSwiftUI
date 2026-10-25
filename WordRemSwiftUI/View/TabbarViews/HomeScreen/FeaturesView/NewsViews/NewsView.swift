//
//  NewsView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 6.03.2024.
//

import SwiftUI

struct NewsView: View {
  var body: some View {
    ZStack {
      Color(hex: "#0b1017").ignoresSafeArea()
      
      VStack(spacing: 16) {
        Image(systemName: "newspaper.fill")
          .font(.system(size: 60))
          .foregroundColor(Color(hex: "#C2512F"))
        
        Text("News Coming Soon")
          .font(.system(size: 22, weight: .semibold, design: .serif))
          .foregroundColor(.white)
        
        Text("We are working hard to bring you the best news articles for language learning.")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.gray)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }
    }
  }
}

#Preview {
  NewsView()
}



