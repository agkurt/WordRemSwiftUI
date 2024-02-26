//
//  AuthState.swift
//  WordRemSwiftUI
//
//  Created by Ahmet Göktürk Kurt on 26.02.2024.
//

import Foundation

enum AuthState {
    case authenticated // Anonymously authenticated in Firebase.
    case signedIn // Authenticated in Firebase using one of service providers, and not anonymous.
    case signedOut // Not authenticated in Firebase.
}
