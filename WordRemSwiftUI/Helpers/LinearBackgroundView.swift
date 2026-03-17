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
        static let backgroundStart = Color(hex: "#f4f6f9") // Light grayish blue
        static let backgroundEnd = Color(hex: "#ffffff")   // Pure white
        
        static let cardBackground = Color.white
        static let navBarBackground = Color.white.opacity(0.85)
        
        // Accents
        static let primaryOrange = Color(hex: "#f97316")
        static let darkOrange = Color(hex: "#ea580c")
        
        static let destructive = Color.red
        static let destructiveSoft = Color.red.opacity(0.1)
        
        // Text
        static let textPrimary = Color.black.opacity(0.85)
        static let textSecondary = Color.gray
        
        // UI Elements
        static let buttonBackground = Color.white
        static let inputBackground = Color(hex: "#f8f9fa")
        static let inputBorder = Color(hex: "#e2e8f0")
        
        static let circularButtonBg = Color.white
        static let circularButtonIcon = Color.black.opacity(0.7)
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let softRadius: CGFloat = 8
        static let softY: CGFloat = 4
        static let softColor = Color.black.opacity(0.06)
        
        static let cardRadius: CGFloat = 14
        static let cardY: CGFloat = 6
        static let cardColor = Color.black.opacity(0.08)
        
        static let vibrantRadius: CGFloat = 12
        static let vibrantY: CGFloat = 6
        static let vibrantColor = Colors.primaryOrange.opacity(0.3)
    }
}
