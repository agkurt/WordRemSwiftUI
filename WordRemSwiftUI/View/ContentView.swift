//
//  ContentView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.12.2023.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        
        
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.init(hex:"#00b4d8")]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    VStack {
                        Spacer()
                        IconImageView()
                            .frame(width: geometry.size.width * 1, height: geometry.size.height * 0.65)
                        TextFieldView()
                        Spacer()
                        Spacer()
                        
                    }
                    
                }
                .edgesIgnoringSafeArea(.all)
            }
           
        }
    }
    // geometry.size.width *0.95
}

#Preview {
    ExampleView()
}
