//
//  MascotAnimationView.swift
//  WordRemSwiftUI
//
//  Lottie mascot wrapper.
//  ⚠️  Animasyonu view gizlenince durdurur — birden fazla view aynı anda bellekte
//  tutulduğunda (NavigationStack) bellek kullanımını minimize eder.
//

import SwiftUI
import Lottie

struct MascotAnimationView: View {
    var width: CGFloat  = 70
    var height: CGFloat = 70

    @State private var isVisible = false

    var body: some View {
        LottieView(animation: .named("reeny_waving"))
            .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
            .playbackMode(
                isVisible
                    ? .playing(.toProgress(1, loopMode: .loop))
                    : .paused(at: .progress(0))
            )
            .frame(width: width, height: height)
            .onAppear  { isVisible = true  }
            .onDisappear { isVisible = false }
    }
}

#Preview {
    MascotAnimationView()
}
