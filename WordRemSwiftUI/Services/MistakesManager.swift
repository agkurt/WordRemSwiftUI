//
//  MistakesManager.swift
//  WordRemSwiftUI
//
//  Manages the user's incorrect answers (mistakes) using UserDefaults.
//

import Foundation

final class MistakesManager: ObservableObject {
    static let shared = MistakesManager()

    /// Reactive count — PathMapView and other views observe this to update live
    @Published private(set) var count: Int = 0

    var hasMistakes: Bool { count > 0 }

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
            let newCount = newValue.count
            DispatchQueue.main.async { self.count = newCount }
        }
    }

    private init() {
        count = currentMistakes.count
    }

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
}
