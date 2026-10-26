//
//  LearningLanguageSheet.swift
//  WordRemSwiftUI
//
//  Ana sayfadaki dil rozeti: öğrenilen dilleri listeler, yeni dil eklemek için
//  öğretmenle kısa bir kurulum konuşması başlatır (Pingo'daki "Öğrenme" gibi).
//

import SwiftUI

private func loc(_ v: [String]) -> String {
    let order = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
    let i = order.firstIndex(of: LanguageManager.shared.currentLanguageCode) ?? 1
    return v.indices.contains(i) ? v[i] : v[1]
}

enum LearningText {
    static var title: String { loc(["Öğrenme", "Learning", "Lernen", "Apprentissage", "Aprendizaje", "Apprendimento", "Обучение", "学习"]) }
    static func level(_ n: Int) -> String {
        String(format: loc(["Seviye %d", "Level %d", "Level %d", "Niveau %d", "Nivel %d", "Livello %d", "Уровень %d", "等级 %d"]), n)
    }
    static var footer: String {
        loc(["Seviyen, planındaki dersleri bitirdikçe yükselir.", "Your level goes up as you finish lessons in your plan.",
             "Dein Level steigt, wenn du Lektionen in deinem Plan abschließt.", "Ton niveau augmente à mesure que tu termines les leçons de ton plan.",
             "Tu nivel sube a medida que completas las lecciones de tu plan.", "Il tuo livello sale man mano che completi le lezioni del tuo piano.",
             "Твой уровень растёт по мере прохождения уроков плана.", "完成计划中的课程，等级就会提升。"])
    }
    static var settings: String { loc(["Ayarlar", "Settings", "Einstellungen", "Réglages", "Ajustes", "Impostazioni", "Настройки", "设置"]) }
    static var leaveTitle: String {
        loc(["Planın neredeyse hazır", "Your plan is almost ready", "Dein Plan ist fast fertig", "Ton plan est presque prêt",
             "Tu plan está casi listo", "Il tuo piano è quasi pronto", "Твой план почти готов", "你的计划快准备好了"])
    }
    static var leaveMessage: String {
        loc(["Şimdi ayrılırsan ilerlemen kaybolur ve baştan başlaman gerekir.", "If you leave now, you'll lose your progress and have to start over.",
             "Wenn du jetzt gehst, geht dein Fortschritt verloren und du musst neu anfangen.", "Si tu pars maintenant, tu perdras ta progression et devras recommencer.",
             "Si sales ahora, perderás tu progreso y tendrás que empezar de nuevo.", "Se esci ora, perderai i tuoi progressi e dovrai ricominciare.",
             "Если выйдешь сейчас, прогресс пропадёт и придётся начать заново.", "现在离开会丢失进度，需要重新开始。"])
    }
    static var stay: String { loc(["Devam et", "Keep going", "Weitermachen", "Continuer", "Continuar", "Continua", "Продолжить", "继续"]) }
    static var leave: String { loc(["Ayrıl", "Leave", "Verlassen", "Quitter", "Salir", "Esci", "Выйти", "离开"]) }
}

/// Öğrenilen diller ve dil başına plan ilerlemesi.
/// İlk dilin hedef kayıtları eski anahtarlarla ("meet.greet") kalır; sonradan eklenen diller "de:meet.greet" gibi ayrı tutulur.
enum LearningLanguages {
    static let flags: [String: String] = [
        "tr": "🇹🇷", "en": "🇬🇧", "de": "🇩🇪", "fr": "🇫🇷", "es": "🇪🇸", "it": "🇮🇹", "ru": "🇷🇺", "zh": "🇨🇳",
    ]
    private static var d: UserDefaults { .standard }

    static var current: String { (d.string(forKey: "selectedTargetLanguageCode") ?? "en").lowercased() }

    static var primary: String {
        if let p = d.string(forKey: "learning.primary") { return p }
        let c = current
        d.set(c, forKey: "learning.primary")
        return c
    }

    /// Kurulumu yapılmış diller (ilk öğrenilen dil dahil)
    static var added: [String] {
        let list = d.stringArray(forKey: "learning.languages") ?? []
        return list.contains(primary) ? list : [primary] + list
    }

    static func goalKey(_ id: String, code: String = current) -> String {
        code == primary ? id : "\(code):\(id)"
    }

    static func doneCount(_ code: String) -> Int {
        let keys = (UserStore.shared.snapshot.voiceGoalsDone ?? [:]).keys
        return code == primary ? keys.filter { !$0.contains(":") }.count : keys.filter { $0.hasPrefix("\(code):") }.count
    }

    static func level(_ code: String) -> Int { 1 + doneCount(code) / 5 }

    /// Öğrenilen dili değiştir (kurulum konuşması bittiyse ya da dil zaten ekliyse)
    @MainActor static func switchTo(_ code: String) {
        _ = primary     // ilk dil, değişmeden önce kaydedilsin
        var list = added
        if !list.contains(code) { list.append(code) }
        d.set(list, forKey: "learning.languages")
        d.set(code, forKey: "selectedTargetLanguageCode")
        d.set(LanguageManager.shared.languageName(for: code), forKey: "selectedTargetLanguageName")
        let level = max(1, d.integer(forKey: "selectedProficiencyLevel"))
        let minutes = d.integer(forKey: "dailyGoalMinutes")
        Task {
            try? await DataService.shared.saveUserPreferences(
                targetLangCode: code, nativeLangCode: OL.nativeLangCode, proficiencyLevel: level,
                dailyGoalMinutes: minutes > 0 ? minutes : 10)
        }
        ReviewScheduler.shared.reload()
    }
}

struct LearningLanguageSheet: View {
    /// Eklenmiş bir dil: hemen geçilir. Yeni dil: kurulum konuşması başlar.
    var onSwitch: (String) -> Void
    var onSetup: (String) -> Void
    var onSettings: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let current = LearningLanguages.current
    private let added = LearningLanguages.added

    private var codes: [String] {
        let all = LanguageManager.supportedCodes.filter { $0 != OL.nativeLangCode.lowercased() }
        // Öğrenilenler üstte
        return all.filter { added.contains($0) } + all.filter { !added.contains($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .frame(width: 40, height: 40)
                        .background(DS.Colors.paperSunken, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Text(LearningText.title)
                .font(DS.Font.display(34, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(codes, id: \.self) { code in row(code) }

                    Text(LearningText.footer)
                        .font(DS.Font.ui(14))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.top, 14)
                        .padding(.horizontal, 12)

                    Button {
                        dismiss()
                        onSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gearshape")
                                .foregroundStyle(DS.Colors.inkSoft)
                            Text(LearningText.settings)
                                .font(DS.Font.ui(17, weight: .medium))
                                .foregroundStyle(DS.Colors.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DS.Colors.inkSoft)
                        }
                        .padding(.horizontal, 18).padding(.vertical, 18)
                        .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 18))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
        .paperBackground()
    }

    private func row(_ code: String) -> some View {
        let isCurrent = code == current
        let isAdded = added.contains(code)
        return Button {
            if !isCurrent { if isAdded { onSwitch(code) } else { onSetup(code) } }
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(LearningLanguages.flags[code] ?? "🌐")
                    .font(.system(size: 30))
                    .frame(width: 48, height: 48)
                    .background(DS.Colors.paper, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text({ let n = LanguageManager.shared.languageName(for: code); return n.prefix(1).uppercased() + n.dropFirst() }())
                        .font(DS.Font.ui(18, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                    if isAdded {
                        Text(LearningText.level(LearningLanguages.level(code)))
                            .font(DS.Font.ui(13, weight: .medium))
                            .foregroundStyle(DS.Colors.inkSoft)
                    }
                }
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DS.Colors.accent)
                } else if !isAdded {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.inkSoft)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isCurrent ? DS.Colors.paper : DS.Colors.paperSunken)
                    .shadow(color: .black.opacity(isCurrent ? 0.07 : 0), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isCurrent ? DS.Colors.accent.opacity(0.5) : .clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
