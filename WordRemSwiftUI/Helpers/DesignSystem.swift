//
//  DesignSystem.swift
//  WordRemSwiftUI
//
//  "Kâğıt & mürekkep" tasarım sistemi: sıcak kırık beyaz zemin, koyu mürekkep metin,
//  tek imza rengi (terracotta). Başlıklar ve kelimeler serif, arayüz metni SF Pro.
//  Gradient, parlama ve emoji yok — kahraman kelimenin kendisi.
//

import SwiftUI

enum DS {

    // MARK: - Colors
    enum Colors {
        static let paper       = Color(hex: "#F6F2EA")   // ana zemin
        static let paperRaised = Color(hex: "#FFFDF8")   // kart zemini
        static let paperSunken = Color(hex: "#EFE9DE")   // ikincil alanlar, inputlar
        static let line        = Color(hex: "#E4DDD0")   // ayraç, kart kenarı

        static let ink         = Color(hex: "#1C1A17")   // ana metin
        static let inkSoft     = Color(hex: "#4A453E")   // ikincil metin
        static let muted       = Color(hex: "#8A8277")   // açıklama, pasif

        static let accent      = Color(hex: "#C2512F")   // terracotta — imza rengi
        static let accentDeep  = Color(hex: "#9E3F22")
        static let accentSoft  = Color(hex: "#F3E2D8")

        static let slate       = Color(hex: "#2F4B5C")   // ikincil vurgu (Pro, bilgi)

        static let success     = Color(hex: "#3F7D58")
        static let successSoft = Color(hex: "#E3EEE6")
        static let danger      = Color(hex: "#B4423A")
        static let dangerSoft  = Color(hex: "#F4E1DE")
        static let gold        = Color(hex: "#C8962E")   // seri / ödül

        // Defter
        static let rule        = Color(hex: "#E6DFD2")   // satır çizgisi
        static let margin      = Color(hex: "#E0A08A")   // kenar boşluğu çizgisi, dördüncü ayraç
        static let highlight   = Color(hex: "#F3D2C2")   // fosforlu kalem: söylenecek ifade
        static let redPen      = Color(hex: "#B4423A")   // öğretmen düzeltmesi
        static let accentText  = Color(hex: "#A8441F")   // kâğıt üstünde küçük terrakota yazı (kontrast)
        static let note        = Color(hex: "#FBEADF")   // yapışkan not, seçili satır
        static let cardRule    = Color(hex: "#DCE4EA")   // fiş kartının mavi çizgileri
        static let backdrop    = Color(hex: "#C9C1B4")   // sayfa altı (sheet arkası)
    }

    /// Çizgili sayfa ölçüleri
    enum Page {
        static let pitch: CGFloat = 32        // satır aralığı
        static let marginX: CGFloat = 64      // kenar boşluğu çizgisinin yeri
        static let textX: CGFloat = 76        // metnin başladığı yer
    }

    // MARK: - Typography
    enum Font {
        /// Kelimeler ve büyük başlıklar — New York (sistem serif)
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }
        /// Arayüz metni — SF Pro
        static func ui(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight)
        }
        /// Küçük büyük harfli etiketler ("BUGÜN", "İSPANYOLCA")
        static let eyebrow = SwiftUI.Font.system(size: 11, weight: .bold)
    }

    // MARK: - Metrics
    enum Radius {
        static let card: CGFloat   = 18
        static let button: CGFloat = 14
    }
}

// MARK: - Components

/// Küçük harf aralıklı üst etiket
struct Eyebrow: View {
    let text: String
    var color: Color = DS.Colors.accent
    var body: some View {
        // Dile duyarlı büyük harf (Türkçe: i → İ)
        Text(text.uppercased(with: Locale(identifier: AL.currentCode)))
            .font(DS.Font.eyebrow)
            .tracking(1.4)
            .foregroundStyle(color)
    }
}

/// Düz, gölgesiz kart: kâğıt üstünde ince çizgili yüzey
struct PaperCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.paperRaised, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Colors.line, lineWidth: 1))
    }
}

/// Ana eylem butonu: düz mürekkep ya da imza rengi, gölge yok
struct InkButtonStyle: ButtonStyle {
    var fill: Color = DS.Colors.ink
    var foreground: Color = DS.Colors.paperRaised
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.ui(17, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(fill, in: RoundedRectangle(cornerRadius: DS.Radius.button))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// İkincil buton: çizgili, şeffaf
struct OutlineButtonStyle: ButtonStyle {
    var tint: Color = DS.Colors.ink
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.ui(17, weight: .semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .stroke(DS.Colors.line, lineWidth: 1.5)
                    .background(DS.Colors.paperRaised.opacity(configuration.isPressed ? 1 : 0),
                                in: RoundedRectangle(cornerRadius: DS.Radius.button))
            )
    }
}

extension View {
    /// Ekran zemini
    func paperBackground() -> some View {
        background(DS.Colors.paper.ignoresSafeArea())
    }
}

// MARK: - Defter
//
// Uygulamanın kendine has dili: çizgili sayfa, kenar boşluğu notları, fosforlu ifade,
// kırmızı kalem, sağ üstten sarkan dört renkli ayraç ve mühür biçimli düğmeler.

/// Defter ekranlarının küçük metinleri (sıra: tr, en, de, fr, es, it, ru, zh)
enum PageText {
    static func t(_ v: [String]) -> String {
        let order = ["tr", "en", "de", "fr", "es", "it", "ru", "zh"]
        let i = order.firstIndex(of: LanguageManager.shared.currentLanguageCode) ?? 1
        return v.indices.contains(i) ? v[i] : v[1]
    }
    static func page(_ n: Int) -> String {
        t(["s. \(n)", "p. \(n)", "S. \(n)", "p. \(n)", "p. \(n)", "p. \(n)", "с. \(n)", "第 \(n) 页"])
    }
    static var hint: String { t(["İpucu", "Hint", "Tipp", "Indice", "Pista", "Aiuto", "Подсказка", "提示"]) }
    static var translation: String { t(["Çeviri", "Translate", "Übersetzen", "Traduire", "Traducir", "Traduci", "Перевод", "翻译"]) }
    static var topics: String { t(["Konular", "Topics", "Themen", "Sujets", "Temas", "Argomenti", "Темы", "话题"]) }
    static var blankPage: String { t(["Boş sayfa", "Blank page", "Leere Seite", "Page blanche", "Página en blanco", "Pagina bianca", "Чистая страница", "空白页"]) }
    static var freeChat: String { t(["Serbest sohbet", "Free chat", "Freies Gespräch", "Discussion libre", "Charla libre", "Chiacchierata libera", "Свободный разговор", "自由对话"]) }
    static var firstPage: String { t(["İlk sayfa", "First page", "Erste Seite", "Première page", "Primera página", "Prima pagina", "Первая страница", "第一页"]) }
    static var newNotebook: String { t(["Yeni defter", "New notebook", "Neues Heft", "Nouveau carnet", "Cuaderno nuevo", "Nuovo quaderno", "Новая тетрадь", "新笔记本"]) }
    static var meetLupa: String { t(["Lupa ile tanış", "Meet Lupa", "Lerne Lupa kennen", "Fais connaissance avec Lupa", "Conoce a Lupa", "Conosci Lupa", "Знакомство с Лупой", "认识 Lupa"]) }
    static var lupaSpeaking: String { t(["Lupa konuşuyor · dokun, araya gir", "Lupa is talking · tap to cut in", "Lupa spricht · tippen zum Unterbrechen", "Lupa parle · touche pour l'interrompre", "Lupa habla · toca para interrumpir", "Lupa parla · tocca per interrompere", "Лупа говорит · нажми, чтобы перебить", "Lupa 正在说 · 点按打断"]) }
    static var lupaThinking: String { t(["Lupa düşünüyor…", "Lupa is thinking…", "Lupa denkt nach…", "Lupa réfléchit…", "Lupa está pensando…", "Lupa sta pensando…", "Лупа думает…", "Lupa 在思考…"]) }
    static var sayIt: String { t(["Basılı tut, söyle", "Hold and speak", "Halten und sprechen", "Maintiens et parle", "Mantén y habla", "Tieni premuto e parla", "Удерживай и говори", "按住说话"]) }
    static var sayLabel: String { t(["Söyle", "Say", "Sag", "Dis", "Di", "Di'", "Скажи", "说"]) }
    static var listen: String { t(["Dinle", "Listen", "Anhören", "Écouter", "Escuchar", "Ascolta", "Слушать", "听"]) }
    static var saveToNotebook: String { t(["Deftere kaydet", "Save to notebook", "Ins Heft", "Dans le carnet", "Guardar", "Salva", "В тетрадь", "存入笔记"]) }
    static var saved: String { t(["Kaydedildi", "Saved", "Gespeichert", "Enregistré", "Guardado", "Salvato", "Сохранено", "已保存"]) }
    static var youLeftOff: String { t(["kaldığın yer", "where you left off", "hier warst du", "là où tu t'es arrêté", "donde lo dejaste", "dove eri rimasto", "где ты остановился", "上次停在这里"]) }
    static var continueLesson: String { t(["Devam et", "Continue", "Weiter", "Continuer", "Continuar", "Continua", "Продолжить", "继续"]) }
    static var correct: String { t(["doğru", "correct", "richtig", "juste", "correcto", "giusto", "верно", "正确"]) }
    static var whatToWrite: String { t(["Bugün bu sayfaya ne yazalım? Söyle ya da birini seç:",
                                        "What shall we write on this page today? Say it or pick one:",
                                        "Was schreiben wir heute auf diese Seite? Sag es oder wähle:",
                                        "Qu'écrivons-nous sur cette page aujourd'hui ? Dis-le ou choisis :",
                                        "¿Qué escribimos hoy en esta página? Dilo o elige uno:",
                                        "Cosa scriviamo oggi su questa pagina? Dillo o scegline uno:",
                                        "Что запишем сегодня на эту страницу? Скажи или выбери:",
                                        "今天在这页写点什么？说出来或选一个："]) }
    static var subRoleplay: String { t(["Kafede sipariş, otelde giriş…", "Ordering at a café, hotel check-in…", "Im Café bestellen, im Hotel einchecken…", "Commander au café, arriver à l'hôtel…", "Pedir en un café, registrarse en el hotel…", "Ordinare al bar, check-in in hotel…", "Заказ в кафе, заселение в отель…", "咖啡馆点单、酒店入住…"]) }
    static var subPhrases: String { t(["Günlük hayattan kalıplar", "Everyday expressions", "Wendungen aus dem Alltag", "Expressions du quotidien", "Expresiones cotidianas", "Espressioni quotidiane", "Фразы на каждый день", "日常表达"]) }
    static var subQuestion: String { t(["Gramer, kelime, telaffuz", "Grammar, words, pronunciation", "Grammatik, Wörter, Aussprache", "Grammaire, mots, prononciation", "Gramática, palabras, pronunciación", "Grammatica, parole, pronuncia", "Грамматика, слова, произношение", "语法、词汇、发音"]) }
    static var subMyDay: String { t(["Sen anlat, Lupa düzeltsin", "You talk, Lupa corrects", "Du erzählst, Lupa korrigiert", "Tu racontes, Lupa corrige", "Tú cuentas, Lupa corrige", "Tu racconti, Lupa corregge", "Ты рассказываешь, Лупа поправляет", "你来讲，Lupa 来纠正"]) }
}

/// Uç kısmı V kesimli kitap ayracı
struct RibbonShape: Shape {
    func path(in r: CGRect) -> Path {
        let notch = min(r.width * 0.55, r.height * 0.3)
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - notch))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Logo: sayfanın üst kenarından sarkan dört renkli ayraç.
/// Lupa konuşurken hafifçe sallanır, seni dinlerken sesinle uzar.
struct BookmarkMark: View {
    enum Mood { case calm, speaking, listening }
    var mood: Mood = .calm
    var level: Float = 0
    /// Bir ayracın genişliği; boylar buna göre ölçeklenir
    var width: CGFloat = 12
    var colors: [Color] = [DS.Colors.ink, DS.Colors.accent, DS.Colors.slate, DS.Colors.margin]

    private let lengths: [CGFloat] = [3.5, 4.5, 3.0, 4.0]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: mood == .calm)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(alignment: .top, spacing: width * 0.25) {
                ForEach(0..<4, id: \.self) { i in
                    RibbonShape()
                        .fill(colors[i % colors.count])
                        .frame(width: width, height: length(i, t))
                        .rotationEffect(.degrees(angle(i, t)), anchor: .top)
                }
            }
            .frame(height: width * 6, alignment: .top)
        }
        .accessibilityHidden(true)
    }

    private func length(_ i: Int, _ t: Double) -> CGFloat {
        let base = lengths[i] * width
        guard mood == .listening else { return base }
        let wave = CGFloat(0.5 + 0.5 * sin(t * 2.6 + Double(i) * 0.9))
        return base * 1.2 + width * CGFloat(min(1, level * 1.6)) * (0.6 + 0.8 * wave)
    }

    private func angle(_ i: Int, _ t: Double) -> Double {
        guard mood == .speaking else { return 0 }
        return 4.5 * sin(t * 4.2 + Double(i) * 0.7)
    }
}

/// Sayfa boyunca satır çizgileri (her satırın altında ince çizgi)
struct RuledLines: View {
    var pitch: CGFloat = DS.Page.pitch
    var color: Color = DS.Colors.rule
    var body: some View {
        Canvas { ctx, size in
            var y = pitch - 1
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(color))
                y += pitch
            }
        }
        .accessibilityHidden(true)
    }
}

/// Kenar boşluğu çizgisi
struct MarginLine: View {
    var x: CGFloat = DS.Page.marginX
    var body: some View {
        Rectangle()
            .fill(DS.Colors.margin)
            .frame(width: 1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, x)
            .accessibilityHidden(true)
    }
}

/// Yüksekliği satır aralığının katına yuvarlar: alt alta dizilen bloklar hep çizgiye oturur
struct GridSnap: Layout {
    var pitch: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let s = subviews.first else { return .zero }
        let size = s.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        let rows = max(1, (size.height / pitch - 0.02).rounded(.up))
        return CGSize(width: proposal.width ?? size.width, height: rows * pitch)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(width: bounds.width, height: nil))
    }
}

/// Çizgili sayfada satırlara oturan serif metin; istenirse kenar boşluğunda not ("Lupa", "Sen")
struct RuledText: View {
    let text: Text
    var size: CGFloat = 21
    var weight: Font.Weight = .regular
    var italic = false
    var color: Color = DS.Colors.ink
    /// Bir satır kaç çizgi yüksekliğinde (büyük ifadeler 2)
    var rows: Int = 1
    var note: String?
    var noteColor: Color = DS.Colors.accentText

    init(_ text: Text, size: CGFloat = 21, weight: Font.Weight = .regular, italic: Bool = false,
         color: Color = DS.Colors.ink, rows: Int = 1, note: String? = nil, noteColor: Color = DS.Colors.accentText) {
        self.text = text; self.size = size; self.weight = weight; self.italic = italic
        self.color = color; self.rows = rows; self.note = note; self.noteColor = noteColor
    }

    init(_ string: String, size: CGFloat = 21, weight: Font.Weight = .regular, italic: Bool = false,
         color: Color = DS.Colors.ink, rows: Int = 1, note: String? = nil, noteColor: Color = DS.Colors.accentText) {
        self.init(Text(string), size: size, weight: weight, italic: italic, color: color, rows: rows, note: note, noteColor: noteColor)
    }

    var body: some View {
        let pitch = DS.Page.pitch * CGFloat(rows)
        let f = Self.serif(size)
        let spacing = max(0, pitch - f.lineHeight)
        let top = max(0, pitch - 5 - f.ascender)
        let n = Self.serif(14)
        return GridSnap(pitch: pitch) {
            text
                .font(.system(size: size, weight: weight, design: .serif))
                .italic(italic)
                .foregroundStyle(color)
                .lineSpacing(spacing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, top)
                .overlay(alignment: .topLeading) {
                    if let note {
                        Text(note)
                            .font(.system(size: 14, design: .serif).italic())
                            .foregroundStyle(noteColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            // Kenar notu çizginin solunda kalır, araya nefes payı (çizgiye değmez)
                            .frame(width: DS.Page.marginX - 18, alignment: .trailing)
                            .offset(x: -(DS.Page.textX - 6), y: pitch - 5 - n.ascender)
                    }
                }
        }
    }

    static func serif(_ size: CGFloat) -> UIFont {
        let base = UIFont.systemFont(ofSize: size)
        return UIFont(descriptor: base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor, size: size)
    }
}

/// Fosforlu kalemle vurgulanmış metin (satır satır sarar)
func highlightedText(_ s: String, color: Color = DS.Colors.highlight) -> Text {
    var a = AttributedString(" \(s) ")
    a.backgroundColor = color
    return Text(a)
}

/// Mühür biçimli mikrofon düğmesinin görünüşü (hareketi çağıran ekler)
struct StampMic: View {
    enum Look { case idle, ready, holding }
    var look: Look
    var size: CGFloat = 76

    var body: some View {
        let ink: Color = look == .idle ? Color(hex: "#B8B0A4") : DS.Colors.ink
        let fg: Color = look == .holding ? DS.Colors.paperRaised : look == .idle ? DS.Colors.muted : DS.Colors.ink
        ZStack {
            Circle().fill(look == .holding ? DS.Colors.accent : DS.Colors.paper)
            Circle().strokeBorder(look == .holding ? DS.Colors.accent : ink, lineWidth: 2)
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .foregroundStyle(look == .holding ? DS.Colors.paperRaised : ink)
                .padding(size * 0.1)
            Image(systemName: "mic")
                .font(.system(size: size * 0.31, weight: .medium))
                .foregroundStyle(fg)
        }
        .frame(width: size, height: size)
        .background(Circle().fill(DS.Colors.highlight).padding(-10).opacity(look == .holding ? 1 : 0))
        .scaleEffect(look == .holding ? 1.08 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: look)
    }
}

/// Tarihli mürekkep mührü ("Tamam", "Pro")
struct InkStamp: View {
    var top: String
    var title: String
    var bottom: String
    var color: Color = DS.Colors.accent
    var size: CGFloat = 118
    var angle: Double = -12

    var body: some View {
        ZStack {
            Circle().strokeBorder(color, lineWidth: max(2, size * 0.025))
            Circle().strokeBorder(color, lineWidth: 1).padding(size * 0.085)
            VStack(spacing: size * 0.02) {
                Text(top).font(.system(size: size * 0.085, weight: .semibold)).tracking(1.4)
                Text(title).font(.system(size: size * 0.17, weight: .bold, design: .serif))
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(bottom).font(.system(size: size * 0.085, weight: .semibold)).tracking(1.4)
            }
            .padding(.horizontal, size * 0.15)
        }
        .foregroundStyle(color)
        .frame(width: size, height: size)
        .rotationEffect(.degrees(angle))
        .accessibilityElement(children: .combine)
    }
}

/// Noktalı çizgi (içindekiler, ders özeti)
struct DottedLeader: View {
    var color: Color = Color(hex: "#B8B0A4")
    var body: some View {
        GeometryReader { g in
            Path { p in
                p.move(to: CGPoint(x: 0, y: g.size.height / 2))
                p.addLine(to: CGPoint(x: g.size.width, y: g.size.height / 2))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 5]))
        }
        .frame(height: 2)
        .frame(minWidth: 12)
        .accessibilityHidden(true)
    }
}

/// "Etiket ........ değer" satırı
struct LeaderRow: View {
    let label: String
    let value: String
    var size: CGFloat = 18
    var labelColor: Color = DS.Colors.ink
    var valueColor: Color = DS.Colors.ink

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: size, design: .serif))
                .foregroundStyle(labelColor)
                .lineLimit(1)
            DottedLeader().alignmentGuide(.lastTextBaseline) { d in d[.bottom] }
            Text(value)
                .font(DS.Font.ui(size - 1, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Kalemle atılmış tik
struct PenTick: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let sx = r.width / 28, sy = r.height / 24
        p.move(to: CGPoint(x: r.minX + 3 * sx, y: r.minY + 13 * sy))
        p.addCurve(to: CGPoint(x: r.minX + 10 * sx, y: r.minY + 21 * sy),
                   control1: CGPoint(x: r.minX + 6 * sx, y: r.minY + 15 * sy),
                   control2: CGPoint(x: r.minX + 8 * sx, y: r.minY + 18 * sy))
        p.addCurve(to: CGPoint(x: r.minX + 26 * sx, y: r.minY + 2 * sy),
                   control1: CGPoint(x: r.minX + 14 * sx, y: r.minY + 12 * sy),
                   control2: CGPoint(x: r.minX + 19 * sx, y: r.minY + 6 * sy))
        return p
    }
}

/// Seri çentikleri: beşli gruplar (dört dik + bir çapraz)
struct TallyMarks: View {
    let count: Int
    var color: Color = DS.Colors.ink
    var accentLast: Color? = DS.Colors.accent
    var height: CGFloat = 44
    var maxShown: Int = 15

    var body: some View {
        let n = min(count, maxShown)
        let groups = n / 5, rest = n % 5
        HStack(alignment: .center, spacing: height * 0.35) {
            ForEach(0..<groups, id: \.self) { g in
                group(5, color: rest == 0 && g == groups - 1 ? (accentLast ?? color) : color)
            }
            if rest > 0 { group(rest, color: accentLast ?? color) }
        }
        .accessibilityLabel("\(count)")
    }

    private func group(_ k: Int, color: Color) -> some View {
        let w = height * 0.2
        return ZStack {
            HStack(spacing: w) {
                ForEach(0..<min(k, 4), id: \.self) { i in
                    Capsule().fill(color).frame(width: height * 0.09, height: height * (i % 2 == 0 ? 1 : 0.94))
                }
            }
            if k == 5 {
                Capsule().fill(color)
                    .frame(width: height * 1.25, height: height * 0.09)
                    .rotationEffect(.degrees(-32))
            }
        }
        .frame(height: height)
    }
}

/// Defter kapağı zemini: arduvaz bez, solda sırt çizgileri
struct NotebookCover: View {
    var color: Color = DS.Colors.slate
    var body: some View {
        color
            .overlay(alignment: .leading) {
                HStack(spacing: 6) {
                    Rectangle().fill(Color.white.opacity(0.14)).frame(width: 4)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1)
                }
                .padding(.leading, 22)
            }
    }
}

/// Sayfaya bantla yapıştırılmış not kâğıdı
struct StickyNote<Content: View>: View {
    var angle: Double = -1.5
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.note)
            .overlay(alignment: .top) {
                Rectangle().fill(DS.Colors.margin.opacity(0.55))
                    .frame(width: 92, height: 26)
                    .rotationEffect(.degrees(3))
                    .offset(y: -12)
            }
            .rotationEffect(.degrees(angle))
            .shadow(color: Color(red: 0.24, green: 0.16, blue: 0.08).opacity(0.14), radius: 15, y: 10)
    }
}

extension View {
    /// Çizgili defter sayfası zemini (kenar boşluğu çizgisiyle)
    func ruledPage(margin: Bool = true) -> some View {
        background(
            ZStack {
                DS.Colors.paper
                if margin { MarginLine() }
            }
            .ignoresSafeArea()
        )
    }
}

/// Kalemle yazılıyormuş gibi: harfler tek tek belirir, kalemin ucundaki son birkaç harf mürekkep kurur gibi
/// soluktan koyuya geçer. Henüz yazılmamış kısım görünmez ama yer tutar; satırlar yazarken kaymaz.
/// İstenirse fosforlu kalem de yazının peşinden gelir.
struct PenText: View {
    let text: String
    /// false: geçmiş satırlar, bütünüyle hemen görünür
    var animate = true
    var size: CGFloat = 21
    var weight: Font.Weight = .regular
    var italic = false
    var color: Color = DS.Colors.ink
    var rows: Int = 1
    var note: String?
    var noteColor: Color = DS.Colors.accentText
    var highlight: Color?
    /// Saniyede yazılan harf (konuşmadan hızlı: kalem sesi hep yakalar)
    var speed: Double = 45
    /// Kalemin ucunda yanıp sönen çubuk (Lupa konuşurken)
    var caret = false

    @State private var shown = 0
    private let tail = 6

    var body: some View {
        Group {
            if caret {
                TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
                    let on = Int(ctx.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                    RuledText(Text(styled(caretOn: on)), size: size, weight: weight, italic: italic, color: color,
                              rows: rows, note: note, noteColor: noteColor)
                }
            } else {
                RuledText(Text(styled(caretOn: nil)), size: size, weight: weight, italic: italic, color: color,
                          rows: rows, note: note, noteColor: noteColor)
            }
        }
        .task(id: text) { await write() }
        .accessibilityLabel(text)
    }

    /// caretOn: nil = çubuk yok; true/false = yanıp sönen çubuğun o anki hali (yer hep tutulur, satır kaymaz)
    private func styled(caretOn: Bool?) -> AttributedString {
        let chars = Array(text)
        let pen = animate && TutorPrefs.penAnimation ? shown : chars.count + tail       // kalemin vardığı yer (sonda mürekkep kurusun diye taşabilir)
        let n = min(pen, chars.count)                         // yazılmış harf sayısı
        let solid = min(n, max(0, pen - tail))                // mürekkebi kurumuş kısım
        var out = AttributedString()
        var head = AttributedString(String(chars[0..<solid]))
        if let highlight { head.backgroundColor = highlight }
        out += head
        // Kalemin ucu: en yeni harf en soluk, geriye doğru koyulaşır
        for i in solid..<n {
            var c = AttributedString(String(chars[i]))
            let wet = Double(i - (pen - tail)) / Double(tail)  // 0 (kuruyor) … 1 (yeni)
            c.foregroundColor = color.opacity(1 - 0.85 * wet)
            if let highlight { c.backgroundColor = highlight.opacity(1 - wet) }
            out += c
        }
        if let caretOn {
            var bar = AttributedString("▍")
            bar.foregroundColor = caretOn ? DS.Colors.accent : .clear
            out += bar
        }
        if n < chars.count {
            var rest = AttributedString(String(chars[n...]))
            rest.foregroundColor = .clear
            out += rest
        }
        return out
    }

    @MainActor
    private func write() async {
        guard animate, TutorPrefs.penAnimation else { shown = text.count; return }
        let step = UInt64(1_000_000_000 / speed)
        while shown < text.count + tail, !Task.isCancelled {
            shown += 1
            try? await Task.sleep(nanoseconds: step)
        }
    }
}
