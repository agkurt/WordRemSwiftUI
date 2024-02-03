//
//  KeyboardObserver.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 3.02.2024.
//

import SwiftUI
import Combine

class KeyboardObserver: ObservableObject {
    @Published private(set) var keyboardHeight: CGFloat = 0
    
    init() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { notification in
                withAnimation {
                    (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
                }
            }
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellables)
    }
    
    private var cancellables: Set<AnyCancellable> = []
}


