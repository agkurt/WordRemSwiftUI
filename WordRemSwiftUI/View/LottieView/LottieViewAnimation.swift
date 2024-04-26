//
//  LottieView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.04.2024.
//

import SwiftUI
import Lottie

struct LottieViewAnimation: View {
    var body: some View {
        LottieView(animation:.named("StartAnimation"))
            .playbackMode(.playing(.toProgress(1, loopMode: .autoReverse)))

    }
}

#Preview {
    LottieViewAnimation()
}
