//
//  MascotAnimationView.swift
//  WordRemSwiftUI
//
//  Created for Onboarding Lottie Mascot replacing static bird.
//

import SwiftUI
import Lottie

struct MascotAnimationView: View {
    var width: CGFloat = 70
    var height: CGFloat = 70
    
    var body: some View {
        // Önce .json dosyası ile dene
        LottieView(animation: .named("reeny_waving"))
            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
            .frame(width: width, height: height)
        
        // Eğer .lottie dosyanız varsa, bunun yerine alttakini kullanın:
        /*
        LottieView {
            try await DotLottieFile.named("reeny_waving")
        } placeholder: {
            Color.clear
        }
        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
        .frame(width: width, height: height)
        */
    }
}

#Preview {
    MascotAnimationView()
}
