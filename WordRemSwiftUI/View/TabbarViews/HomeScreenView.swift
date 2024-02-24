//
//  HomeScreenView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 19.02.2024.
//

import SwiftUI

struct HomeScreenView: View {
    @State private var offsets: [CGFloat] = Array(repeating: 0, count: 4)
    
    var body: some View {
        ZStack {
            LinearBackgroundView()
            ForEach(0..<4) { index in
                CardView(title: "English Word", subtitle: "Definition", image: Image(systemName: "pencil"))
                    .offset(x: offsets[index])
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offsets[index] = gesture.translation.width
                            }
                            .onEnded { _ in
                                if abs(offsets[index]) > 100 {
                                    offsets[index] = 0
                                } else {
                                    offsets[index] = 0
                                }
                            }
                    )
            }
        }

    }
}

#Preview {
    HomeScreenView()
}
