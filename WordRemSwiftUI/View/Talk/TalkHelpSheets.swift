//
//  TalkHelpSheets.swift
//  WordRemSwiftUI
//
//  Sesli ekranın sol üst düğmesi (Pingo gibi):
//   • Derste "?" → "Takıldın mı?": daha yavaş tekrar et / tekrar açıkla
//   • Asistanla sohbette → "Bir konu seç": Temel · Hayat · Sosyal ya da kendi konun; AI sohbeti o konuya göre yönlendirir
//

import SwiftUI

// MARK: - Küçük çeviri tablosu (sıra: tr, en, de, fr, es, it, ru, zh)
private func loc(_ v: [String]) -> String {
    let order = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
    let i = order.firstIndex(of: LanguageManager.shared.currentLanguageCode) ?? 1
    return v.indices.contains(i) ? v[i] : v[1]
}

private enum HelpText {
    static var stuckTitle: String { loc(["Takıldın mı?", "Stuck?", "Hängst du fest?", "Tu bloques ?", "¿Te atascaste?", "Sei bloccato?", "Застрял?", "卡住了吗？"]) }
    static var stuckSub: String { loc(["İhtiyacını seç", "Choose what you need", "Wähle, was du brauchst", "Choisis ce dont tu as besoin", "Elige lo que necesitas", "Scegli cosa ti serve", "Выбери, что нужно", "选择你需要的帮助"]) }
    static var slower: String { loc(["Daha yavaş tekrar et", "Repeat more slowly", "Langsamer wiederholen", "Répéter plus lentement", "Repetir más despacio", "Ripeti più lentamente", "Повтори медленнее", "说慢一点再说一遍"]) }
    static var explain: String { loc(["Tekrar açıkla", "Explain again", "Nochmal erklären", "Réexpliquer", "Explicar de nuevo", "Spiega di nuovo", "Объясни ещё раз", "再解释一遍"]) }
    static var proceed: String { loc(["Devam et", "Continue", "Weiter", "Continuer", "Continuar", "Continua", "Продолжить", "继续"]) }
    static var pickTopic: String { loc(["Bir konu seç", "Pick a topic", "Wähle ein Thema", "Choisis un sujet", "Elige un tema", "Scegli un argomento", "Выбери тему", "选一个话题"]) }
    static var custom: String { loc(["Özel", "Custom", "Eigenes", "Perso", "Personal", "Personale", "Своя", "自定义"]) }
    static var createOwn: String { loc(["Kendi konunu oluştur", "Create your own topic", "Eigenes Thema", "Crée ton sujet", "Crea tu tema", "Crea il tuo argomento", "Своя тема", "创建自己的话题"]) }
    static var ownPlaceholder: String { loc(["Ne hakkında konuşmak istersin?", "What do you want to talk about?", "Worüber möchtest du sprechen?", "De quoi veux-tu parler ?", "¿De qué quieres hablar?", "Di cosa vuoi parlare?", "О чём хочешь поговорить?", "你想聊什么？"]) }
    static var start: String { loc(["Başla", "Start", "Los", "Commencer", "Empezar", "Inizia", "Начать", "开始"]) }
}

// MARK: - Konu kataloğu
struct TalkTopic: Identifiable, Hashable {
    enum Category: Int, CaseIterable {
        case basics, life, social
        var title: String {
            switch self {
            case .basics: return loc(["Temel", "Basics", "Grundlagen", "Bases", "Básico", "Base", "Основы", "基础"])
            case .life:   return loc(["Hayat", "Life", "Alltag", "Vie", "Vida", "Vita", "Жизнь", "生活"])
            case .social: return loc(["Sosyal", "Social", "Soziales", "Social", "Social", "Sociale", "Общение", "社交"])
            }
        }
    }
    let id: String
    let category: Category
    let icon: String
    let names: [String]
    /// AI'a giden açıklama (İngilizce)
    let prompt: String
    var title: String { loc(names) }

    static let all: [TalkTopic] = [
        .init(id: "hello", category: .basics, icon: "hand.wave", names: ["Merhaba", "Hello", "Hallo", "Bonjour", "Hola", "Ciao", "Привет", "你好"], prompt: "greetings and introducing yourself"),
        .init(id: "sounds", category: .basics, icon: "waveform", names: ["Sesler ve Temeller", "Sounds & Basics", "Laute & Grundlagen", "Sons et bases", "Sonidos y bases", "Suoni e basi", "Звуки и основы", "发音与基础"], prompt: "tricky sounds and basic pronunciation, with tiny practice words"),
        .init(id: "everyday", category: .basics, icon: "text.bubble", names: ["Günlük İfadeler", "Everyday Phrases", "Alltagsausdrücke", "Expressions du quotidien", "Frases cotidianas", "Frasi quotidiane", "Фразы на каждый день", "日常表达"], prompt: "the most useful everyday phrases"),
        .init(id: "time", category: .basics, icon: "clock", names: ["Zaman", "Time", "Zeit", "Le temps", "El tiempo", "Il tempo", "Время", "时间"], prompt: "telling the time, days and making plans"),
        .init(id: "numbers", category: .basics, icon: "number", names: ["Sayılar", "Numbers", "Zahlen", "Nombres", "Números", "Numeri", "Числа", "数字"], prompt: "numbers, prices and phone numbers"),
        .init(id: "verbs", category: .basics, icon: "figure.walk", names: ["Fiiller", "Verbs", "Verben", "Verbes", "Verbos", "Verbi", "Глаголы", "动词"], prompt: "common everyday verbs in simple sentences"),
        .init(id: "describe", category: .basics, icon: "paintpalette", names: ["Betimleme", "Describing", "Beschreiben", "Décrire", "Describir", "Descrivere", "Описание", "描述"], prompt: "describing people, places and things"),
        .init(id: "sentences", category: .basics, icon: "list.bullet", names: ["Cümle Kurma", "Building Sentences", "Sätze bauen", "Construire des phrases", "Construir frases", "Costruire frasi", "Строим предложения", "造句"], prompt: "building sentences step by step"),
        .init(id: "routine", category: .life, icon: "sun.max", names: ["Günlük Rutin", "Daily Routine", "Tagesablauf", "Routine quotidienne", "Rutina diaria", "Routine quotidiana", "Распорядок дня", "日常作息"], prompt: "talking about your daily routine"),
        .init(id: "food", category: .life, icon: "fork.knife", names: ["Yemek", "Food", "Essen", "Nourriture", "Comida", "Cibo", "Еда", "美食"], prompt: "food, ordering at a café or restaurant"),
        .init(id: "home", category: .life, icon: "house", names: ["Ev", "Home", "Zuhause", "Maison", "Casa", "Casa", "Дом", "家"], prompt: "home, rooms and chores"),
        .init(id: "health", category: .life, icon: "cross.case", names: ["Sağlık", "Health", "Gesundheit", "Santé", "Salud", "Salute", "Здоровье", "健康"], prompt: "health, feeling sick and visiting a doctor or pharmacy"),
        .init(id: "shopping", category: .life, icon: "bag", names: ["Alışveriş", "Shopping", "Einkaufen", "Shopping", "Compras", "Shopping", "Покупки", "购物"], prompt: "shopping, sizes, prices and paying"),
        .init(id: "transport", category: .life, icon: "bus", names: ["Ulaşım", "Getting Around", "Unterwegs", "Transports", "Transporte", "Trasporti", "Транспорт", "交通"], prompt: "transport, tickets and asking for directions"),
        .init(id: "travel", category: .life, icon: "airplane", names: ["Seyahat", "Travel", "Reisen", "Voyage", "Viajes", "Viaggi", "Путешествия", "旅行"], prompt: "travel, airports and hotels"),
        .init(id: "work", category: .life, icon: "briefcase", names: ["İş", "Work", "Arbeit", "Travail", "Trabajo", "Lavoro", "Работа", "工作"], prompt: "work, meetings and job interviews"),
        .init(id: "family", category: .social, icon: "person.2", names: ["Aile", "Family", "Familie", "Famille", "Familia", "Famiglia", "Семья", "家庭"], prompt: "family and the people in your life"),
        .init(id: "friends", category: .social, icon: "person.3", names: ["Arkadaşlar", "Friends", "Freunde", "Amis", "Amigos", "Amici", "Друзья", "朋友"], prompt: "making plans and chatting with friends"),
        .init(id: "slang", category: .social, icon: "quote.bubble", names: ["Deyimler ve Argo", "Idioms & Slang", "Redewendungen & Slang", "Expressions et argot", "Modismos y jerga", "Modi di dire e slang", "Идиомы и сленг", "习语与俚语"], prompt: "natural idioms and casual slang natives really use"),
        .init(id: "dating", category: .social, icon: "heart", names: ["Flört", "Dating", "Dating", "Rendez-vous", "Citas", "Appuntamenti", "Свидания", "约会"], prompt: "light, respectful flirting and dating conversation"),
        .init(id: "feelings", category: .social, icon: "face.smiling", names: ["Duygusal Paylaşım", "Sharing Feelings", "Gefühle teilen", "Partager ses émotions", "Compartir emociones", "Condividere emozioni", "Делимся чувствами", "表达情感"], prompt: "expressing feelings and reacting with empathy"),
        .init(id: "compliments", category: .social, icon: "party.popper", names: ["İltifatlar ve Kutlamalar", "Compliments & Celebrations", "Komplimente & Feiern", "Compliments et fêtes", "Cumplidos y celebraciones", "Complimenti e feste", "Комплименты и праздники", "称赞与庆祝"], prompt: "giving compliments and celebrating"),
        .init(id: "stories", category: .social, icon: "book", names: ["Hikaye Anlatma", "Storytelling", "Geschichten erzählen", "Raconter des histoires", "Contar historias", "Raccontare storie", "Рассказываем истории", "讲故事"], prompt: "telling a short story about something that happened"),
    ]
}

// MARK: - "Takıldın mı?"
struct StuckHelpSheet: View {
    enum Need { case slower, explain }
    var onPick: (Need) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var choice: Need?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).foregroundStyle(DS.Colors.ink)
                }
            }
            Text(HelpText.stuckTitle)
                .font(DS.Font.display(30, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
            Text(HelpText.stuckSub)
                .font(DS.Font.ui(16))
                .foregroundStyle(DS.Colors.muted)
                .padding(.top, 4)
                .padding(.bottom, 24)
            option(.slower, "repeat", HelpText.slower)
            option(.explain, "book", HelpText.explain).padding(.top, 10)
            Spacer(minLength: 24)
            Button(HelpText.proceed) {
                if let choice { onPick(choice) }
                dismiss()
            }
            .buttonStyle(InkButtonStyle(fill: DS.Colors.accent))
            .disabled(choice == nil)
            .opacity(choice == nil ? 0.5 : 1)
        }
        .padding(24)
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(DS.Colors.paper)
    }

    private func option(_ need: Need, _ icon: String, _ title: String) -> some View {
        let on = choice == need
        return Button { withAnimation(.easeOut(duration: 0.15)) { choice = need } } label: {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 17, weight: .medium))
                Text(title).font(DS.Font.ui(18, weight: .medium))
                Spacer()
            }
            .foregroundStyle(on ? DS.Colors.accent : DS.Colors.inkSoft)
            .padding(.horizontal, 20)
            .frame(height: 60)
            .background(on ? DS.Colors.accent.opacity(0.1) : DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(on ? DS.Colors.accent : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - "Bir konu seç"
struct TopicPickerSheet: View {
    /// (gösterilen ad, AI'a giden konu)
    var onPick: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var category: TalkTopic.Category = .basics
    @State private var writingOwn = false
    @State private var own = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).foregroundStyle(DS.Colors.ink)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            Text(HelpText.pickTopic)
                .font(DS.Font.display(30, weight: .bold))
                .foregroundStyle(DS.Colors.ink)
                .padding(.bottom, 18)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        ForEach(TalkTopic.Category.allCases, id: \.self) { c in
                            Button { withAnimation(.easeOut(duration: 0.15)) { category = c } } label: {
                                Text(c.title)
                                    .font(DS.Font.ui(16, weight: .semibold))
                                    .foregroundStyle(category == c ? DS.Colors.paper : DS.Colors.accent)
                                    .padding(.horizontal, 20)
                                    .frame(height: 44)
                                    .background(category == c ? DS.Colors.accent : DS.Colors.accent.opacity(0.1), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if writingOwn {
                        HStack(spacing: 10) {
                            TextField(HelpText.ownPlaceholder, text: $own)
                                .font(DS.Font.ui(16))
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(DS.Colors.paperSunken, in: RoundedRectangle(cornerRadius: 16))
                                .submitLabel(.go)
                                .onSubmit(startOwn)
                            Button(HelpText.start, action: startOwn)
                                .font(DS.Font.ui(16, weight: .semibold))
                                .foregroundStyle(DS.Colors.accent)
                                .disabled(own.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        tile(icon: "plus", kicker: HelpText.custom, title: HelpText.createOwn) {
                            withAnimation { writingOwn = true }
                        }
                        ForEach(TalkTopic.all.filter { $0.category == category }) { t in
                            tile(icon: t.icon, kicker: t.category.title, title: t.title) {
                                onPick(t.title, t.prompt)
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(DS.Colors.paper)
    }

    private func startOwn() {
        let text = own.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        onPick(text, text)
        dismiss()
    }

    private func tile(icon: String, kicker: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(DS.Colors.accent)
                    .frame(height: 40)
                Text(kicker).font(DS.Font.ui(13)).foregroundStyle(DS.Colors.muted)
                Text(title)
                    .font(DS.Font.ui(18, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .padding(.horizontal, 10)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(DS.Colors.line))
        }
        .buttonStyle(.plain)
    }
}
