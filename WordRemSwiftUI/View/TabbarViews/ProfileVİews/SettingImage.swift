//
//  SettingImage.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import SwiftUI

struct SettingImage: View {
  let color: Color
  let imageName: String
  
  var body: some View {
    Image(systemName: imageName)
      .resizable()
      .foregroundStyle(color)
      .frame(width: 25, height: 25)
  }
}
