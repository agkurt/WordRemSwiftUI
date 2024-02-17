//
//  ImageView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 27.12.2023.
//

import SwiftUI

struct IconImageView: View {
    
    var body: some View {
        VStack{
            Image("logo")
                .resizable()
                .allowedDynamicRange(.constrainedHigh)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 150, maxHeight: 150)
                .shadow(radius: 20)
        }
        .padding()
    }
}

#Preview {
    IconImageView()
}

