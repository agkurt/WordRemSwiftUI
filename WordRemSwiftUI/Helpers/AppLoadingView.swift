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
        VStack(spacing: 16) {
            LottieView(animation: .named("reeny_waving"))
                .configuration(LottieConfiguration(renderingEngine: .coreAnimation))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .frame(width: 140, height: 140)

            if let message {
                Text(message)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundStyle(Color(hex: "#94a3b8"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
