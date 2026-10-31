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
            // Yüklenirken dört ayraç hafifçe sallanır
            BookmarkMark(mood: .speaking, width: 12)

            if let message {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Colors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
