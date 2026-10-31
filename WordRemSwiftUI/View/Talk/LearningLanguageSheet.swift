//
//  LearningLanguageSheet.swift
//  WordRemSwiftUI
//
//  Ana sayfadaki dil rozeti: öğrenilen dilleri listeler, yeni dil eklemek için
//  öğretmenle kısa bir kurulum konuşması başlatır. Her dil ayrı bir defter.
//

import SwiftUI

private func loc(_ v: [String]) -> String {
    let order = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
    let i = order.firstIndex(of: LanguageManager.shared.currentLanguageCode) ?? 1
    return v.indices.contains(i) ? v[i] : v[1]
}

enum LearningText {
    static var title: String { loc(["Dillerim", "My languages", "Meine Sprachen", "Mes langues", "Mis idiomas", "Le mie lingue", "Мои языки", "我的语言"]) }
    static var subtitle: String { loc(["Her dil ayrı bir defter.", "Each language is its own notebook.", "Jede Sprache ist ein eigenes Heft.", "Chaque langue a son carnet.", "Cada idioma es un cuaderno.", "Ogni lingua è un quaderno.", "Каждый язык — своя тетрадь.", "每种语言一本笔记。"]) }
    static var newNotebook: String { loc(["YENİ DEFTER AÇ", "START A NEW NOTEBOOK", "NEUES HEFT", "NOUVEAU CARNET", "NUEVO CUADERNO", "NUOVO QUADERNO", "НОВАЯ ТЕТРАДЬ", "新笔记本"]) }
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
        LupaShared.save(target: code, native: OL.nativeLangCode)
    }
}

struct LearningLanguageSheet: View {
    /// Eklenmiş bir dil: hemen geçilir. Yeni dil: kurulum konuşması başlar.
    var onSwitch: (String) -> Void
    var onSetup: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    private let current = LearningLanguages.current
    private let added = LearningLanguages.added

    private var codes: [String] {
        let all = LanguageManager.supportedCodes.filter { $0 != OL.nativeLangCode.lowercased() }
        // Öğrenilenler üstte
        return all.filter { added.contains($0) } + all.filter { !added.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LearningText.title)
                        .font(DS.Font.display(34, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                    Text(LearningText.subtitle)
                        .font(DS.Font.ui(14))
                        .foregroundStyle(DS.Colors.muted)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.inkSoft)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 10)
            .padding(.top, 24)
            .padding(.bottom, 18)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Açık defterler (öğrenilenler) kapak olarak, yeniler kesik çizgili satır
                    VStack(spacing: 10) {
                        ForEach(codes.filter { added.contains($0) }, id: \.self) { code in notebook(code) }
                    }
                    let fresh = codes.filter { !added.contains($0) }
                    if !fresh.isEmpty {
                        Text(LearningText.newNotebook)
                            .font(DS.Font.eyebrow)
                            .tracking(1.4)
                            .foregroundStyle(DS.Colors.muted)
                            .padding(.top, 26)
                            .padding(.bottom, 4)
                        ForEach(fresh, id: \.self) { code in newRow(code) }
                    }

                    Text(LearningText.footer)
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                        .padding(.top, 16)

                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
        .paperBackground()
    }

    private func languageName(_ code: String) -> String {
        let n = LanguageManager.shared.languageName(for: code)
        return n.prefix(1).uppercased() + n.dropFirst()
    }

    /// Küçük defter kapağı: dolu (açılmış) ya da kesik çizgili (yeni)
    private func cover(_ code: String, filled: Bool, width: CGFloat) -> some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: width * 0.08, bottomLeadingRadius: width * 0.08,
                                           bottomTrailingRadius: width * 0.16, topTrailingRadius: width * 0.16)
        return Text(code.uppercased())
            .font(.system(size: width * 0.2, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(filled ? DS.Colors.ink : DS.Colors.muted)
            .padding(.horizontal, width * 0.1).padding(.vertical, width * 0.05)
            .background(filled ? DS.Colors.paperRaised : .clear, in: RoundedRectangle(cornerRadius: 3))
            .frame(width: width, height: width * 1.3)
            .background(filled ? DS.Colors.slate : .clear, in: shape)
            .overlay(shape.strokeBorder(filled ? .clear : Color(hex: "#B8B0A4"), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])))
    }

    private func notebook(_ code: String) -> some View {
        let isCurrent = code == current
        return Button {
            if !isCurrent { onSwitch(code) }
            dismiss()
        } label: {
            HStack(spacing: 16) {
                cover(code, filled: true, width: 54)
                    .overlay(alignment: .topTrailing) {
                        if isCurrent { RibbonShape().fill(DS.Colors.accent).frame(width: 8, height: 20).padding(.trailing, 8).offset(y: -2) }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(languageName(code))
                        .font(DS.Font.display(21, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                    Text(LearningText.level(LearningLanguages.level(code)))
                        .font(DS.Font.ui(13))
                        .foregroundStyle(DS.Colors.muted)
                }
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Colors.accent)
                }
            }
            .padding(14)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isCurrent ? DS.Colors.accent : DS.Colors.line, lineWidth: isCurrent ? 1.5 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func newRow(_ code: String) -> some View {
        Button {
            onSetup(code)
            dismiss()
        } label: {
            HStack(spacing: 16) {
                cover(code, filled: false, width: 32)
                Text(languageName(code))
                    .font(DS.Font.ui(17, weight: .medium))
                    .foregroundStyle(DS.Colors.ink)
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.inkSoft)
            }
            .frame(minHeight: 62)
            .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.line).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
