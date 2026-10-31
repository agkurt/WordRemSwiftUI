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
                    // Bayraklar kapağa yapıştırılacak etiketler; seçili olan kalemle halkalanır, adı çizilir
                    VStack(spacing: 8) {
                        Image(flag.rawValue)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(DS.Colors.paperRaised, lineWidth: 2.5))
                            .padding(4)
                            .overlay(
                                Circle().stroke(selected ? DS.Colors.accent : DS.Colors.line,
                                                lineWidth: selected ? 2 : 1)
                            )
                            .rotationEffect(.degrees(selected ? -6 : 0))

                        Text(flag.rawValue.capitalized)
                            .font(DS.Font.ui(12, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? DS.Colors.ink : DS.Colors.muted)
                            .padding(.bottom, 3)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(DS.Colors.accent)
                                    .frame(height: 2)
                                    .opacity(selected ? 1 : 0)
                            }
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
