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
          .foregroundColor(Color(hex: "#f97316"))
        
        Text("News Coming Soon")
          .font(.custom("Poppins-SemiBold", size: 22))
          .foregroundColor(.white)
        
        Text("We are working hard to bring you the best news articles for language learning.")
          .font(.custom("Poppins-Regular", size: 14))
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



