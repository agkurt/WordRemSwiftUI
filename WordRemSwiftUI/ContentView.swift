//
//  ContentView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI

struct ContentView: View {
    @State private var text1: String = ""
    @State private var text2: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.green]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ImageView()
                    TextField("Enter text 1", text: $text1)
                        .textFieldStyle(.automatic)
                        .frame(width: geometry.size.width * 0.95, height: geometry.size.height * 0.1)
                    
                    TextField("Enter text 2", text: $text2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: geometry.size.width * 0.95, height: geometry.size.height * 0.1)
                    
        
                }
            }
        }
    }
}



#Preview {
    ContentView()
}
