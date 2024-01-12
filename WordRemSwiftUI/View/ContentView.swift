//
//  ContentView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.init(hex:"#00b4d8")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack {
                    IconImageView()
                    TextFieldView()
                }
                
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
    // geometry.size.width *0.95
}

#Preview {
    ContentView()
}
