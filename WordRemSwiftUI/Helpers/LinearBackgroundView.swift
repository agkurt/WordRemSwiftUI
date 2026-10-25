//
//  LinearBackgroundView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 14.02.2024.
//

import SwiftUI

struct LinearBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.Colors.backgroundStart, AppTheme.Colors.backgroundEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
}


#Preview {
    LinearBackgroundView()
}

// MARK: - AppTheme
struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Core Palette
        static let backgroundStart = DS.Colors.paper
        static let backgroundEnd = DS.Colors.paper
        
        static let cardBackground = DS.Colors.paperRaised
        static let navBarBackground = DS.Colors.paper.opacity(0.92)
        
        // Accents
        static let primaryOrange = DS.Colors.accent
        static let darkOrange = DS.Colors.accentDeep
        
        static let destructive = DS.Colors.danger
        static let destructiveSoft = DS.Colors.dangerSoft
        
        // Text
        static let textPrimary = DS.Colors.ink
        static let textSecondary = DS.Colors.muted
        
        // UI Elements
        static let buttonBackground = DS.Colors.paperRaised
        static let inputBackground = DS.Colors.paperSunken
        static let inputBorder = DS.Colors.line
        
        static let circularButtonBg = DS.Colors.paperRaised
        static let circularButtonIcon = DS.Colors.inkSoft
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let softRadius: CGFloat = 8
        static let softY: CGFloat = 4
        static let softColor = Color.black.opacity(0.04)
        
        static let cardRadius: CGFloat = 14
        static let cardY: CGFloat = 6
        static let cardColor = Color.black.opacity(0.05)
        
        static let vibrantRadius: CGFloat = 12
        static let vibrantY: CGFloat = 6
        static let vibrantColor = Color.black.opacity(0.05)
    }
}

// MARK: - Keyboard Dismiss
extension View {
    /// Boş alana tıklandığında klavyeyi kapat
    func hideKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.hideKeyboard()
            }
        )
    }
}
