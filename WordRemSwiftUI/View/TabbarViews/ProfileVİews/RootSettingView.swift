//
//  RootSettingView.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 9.03.2024.
//

import SwiftUI

struct RootSettingView: View {
    
  let viewToDisplay: String
    
  var body: some View {
    switch viewToDisplay {
    case "theme":
      ThemeSettingView()
    case "widget":
      WidgetSettingView()
    case "some other setting":
      SomeOtherSettingView()
    case "another setting":
      AnotherSettingView()
    default:
      RootSettingView(viewToDisplay: "")
    }
  }
}
