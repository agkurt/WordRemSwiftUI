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
        TabView(selection: $selectedFlag) {
            ForEach(FlagModel.allCases, id: \.self) { flag in
                VStack {
                    Image(flag.rawValue)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(width: 180, height: 180)
                    Text(flag.rawValue.capitalized)
                        .foregroundColor(selectedFlag == flag ? .blue : .black)
                        .font(selectedFlag == flag ? .headline : .subheadline)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .tag(flag)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .padding()
    }
}
