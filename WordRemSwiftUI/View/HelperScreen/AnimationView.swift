//
//  AnimationView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 22.04.2024.
//

import SwiftUI

struct AnimationView: View {
    @State var start = false
    var body: some View {
        ZStack{
            Text("Loading...").bold().font(Font.custom("Arial-BoldMT", size: 25))
                .foregroundStyle(.black)
            Text("Loading...").bold().font(Font.custom("Arial-BoldMT", size: 25))
                .foregroundStyle(.white)
                .frame(width: 200, height: 50)
                .background(.black.opacity(0.9))
                .mask {
                    Circle()
                        .frame(width: 40, height: 40)
                        .offset(x: start ? -50 : 50)
                }
            Circle().stroke(.black,lineWidth: 3)
                .frame(width: 40, height: 40)
                .offset(x: start ? -50 : 50)
        }
        .frame(width: 250, height: 150)
        .background(Color("DL"),in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 0)
        .onAppear{
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                start = true
            }
        }
    }
}

#Preview {
    AnimationView()
}
