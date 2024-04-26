//
//  SelectedLanguage.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.04.2024.
//

import SwiftUI

struct SelectedLanguage: View {
    
    @Binding var selectedLanguage: String
    
    var body: some View {
        NavigationStack {
            Text(selectedLanguage)
                .padding()
        }
    }
}

struct SelectedLanguage_Previews: PreviewProvider {
    static var previews: some View {
        SelectedLanguage(selectedLanguage: .constant(""))
    }
}
