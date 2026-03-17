//
//  MistakesManager.swift
//  WordRemSwiftUI
//
//  Manages the user's incorrect answers (mistakes) using UserDefaults.
//

import Foundation

final class MistakesManager {
    static let shared = MistakesManager()
    
    private let defaults = UserDefaults.standard
    
    // Yalnızca o anki kullanıcı bazında benzersiz key
    private var key: String {
        let uid = SupabaseAuthService.shared.currentUserId?.uuidString ?? "anonymous"
        return "userMistakesIds_\(uid)"
    }
    
    // Doğrudan diske giden ve diskten gelen computed property (Cache bleed'i önler)
    private var currentMistakes: Set<String> {
        get {
            if let array = defaults.stringArray(forKey: key) {
                return Set(array)
            }
            return []
        }
        set {
            defaults.set(Array(newValue), forKey: key)
        }
    }
    
    private init() {}
    
    /// Quiz seansında yanlış yapılan soruları ekler
    func addMistakes(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        var current = currentMistakes
        current.formUnion(ids)
        currentMistakes = current
    }
    
    /// Pratik sırasında doğru bilinenleri siler
    func removeMistakes(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        var current = currentMistakes
        current.subtract(ids)
        currentMistakes = current
    }
    
    /// Hatalı UUID array olarak döndürür
    var mistakeUUIDs: [UUID] {
        currentMistakes.compactMap { UUID(uuidString: $0) }
    }
    
    /// Hiç hatası var mı?
    var hasMistakes: Bool {
        !currentMistakes.isEmpty
    }
    
    /// Hata sayısı
    var count: Int {
        currentMistakes.count
    }
}
