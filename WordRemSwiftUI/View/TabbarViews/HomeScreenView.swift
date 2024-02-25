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
                CardView(title: "English Word", image: Image(systemName: "pencil"))
                    .offset(x: offsets[index])
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offsets[index] = gesture.translation.width
                            }
                            .onEnded { gesture in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    if gesture.translation.width > 100 {
                                        print("Word marked as learned")
                                        offsets[index] = 400
                                    } else if gesture.translation.width < -100 {
                                        print("Word added to review list")
                                        offsets[index] = -400
                                    } else {
                                        offsets[index] = 0
                                    }
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
