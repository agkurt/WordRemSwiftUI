//
//  GoogleAndAppleSignView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 8.05.2024.
//

import SwiftUI

struct GoogleAndAppleSignView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        HStack(spacing:70) {
            Button {
                authManager.handleGoogleSignIn(with: getRootViewController())
            } label: {
                Image("google")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50,height: 50)
                    .alignmentGuide(.bottom) { d in d[.bottom] }
            }
            Button {
                authManager.handleAppleLogin()
            } label: {
                Image("apple")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60,height: 60)
                    .alignmentGuide(.bottom) { d in d[.bottom] }
            }
        }
        .padding()
    }
}


#Preview {
    GoogleAndAppleSignView()
}

