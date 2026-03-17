//
//  FlagSelectionView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 21.04.2024.
//

import SwiftUI

struct FlagSelectionView: View {
    
    @Binding var selectedFlag:FlagModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(FlagModel.allCases, id: \.self) { flag in
                    VStack(spacing: 12) {
                        Image(flag.rawValue)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(selectedFlag == flag ? AppTheme.Colors.primaryOrange : Color.clear, lineWidth: 3)
                            )
                            .shadow(color: selectedFlag == flag ? AppTheme.Colors.primaryOrange.opacity(0.4) : .clear, radius: 8, y: 4)
                            .scaleEffect(selectedFlag == flag ? 1.05 : 0.95)
                            .animation(.spring(response: 0.3), value: selectedFlag)
                        
                        Text(flag.rawValue.capitalized)
                            .font(.custom("Poppins-Medium", size: 12))
                            .foregroundStyle(selectedFlag == flag ? AppTheme.Colors.primaryOrange : AppTheme.Colors.textSecondary)
                    }
                    .padding(.vertical, 8)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFlag = flag
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}


struct FlagSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        FlagSelectionView(selectedFlag: .constant(.chinese))
    }
}

