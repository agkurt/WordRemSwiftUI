//
//  ImageView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 27.12.2023.
//

import SwiftUI

struct IconImageView: View {
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                Image("logo")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: geometry.size.width * 1.5,maxHeight:geometry.size.height * 0.15)
                    .shadow(radius: 15)
            }
            .padding()
        }
    }
}

#Preview {
    IconImageView()
}
    
