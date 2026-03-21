//
//  AppLoadingView.swift
//  WordRemSwiftUI
//
//  Tüm ekranlarda ortak yükleme göstergesi.
//

import SwiftUI
import Lottie

struct AppLoadingView: View {
    var message: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            LottieView(animation: .named("reeny_waving"))
                .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .frame(width: 120, height: 120)

            if let message {
                Text(message)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundStyle(Color(hex: "#94a3b8"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
