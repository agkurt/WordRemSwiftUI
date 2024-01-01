//
//  ImageView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 27.12.2023.
//

import SwiftUI

struct ImageView: View {
    var body: some View {
        VStack {
            Image("logo")
                .resizable() // ekrana düzgünce sığdırdı.
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.3 ,height: UIScreen.main
                    .bounds.height * 0.2,alignment: .center)
                .padding()
                .shadow(radius: 10) // etrafına gölge koyduk.
        }
    }
}

#Preview {
    ImageView()
}
