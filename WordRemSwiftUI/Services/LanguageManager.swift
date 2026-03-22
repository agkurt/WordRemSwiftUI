//
//  LanguageManager.swift
//  WordRemSwiftUI
//
//  Kullanıcının onboarding'de seçtiği anadile göre tüm UI string'lerini yöneten merkezi manager.
//  Cihaz diline (Locale.current) hiçbir bağımlılık yoktur.
//  Supabase'den gelen native_lang_id ile UserDefaults'taki userNativeLangCode senkronize tutulur.
//

import SwiftUI
import Combine

final class LanguageManager: ObservableObject {

    // MARK: - Singleton (optional usage — EnvironmentObject tercih edilmeli)
    static let shared = LanguageManager()

    // MARK: - Sabitler
    static let defaultCode = "en"
    static let supportedCodes = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
    private let userDefaultsKey = "userNativeLangCode"

    // RTL dil kodları
    private let rtlCodes: Set<String> = ["ar", "he", "fa", "ur"]

    // MARK: - Yayımlanan Özellik
    /// Değiştiğinde tüm bağlı View'lar otomatik yeniden render edilir.
    @Published private(set) var currentLanguageCode: String

    // MARK: - Init
    init() {
        let saved = UserDefaults.standard.string(forKey: "userNativeLangCode") ?? Self.defaultCode
        let validated = Self.supportedCodes.contains(saved.lowercased()) ? saved.lowercased() : Self.defaultCode
        currentLanguageCode = validated
    }

    // MARK: - Dil Ayarlama
    /// Dili değiştirir, UserDefaults'a yazar ve tüm observer'ları tetikler.
    func setLanguage(_ code: String) {
        let normalized = code.lowercased()
        let resolved = Self.supportedCodes.contains(normalized) ? normalized : Self.defaultCode
        guard resolved != currentLanguageCode else { return }
        currentLanguageCode = resolved
        UserDefaults.standard.set(resolved, forKey: userDefaultsKey)
    }

    // MARK: - Supabase Senkronizasyonu
    /// Kullanıcı profilinden native_lang_id alır, languages tablosunda koda çevirir ve dili günceller.
    /// Hata durumunda mevcut değer (fallback: "en") korunur.
    @MainActor
    func syncFromSupabase() async {
        guard let user = try? await SupabaseDataService.shared.fetchUserProfile(),
              let nativeLangId = user.nativeLangId else { return }

        guard let languages = try? await SupabaseDataService.shared.fetchLanguages() else { return }

        if let lang = languages.first(where: { $0.id == nativeLangId }) {
            setLanguage(lang.code)
        }
    }

    // MARK: - RTL Desteği
    /// Seçili dil sağdan sola yazılıyorsa `.rightToLeft` döner.
    var layoutDirection: LayoutDirection {
        rtlCodes.contains(currentLanguageCode) ? .rightToLeft : .leftToRight
    }

    /// SwiftUI `environment(\.layoutDirection, ...)` için kullanılır.
    var userInterfaceLayoutDirection: UserInterfaceLayoutDirection {
        rtlCodes.contains(currentLanguageCode) ? .rightToLeft : .leftToRight
    }

    // MARK: - OL (Onboarding) String'leri
    func s(_ key: OL.Key) -> String {
        OL.s(key, for: currentLanguageCode)
    }

    func f(_ key: OL.Key, _ arg: String) -> String {
        String(format: s(key), arg)
    }

    // MARK: - AL (App) String'leri
    func s(_ key: AL.Key) -> String {
        AL.s(key, for: currentLanguageCode)
    }

    func f(_ key: AL.Key, _ arg: String) -> String {
        String(format: s(key), arg)
    }

    func f(_ key: AL.Key, _ arg: Int) -> String {
        String(format: s(key), arg)
    }

    func f(_ key: AL.Key, _ arg1: Int, _ arg2: Int) -> String {
        String(format: s(key), arg1, arg2)
    }

    // MARK: - Quiz Kelimeleri
    var quizCorrectWords: [String] {
        OL.quizCorrectWords(for: currentLanguageCode)
    }

    var quizDecoyWords: [String] {
        OL.quizDecoyWords(for: currentLanguageCode)
    }

    // MARK: - Paywall Yorumları
    var paywallReviews: [(String, String)] {
        AL.paywallReviews(for: currentLanguageCode)
    }

    // MARK: - Dil İsmi Yardımcısı
    /// İstenen ISO kodu için seçili dilde yazılmış dil ismini döner.
    /// Örn: currentLanguageCode="tr", isoCode="en" → "İngilizce"
    func languageName(for isoCode: String) -> String {
        let locale = Locale(identifier: currentLanguageCode)
        return locale.localizedString(forLanguageCode: isoCode) ?? isoCode.uppercased()
    }

    // MARK: - "X bilenler için" Subtitle
    func forSpeakersSubtitle(nativeLangCode: String? = nil) -> String {
        let code = nativeLangCode ?? currentLanguageCode
        let langName = languageName(for: code)
        return f(.forSpeakersFormat, langName)
    }
}
