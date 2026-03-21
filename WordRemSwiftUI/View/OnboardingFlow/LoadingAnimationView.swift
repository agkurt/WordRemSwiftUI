//
//  LoadingAnimationView.swift
//  WordRemSwiftUI
//
//  Lottie loading animation wrapper (loading.json).
//  Splash, LaunchScreen ve OnboardingLoading ekranlarında kullanılır.
//

import SwiftUI
import Lottie

struct LoadingAnimationView: View {
    var width: CGFloat  = 120
    var height: CGFloat = 120

    @State private var isVisible = false

    var body: some View {
        LottieView(animation: .named("loading"))
            .configuration(LottieConfiguration(renderingEngine: .automatic))
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
    LoadingAnimationView()
}
