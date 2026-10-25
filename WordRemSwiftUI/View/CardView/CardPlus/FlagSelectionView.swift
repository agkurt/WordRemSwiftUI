//
//  FlagSelectionView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 21.04.2024.
//

import SwiftUI

struct FlagSelectionView: View {

    @Binding var selectedFlag: FlagModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(FlagModel.allCases, id: \.self) { flag in
                    let selected = selectedFlag == flag
                    VStack(spacing: 8) {
                        Image(flag.rawValue)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .padding(3)
                            .overlay(
                                Circle().stroke(selected ? DS.Colors.accent : DS.Colors.line,
                                                lineWidth: selected ? 2 : 1)
                            )

                        Text(flag.rawValue.capitalized)
                            .font(DS.Font.ui(12, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? DS.Colors.ink : DS.Colors.muted)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
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
