//
//  ContentView.swift
//  WordRemSwiftUI
//

import SwiftUI

class TabBarModifier: ObservableObject {
    @Published var customAddAction: (() -> Void)? = nil
}
