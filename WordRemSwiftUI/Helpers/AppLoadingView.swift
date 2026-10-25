//
//  AppLoadingView.swift
//  WordRemSwiftUI
//
//  Tüm ekranlarda ortak yükleme göstergesi.
//

import SwiftUI

struct AppLoadingView: View {
    var message: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(DS.Colors.muted)
                .scaleEffect(1.2)

            if let message {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#8A8277"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
