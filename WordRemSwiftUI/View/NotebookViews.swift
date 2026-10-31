//
//  NotebookViews.swift
//  WordRemSwiftUI
//
//  Defterlerim: raftaki defterler. Her dilin bir sohbet defteri var: her sesli sohbet bir sayfa,
//  sayfalar gerçek kâğıt gibi kıvrılarak çevrilir. Sayfadaki kelimeye dokununca fosforlu kalemle
//  işaretlenir, anlamı bulunur ve kelime tekrar listesine düşer (Lupa sonraki sohbetlerde kullandırır).
//  Defterin son sayfası kelime dizini. Kullanıcının kelime desteleri de rafta küçük defterler.
//

import SwiftUI
import UIKit
import NaturalLanguage
#if canImport(Translation)
import Translation
#endif

// MARK: - Metinler (sıra: tr, en, de, fr, es, it, ru, zh)
enum NoteText {
    static var title: String { PageText.t(["Defterlerim", "My notebooks", "Meine Hefte", "Mes carnets", "Mis cuadernos", "I miei quaderni", "Мои тетради", "我的笔记本"]) }
    static var talkNotebooks: String { PageText.t(["SOHBET DEFTERLERİN", "YOUR CONVERSATION NOTEBOOKS", "DEINE GESPRÄCHSHEFTE", "TES CARNETS DE CONVERSATION", "TUS CUADERNOS DE CONVERSACIÓN", "I TUOI QUADERNI DI CONVERSAZIONE", "ТЕТРАДИ РАЗГОВОРОВ", "对话笔记本"]) }
    static var wordNotebooks: String { PageText.t(["KELİME DEFTERLERİN", "YOUR WORD NOTEBOOKS", "DEINE WORTHEFTE", "TES CARNETS DE MOTS", "TUS CUADERNOS DE PALABRAS", "I TUOI QUADERNI DI PAROLE", "ТЕТРАДИ СЛОВ", "单词笔记本"]) }
    static var notebook: String { PageText.t(["defteri", "notebook", "Heft", "carnet", "cuaderno", "quaderno", "тетрадь", "笔记本"]) }
    static func pages(_ n: Int) -> String { PageText.t(["\(n) sayfa", "\(n) pages", "\(n) Seiten", "\(n) pages", "\(n) páginas", "\(n) pagine", "\(n) стр.", "\(n) 页"]) }
    static func words(_ n: Int) -> String { PageText.t(["\(n) kelime", "\(n) words", "\(n) Wörter", "\(n) mots", "\(n) palabras", "\(n) parole", "\(n) слов", "\(n) 个词"]) }
    static var newNotebook: String { PageText.t(["Yeni defter", "New notebook", "Neues Heft", "Nouveau carnet", "Cuaderno nuevo", "Nuovo quaderno", "Новая тетрадь", "新笔记本"]) }
    static var tapToMark: String { PageText.t(["Kelimeye dokun: işaretle ve kaydet", "Tap a word to mark and save it", "Tippe ein Wort an: markieren und speichern", "Touche un mot pour le surligner et l'enregistrer", "Toca una palabra para marcarla y guardarla", "Tocca una parola per evidenziarla e salvarla", "Нажми на слово, чтобы отметить и сохранить", "点按单词即可标记并保存"]) }
    static var emptyPage: String { PageText.t(["Bu defter henüz boş. Lupa ile her sohbetin buraya bir sayfa olarak yazılacak.", "This notebook is still empty. Every chat with Lupa becomes a page here.", "Dieses Heft ist noch leer. Jedes Gespräch mit Lupa wird hier zu einer Seite.", "Ce carnet est encore vide. Chaque conversation avec Lupa deviendra une page ici.", "Este cuaderno aún está vacío. Cada charla con Lupa será una página aquí.", "Questo quaderno è ancora vuoto. Ogni chiacchierata con Lupa diventerà una pagina qui.", "Тетрадь пока пуста. Каждый разговор с Лупой станет здесь страницей.", "这本笔记本还是空的。你和 Lupa 的每次对话都会成为这里的一页。"]) }
    static var index: String { PageText.t(["Kelime dizini", "Word index", "Wortregister", "Index des mots", "Índice de palabras", "Indice delle parole", "Словарик", "单词索引"]) }
    static func fromPages(_ n: Int) -> String { PageText.t(["\(n) sayfadan", "from \(n) pages", "aus \(n) Seiten", "sur \(n) pages", "de \(n) páginas", "da \(n) pagine", "из \(n) стр.", "来自 \(n) 页"]) }
    static var indexTip: String { PageText.t(["Kelimeye dokun, sesini dinle · sayfa numarasına dokun, o sayfaya git", "Tap a word to hear it · tap a page number to jump there", "Tippe ein Wort an, um es zu hören · tippe eine Seitenzahl an, um hinzuspringen", "Touche un mot pour l'écouter · touche un numéro de page pour y aller", "Toca una palabra para oírla · toca un número de página para ir allí", "Tocca una parola per ascoltarla · tocca un numero di pagina per andarci", "Нажми на слово, чтобы послушать · нажми на номер страницы, чтобы перейти", "点按单词收听 · 点按页码跳转到该页"]) }
    static var indexEmpty: String { PageText.t(["Sayfalarda işaretlediğin kelimeler burada toplanır.", "Words you mark on the pages gather here.", "Wörter, die du markierst, sammeln sich hier.", "Les mots que tu surlignes se rassemblent ici.", "Las palabras que marcas se reúnen aquí.", "Le parole che evidenzi si raccolgono qui.", "Отмеченные слова собираются здесь.", "你标记的单词会汇集在这里。"]) }
    static var savedToReview: String { PageText.t(["tekrar listene eklendi", "added to your reviews", "zu deinen Wiederholungen", "ajouté à tes révisions", "añadida a tus repasos", "aggiunta ai ripassi", "добавлено в повторение", "已加入复习"]) }
    static var marked: String { PageText.t(["işaretlendi", "marked", "markiert", "surligné", "marcada", "evidenziata", "отмечено", "已标记"]) }
    static var turnPage: String { PageText.t(["Sayfayı çevir", "Turn the page", "Umblättern", "Tourne la page", "Pasa la página", "Gira pagina", "Переверни страницу", "翻页"]) }
    static var owner: String { PageText.t(["Ad", "Name", "Name", "Nom", "Nombre", "Nome", "Имя", "姓名"]) }
    static var newEyebrow: String { PageText.t(["YENİ DEFTER", "NEW NOTEBOOK", "NEUES HEFT", "NOUVEAU CARNET", "CUADERNO NUEVO", "NUOVO QUADERNO", "НОВАЯ ТЕТРАДЬ", "新笔记本"]) }
    static var createTitle: String { PageText.t(["Kelimelerin için yeni bir defter", "A new notebook for your words", "Ein neues Heft für deine Wörter", "Un nouveau carnet pour tes mots", "Un cuaderno nuevo para tus palabras", "Un nuovo quaderno per le tue parole", "Новая тетрадь для твоих слов", "为你的单词准备一本新笔记本"]) }
    static var createSub: String { PageText.t(["Kapağını seç, adını etikete yaz, bir çıkartma yapıştır.", "Pick a cover, write its name on the label, add a sticker.", "Wähle einen Umschlag, schreib den Namen aufs Etikett, kleb einen Sticker drauf.", "Choisis une couverture, écris son nom sur l'étiquette, colle un autocollant.", "Elige una tapa, escribe su nombre en la etiqueta y pega una pegatina.", "Scegli una copertina, scrivi il nome sull'etichetta, attacca un adesivo.", "Выбери обложку, подпиши этикетку, наклей наклейку.", "选封面、在标签上写名字、贴一张贴纸。"]) }
    static var cover: String { PageText.t(["KAPAK", "COVER", "UMSCHLAG", "COUVERTURE", "TAPA", "COPERTINA", "ОБЛОЖКА", "封面"]) }
    static var sticker: String { PageText.t(["ÇIKARTMA", "STICKER", "STICKER", "AUTOCOLLANT", "PEGATINA", "ADESIVO", "НАКЛЕЙКА", "贴纸"]) }
    static var languages: String { PageText.t(["HANGİ DİLDEN HANGİ DİLE", "FROM WHICH LANGUAGE TO WHICH", "VON WELCHER SPRACHE IN WELCHE", "DE QUELLE LANGUE À QUELLE LANGUE", "DE QUÉ IDIOMA A CUÁL", "DA QUALE LINGUA A QUALE", "С КАКОГО ЯЗЫКА НА КАКОЙ", "从哪种语言到哪种语言"]) }
    static var nameField: String { PageText.t(["Defterin adı", "Notebook name", "Name des Hefts", "Nom du carnet", "Nombre del cuaderno", "Nome del quaderno", "Название тетради", "笔记本名称"]) }
    static var namePlaceholder: String { PageText.t(["Örn. Mutfak kelimeleri", "e.g. Kitchen words", "z. B. Küchenwörter", "ex. Mots de cuisine", "p. ej. Palabras de cocina", "es. Parole di cucina", "напр. Кухонные слова", "例如：厨房词汇"]) }
    static var create: String { PageText.t(["Defteri oluştur", "Create notebook", "Heft anlegen", "Créer le carnet", "Crear cuaderno", "Crea quaderno", "Создать тетрадь", "创建笔记本"]) }
    static var delete: String { PageText.t(["Sil", "Delete", "Löschen", "Supprimer", "Eliminar", "Elimina", "Удалить", "删除"]) }
}

// MARK: - Raf

/// Kelimeler sekmesinin "Defterlerim" bölümü: sohbet defterleri (dil başına) ve kelime desteleri
struct NotebookShelfView: View {
    @ObservedObject var homeVM: HomeScreenViewModel
    @Binding var showCreateDeck: Bool
    @ObservedObject private var store = NotebookStore.shared
    @State private var openLanguage: String?

    private var languages: [String] {
        var seen = Set<String>()
        let current = LearningLanguages.current
        return ([current] + LearningLanguages.added + store.pages.map(\.language)).filter { seen.insert($0).inserted }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: NoteText.talkNotebooks, color: DS.Colors.accentText)
                        .padding(.top, 18)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 18) {
                            ForEach(languages, id: \.self) { code in
                                Button { openLanguage = code } label: { languageCover(code) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 2)
                    }

                    Eyebrow(text: NoteText.wordNotebooks, color: DS.Colors.accentText)
                        .padding(.top, 22)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 16, alignment: .top)], spacing: 22) {
                        Button { showCreateDeck = true } label: { newDeckCover }
                            .buttonStyle(.plain)
                        ForEach(Array(homeVM.cardNames.indices), id: \.self) { i in
                            NavigationLink {
                                CardDetailView(viewModel: CardDetailViewModel(), cardName: homeVM.cardNames[i], cardId: homeVM.cardIds[i])
                            } label: {
                                deckCover(i)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { withAnimation { homeVM.deleteCard(at: i) } } label: {
                                    Label(NoteText.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.top, 14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DS.Colors.paperRaised.ignoresSafeArea())
            .navigationBarHidden(true)
            .task {
                await homeVM.fetchCardName()
                #if DEBUG
                if DemoData.stage == "notebook" { openLanguage = LearningLanguages.current }
                #endif
            }
            .onReceive(NotificationCenter.default.publisher(for: .pathMistakesDeckCreated)) { _ in
                Task { await homeVM.fetchCardName() }
            }
        }
        .fullScreenCover(item: Binding(get: { openLanguage.map(LanguageBox.init) }, set: { openLanguage = $0?.code })) { box in
            NotebookReaderView(language: box.code)
        }
    }

    private func languageName(_ code: String) -> String {
        OL.languageName(for: code).capitalized(with: Locale(identifier: OL.nativeLangCode))
    }

    /// Büyük sohbet defteri kapağı: dil, sayfa ve kelime sayısı, üstten sarkan ayraç
    private func languageCover(_ code: String) -> some View {
        let pages = store.pages(for: code).count
        let words = store.marks(for: code).count
        let isCurrent = code == LearningLanguages.current
        return ZStack(alignment: .topTrailing) {
            NotebookCover(color: isCurrent ? DS.Colors.slate : DS.Colors.ink)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 5, bottomTrailingRadius: 14, topTrailingRadius: 14))
            BookmarkMark(width: 8, colors: [DS.Colors.ink, DS.Colors.accent, DS.Colors.paper, DS.Colors.margin])
                .padding(.trailing, 14)
            VStack(alignment: .leading, spacing: 4) {
                Text(languageName(code))
                    .font(DS.Font.display(19, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(NoteText.notebook)
                    .font(.system(size: 13, design: .serif).italic())
                    .foregroundStyle(DS.Colors.muted)
                Rectangle().fill(DS.Colors.line).frame(height: 1).padding(.vertical, 4)
                Text("\(NoteText.pages(pages)) · \(NoteText.words(words))")
                    .font(DS.Font.ui(11, weight: .medium))
                    .foregroundStyle(DS.Colors.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.paper, in: RoundedRectangle(cornerRadius: 6))
            .rotationEffect(.degrees(-1))
            .padding(.leading, 26)
            .padding(.trailing, 14)
            .frame(maxHeight: .infinity)
        }
        .frame(width: 168, height: 220)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 2, y: 8)
        .accessibilityElement(children: .combine)
    }

    private func deckCover(_ i: Int) -> some View {
        let title = homeVM.cardNames[i]
        let count = i < homeVM.cardWordCounts.count ? homeVM.cardWordCounts[i] : 0
        return VStack(alignment: .leading, spacing: 8) {
            ZStack {
                NotebookCover(color: CardView.coverColor(for: title))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 4, bottomTrailingRadius: 10, topTrailingRadius: 10))
                let flag = i < homeVM.selectedFlag.count ? homeVM.selectedFlag[i] : ""
                if !flag.isEmpty, UIImage(named: flag) != nil {
                    Image(flag).resizable().scaledToFill()
                        .frame(width: 34, height: 34).clipShape(Circle())
                        .overlay(Circle().stroke(DS.Colors.paperRaised, lineWidth: 3))
                        .padding(.leading, 12)
                }
            }
            .frame(height: 124)
            .shadow(color: .black.opacity(0.14), radius: 6, x: 1, y: 5)
            Text(title)
                .font(DS.Font.display(15, weight: .semibold))
                .foregroundStyle(DS.Colors.ink)
                .lineLimit(2)
            Text(NoteText.words(count))
                .font(DS.Font.ui(12))
                .foregroundStyle(DS.Colors.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private var newDeckCover: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(Color(hex: "#B8B0A4"))
                .frame(height: 124)
                .overlay(Image(systemName: "plus").font(.system(size: 22, weight: .medium)).foregroundStyle(DS.Colors.inkSoft))
            Text(NoteText.newNotebook)
                .font(DS.Font.display(15, weight: .semibold))
                .foregroundStyle(DS.Colors.inkSoft)
        }
    }
}

private struct LanguageBox: Identifiable {
    let code: String
    var id: String { code }
}

// MARK: - Defteri okuma: sayfa sayfa çevir

struct NotebookReaderView: View {
    let language: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = NotebookStore.shared
    @State private var index: Int
    @State private var toast: String?
    /// Bu açılışta işaretlenen, anlamı beklenen kelimeler: anlamı gelince tekrar listesine eklenir
    @State private var fresh: Set<String> = []

    init(language: String) {
        self.language = language
        // Defter en son yazılan sayfada açılır; açılırken kendi kendine sayfa çevrilmez
        let written = NotebookStore.shared.pages(for: language).count
        _index = State(initialValue: written)
    }

    private var pages: [NotebookPage] { store.pages(for: language) }
    /// 0: kapak, 1…n: sohbetler (boşsa bir boş sayfa), son: kelime dizini
    private var count: Int { max(pages.count, 1) + 2 }
    /// Anlamı henüz bulunmamış işaretli kelimeler
    private var unglossed: [String] {
        store.marks(for: language).filter { store.gloss($0, language: language) == nil }
    }

    var body: some View {
        ZStack(alignment: .top) {
            DS.Colors.backdrop.ignoresSafeArea()
            PageCurlReader(count: count, index: $index) { i in
                AnyView(page(i))
            }
            .padding(.top, 52)
            .ignoresSafeArea(edges: .bottom)

            // Sağ üst köşede kıvrık sayfa kulağı: hafifçe nefes alır. Dokunuşları altındaki sayfaya bırakır:
            // köşeden tutup sürükleyince sayfa parmağın altında kıvrılarak çevrilir, dokununca da çevrilir.
            if index < count - 1 {
                DogEar()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 52)
                    .transition(.opacity)
            }

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.ink)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(AL.s(.talkEnd))
                Spacer()
                Text(index == 0 ? "" : index == count - 1 ? NoteText.index : PageText.page(index))
                    .font(.system(size: 15, design: .serif).italic())
                    .foregroundStyle(DS.Colors.inkSoft)
                Spacer()
                Button { withAnimation { index = count - 1 } } label: {
                    Image(systemName: "character.book.closed")
                        .font(.system(size: 17))
                        .foregroundStyle(DS.Colors.ink)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(NoteText.index)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            if let toast {
                Text(toast)
                    .font(DS.Font.ui(14, weight: .medium))
                    .foregroundStyle(DS.Colors.paperRaised)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(DS.Colors.ink, in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .modifier(GlossFiller(language: language, words: unglossed) { key, gloss in
            if let gloss { store.setGloss(gloss, for: key, language: language) }
            guard fresh.remove(key) != nil else { return }
            if let gloss { learn(gloss) } else { showToast("“\(key)” \(NoteText.marked)") }
        })
    }

    /// Sayfada bir kelime işaretlendi: anlamı biliniyorsa hemen, değilse bulununca tekrar listesine düşer
    private func marked(_ key: String) {
        if let gloss = store.gloss(key, language: language) { learn(gloss) } else { fresh.insert(key) }
    }

    private func learn(_ g: NotebookGloss) {
        let lw = LearnedWord(id: "note|\(language)|\(NotebookStore.key(g.headword))", term: g.headword, meaning: g.meaning,
                             phonetic: nil, languageCode: language.uppercased(), learnedAt: Date())
        LearnedWordsStore.add([lw], nativeLangCode: OL.nativeLangCode)
        ReviewScheduler.shared.reload()
        showToast((g.fromNative ? "“\(g.meaning)” → \(g.headword)" : "“\(g.headword)” · \(g.meaning)") + " — \(NoteText.savedToReview)")
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.35)) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation { if toast == message { toast = nil } }
        }
    }

    @ViewBuilder
    private func page(_ i: Int) -> some View {
        if i == 0 {
            NotebookCoverPage(language: language, pageCount: pages.count)
        } else if i == count - 1 {
            NotebookIndexPage(language: language) { n in index = n }
        } else if pages.isEmpty {
            NotebookBlankPage()
        } else {
            NotebookPageView(pageId: pages[i - 1].id, number: i, onMark: marked)
        }
    }
}

/// Sayfanın sağ üst köşesi hafifçe kıvrılmış: altındaki zemin görünür, kıvrılan kulak gölge düşürür.
/// Kulak yavaşça açılıp kapanır, sayfanın çevrilebildiği anlaşılır.
private struct DogEar: View {
    @State private var open = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let size: CGFloat = open ? 40 : 28
        ZStack(alignment: .topTrailing) {
            // Kıvrılınca açığa çıkan köşe: sayfanın arkasındaki zemin
            CornerTriangle(flap: false)
                .fill(DS.Colors.backdrop)
                .frame(width: size, height: size)
            // Kıvrılan kulak: kâğıdın arka yüzü, köşeden içe doğru koyulaşır
            CornerTriangle(flap: true)
                .fill(LinearGradient(colors: [DS.Colors.paperSunken, Color(hex: "#D9D0C1")],
                                     startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.22), radius: 3, x: -2, y: 3)
        }
        .frame(width: 56, height: 56, alignment: .topTrailing)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { open = true }
        }
    }

    /// flap: kıvrılan kulak (sol üst, sağ alt, sol alt); değilse kesilen köşe (sol üst, sağ üst, sağ alt)
    private struct CornerTriangle: Shape {
        let flap: Bool
        func path(in r: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            if flap {
                p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
                p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            } else {
                p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
                p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            }
            p.closeSubpath()
            return p
        }
    }
}

/// UIPageViewController'ın kâğıt kıvrılması: defter sayfası gerçekten çevrilir
struct PageCurlReader: UIViewControllerRepresentable {
    let count: Int
    @Binding var index: Int
    /// Sayfanın arka zemini (çevrilen yaprağın rengi)
    var pageColor: Color = DS.Colors.paperRaised
    /// false: yalnızca sürükleyerek çevrilir, kenara dokunmak sayfa çevirmez
    var tapToTurn = true
    let page: (Int) -> AnyView

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal,
                                       options: [.spineLocation: NSNumber(value: UIPageViewController.SpineLocation.min.rawValue)])
        pvc.isDoubleSided = false
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        pvc.view.backgroundColor = .clear
        pvc.setViewControllers([context.coordinator.controller(min(index, count - 1))], direction: .forward, animated: false)
        context.coordinator.shown = index
        if !tapToTurn {
            pvc.gestureRecognizers.filter { $0 is UITapGestureRecognizer }.forEach { $0.isEnabled = false }
        }
        // Kıvırma hareketi sayfadaki kaydırmayla çakışmasın: yana çekince ya da sağ üst köşeden tutunca sayfa çevrilir,
        // yukarı-aşağı çekince sayfa kayar. Çakışınca UIPageViewController yarım kalıp bir daha çevirmiyordu.
        // Dokunma da buradan geçer: son sayfada ileri, kapakta geri çevirme ve çevrilirken yeni çevirme engellenir
        // (yoksa UIPageViewController olmayan sayfayı isteyip çöküyor).
        context.coordinator.pvc = pvc
        for g in pvc.gestureRecognizers {
            context.coordinator.original = g.delegate
            g.delegate = context.coordinator
        }
        // Kâğıt kıvrılması bir tık yavaş: gerçek bir sayfa gibi
        pvc.view.layer.speed = 0.78
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        let c = context.coordinator
        c.parent = self
        // Görünen yaprak güncel kalsın (üst görünümdeki veriler değişince)
        if let hc = pvc.viewControllers?.first as? UIHostingController<AnyView> {
            hc.rootView = page(hc.view.tag)
        }
        let target = min(max(index, 0), count - 1)
        if target != c.shown {
            let dir: UIPageViewController.NavigationDirection = target > c.shown ? .forward : .reverse
            c.shown = target
            let vc = c.controller(target)
            // Animasyonlu geçişten sonra yaprak bir kez daha animasyonsuz yerleştirilir: yoksa UIPageViewController
            // komşu sayfaları eski yerden hatırlar ve sonraki çevirmede aynı sayfayı tekrar gösterir
            c.turning(true)
            pvc.setViewControllers([vc], direction: dir, animated: true) { [weak pvc, weak c] done in
                DispatchQueue.main.async {
                    if done { pvc?.setViewControllers([vc], direction: dir, animated: false) }
                    c?.turning(false)
                }
            }
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate {
        var parent: PageCurlReader
        var shown = 0
        /// Kıvırma hareketinin asıl yöneticisi (UIPageViewController): bizim karar vermediğimiz her şey ona gider
        weak var original: UIGestureRecognizerDelegate?
        weak var pvc: UIPageViewController?
        /// Bir yaprak çevriliyor: bitene kadar yeni çevirme başlamaz
        private var isTurning = false
        private var turnStarted = Date.distantPast
        init(_ parent: PageCurlReader) { self.parent = parent }

        func turning(_ on: Bool) {
            isTurning = on
            if on { turnStarted = Date() }
        }

        func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
            guard let v = g.view else { return original?.gestureRecognizerShouldBegin?(g) ?? true }
            // Takılı kalırsa (geçiş bildirimi gelmezse) 2 sn sonra yeniden izin verilir
            if isTurning, Date().timeIntervalSince(turnStarted) < 2 { return false }
            let current = pvc?.viewControllers?.first?.view.tag ?? shown
            let p = g.location(in: v)
            let rightHalf = p.x > v.bounds.width / 2
            var forward = rightHalf
            if let pan = g as? UIPanGestureRecognizer {
                let t = pan.translation(in: v)
                let corner = p.x > v.bounds.width - 120 && p.y < 140
                let sideways = abs(t.x) > abs(t.y) * 1.15
                guard corner || sideways else { return false }
                if t.x != 0 { forward = t.x < 0 || rightHalf }
            }
            // Olmayan sayfaya çevirme yok: sonda ileri, başta geri
            if current >= parent.count - 1, forward || rightHalf { return false }
            if current <= 0, !forward || !rightHalf { return false }
            return original?.gestureRecognizerShouldBegin?(g) ?? true
        }

        /// Sayfadaki kaydırma, kıvırmanın başlamayacağı anlaşılana kadar bekler: ikisi aynı anda başlamaz
        func gestureRecognizer(_ g: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            if g is UIPanGestureRecognizer, other is UIPanGestureRecognizer, other.view is UIScrollView { return true }
            return original?.gestureRecognizer?(g, shouldBeRequiredToFailBy: other) ?? false
        }

        override func responds(to aSelector: Selector!) -> Bool {
            super.responds(to: aSelector) || (original?.responds(to: aSelector) ?? false)
        }

        override func forwardingTarget(for aSelector: Selector!) -> Any? {
            if let original, original.responds(to: aSelector) { return original }
            return super.forwardingTarget(for: aSelector)
        }

        func controller(_ i: Int) -> UIViewController {
            let hc = UIHostingController(rootView: parent.page(i))
            hc.view.tag = i
            hc.view.backgroundColor = UIColor(parent.pageColor)
            return hc
        }

        func pageViewController(_ pvc: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
            let i = vc.view.tag
            return i > 0 ? controller(i - 1) : nil
        }

        func pageViewController(_ pvc: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
            let i = vc.view.tag
            return i < parent.count - 1 ? controller(i + 1) : nil
        }

        func pageViewController(_ pvc: UIPageViewController, willTransitionTo pending: [UIViewController]) {
            turning(true)
        }

        func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            turning(false)
            guard completed, let i = pvc.viewControllers?.first?.view.tag else { return }
            shown = i
            Haptics.tap()
            DispatchQueue.main.async { self.parent.index = i }
        }
    }
}

// MARK: - Sayfalar

/// Kapak: dil, sahibinin adı, sayfa sayısı
private struct NotebookCoverPage: View {
    let language: String
    let pageCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NotebookCover(color: language == LearningLanguages.current ? DS.Colors.slate : DS.Colors.ink)
            BookmarkMark(width: 16, colors: [DS.Colors.ink, DS.Colors.accent, DS.Colors.paper, DS.Colors.margin])
                .padding(.trailing, 36)
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    WordRemLogoText(size: 26)
                    Text(OL.languageName(for: language).capitalized(with: Locale(identifier: OL.nativeLangCode)) + " " + NoteText.notebook)
                        .font(DS.Font.display(28, weight: .bold))
                        .foregroundStyle(DS.Colors.ink)
                        .padding(.top, 14)
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(NoteText.owner).font(DS.Font.ui(13)).foregroundStyle(DS.Colors.muted)
                        Text(UserStore.shared.snapshot.username)
                            .font(DS.Font.display(22, weight: .semibold))
                            .foregroundStyle(DS.Colors.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(alignment: .bottom) { Rectangle().fill(Color(hex: "#B8B0A4")).frame(height: 1).offset(y: 4) }
                    }
                    .padding(.top, 18)
                    Text(NoteText.pages(pageCount))
                        .font(.system(size: 14, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                        .padding(.top, 14)
                }
                .padding(22)
                .background(DS.Colors.paper, in: RoundedRectangle(cornerRadius: 8))
                .rotationEffect(.degrees(-1))
                .shadow(color: .black.opacity(0.22), radius: 14, y: 10)
                .padding(.leading, 48)
                .padding(.trailing, 28)
                Spacer()
                HStack(spacing: 6) {
                    Text(NoteText.turnPage)
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 15, design: .serif).italic())
                .foregroundStyle(Color(hex: "#E5ECEF"))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 28)
                .padding(.bottom, 48)
            }
        }
    }
}

/// Boş defter: yazı da sayfadaki her şey gibi satırlara oturur (çizgiler ve metin aynı 32 pt ızgarada)
private struct NotebookBlankPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: DS.Page.pitch * 2)
            RuledText(NoteText.emptyPage, size: 19, italic: true, color: DS.Colors.muted)
            Spacer(minLength: 0)
        }
        .padding(.leading, DS.Page.textX)
        .padding(.trailing, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(alignment: .top) { RuledLines() }
        .background { MarginLine() }
        .background(DS.Colors.paperRaised)
    }
}

/// Bir sohbetin sayfası: tarih, başlık, satırlar; her kelimeye dokunulabilir
private struct NotebookPageView: View {
    let pageId: UUID
    let number: Int
    var onMark: (String) -> Void
    @ObservedObject private var store = NotebookStore.shared

    var body: some View {
        if let page = store.page(pageId) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(page.date.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute().locale(Locale(identifier: OL.nativeLangCode))))
                                .font(.system(size: 14, design: .serif).italic())
                                .foregroundStyle(DS.Colors.muted)
                            Eyebrow(text: page.kicker, color: DS.Colors.accentText).lineLimit(1)
                            Text(page.title)
                                .font(DS.Font.display(24, weight: .bold))
                                .foregroundStyle(DS.Colors.ink)
                        }
                        Spacer(minLength: 8)
                        if page.done {
                            InkStamp(top: page.date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: OL.nativeLangCode))).uppercased(),
                                     title: "✓", bottom: "WORDREM", size: 64)
                        }
                    }
                    .padding(.top, 22)
                    .padding(.bottom, 18)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(page.lines.enumerated()), id: \.offset) { _, line in
                            lineView(line, page: page)
                        }
                    }
                    .background(alignment: .top) { RuledLines().padding(.leading, -DS.Page.textX).padding(.trailing, -24) }

                    Text("— \(number) —")
                        .font(.system(size: 14, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                    Text(NoteText.tapToMark)
                        .font(DS.Font.ui(12))
                        .foregroundStyle(DS.Colors.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                        .padding(.bottom, 40)
                }
                .padding(.leading, DS.Page.textX)
                .padding(.trailing, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background { MarginLine() }
            .background(DS.Colors.paperRaised)
        }
    }

    @ViewBuilder
    private func lineView(_ line: NotebookPage.Line, page: NotebookPage) -> some View {
        switch line.role {
        case .ai:
            words(line.text, page: page, size: 19, color: DS.Colors.ink, note: "Lupa", noteColor: DS.Colors.accentText)
        case .user:
            words(line.text, page: page, size: 18, color: DS.Colors.slate, note: AL.s(.talkYouLabel), noteColor: DS.Colors.slate)
        case .card:
            VStack(alignment: .leading, spacing: 0) {
                words(line.text, page: page, size: 20, weight: .semibold, color: DS.Colors.ink, card: true)
                if let tr = line.detail, !tr.isEmpty {
                    RuledText(tr, size: 15, italic: true, color: DS.Colors.muted)
                }
            }
        }
    }

    private func words(_ text: String, page: NotebookPage, size: CGFloat, weight: Font.Weight = .regular,
                       color: Color, card: Bool = false, note: String? = nil, noteColor: Color = DS.Colors.accentText) -> some View {
        let tokens = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        return WordFlow(rowHeight: DS.Page.pitch) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                let marked = page.marks.contains(NotebookStore.key(token))
                Text(token)
                    .font(.system(size: size, weight: weight, design: .serif))
                    .foregroundStyle(color)
                    .padding(.horizontal, 2)
                    .background(marked ? DS.Colors.highlight : card ? DS.Colors.highlight.opacity(0.45) : .clear)
                    .contentShape(Rectangle())
                    .onTapGesture { tap(token, page: page) }
                    .accessibilityAddTraits(.isButton)
            }
        }
        .overlay(alignment: .topLeading) {
            if let note {
                Text(note)
                    .font(.system(size: 13, design: .serif).italic())
                    .foregroundStyle(noteColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: DS.Page.marginX - 18, alignment: .trailing)
                    // Kenar notunun tabanı da satırın tabanıyla aynı çizgide
                    .offset(x: -(DS.Page.textX - 6), y: DS.Page.pitch - 5 - RuledText.serif(13).ascender)
            }
        }
    }

    private func tap(_ token: String, page: NotebookPage) {
        let word = NotebookStore.key(token)
        guard !word.isEmpty else { return }
        let nowMarked = store.toggleMark(token, in: page.id)
        Haptics.tap()
        if nowMarked { onMark(word) }
    }
}

/// Kelime dizini: defterde işaretlenen kelimeler, gerçek bir kitabın arkasındaki dizin gibi.
/// Harf başlıkları kenar boşluğunda; her madde öğrenilen dildeki kelime, ana dildeki karşılığı,
/// geçtiği cümle ve sayfa numarası. Ana dilde işaretlenen kelime ("kitap") öğrenilen dildeki karşılığıyla ("book") girer.
private struct NotebookIndexPage: View {
    let language: String
    var onOpenPage: (Int) -> Void
    @ObservedObject private var store = NotebookStore.shared

    private struct Entry: Identifiable {
        let key: String
        let headword: String
        let meaning: String?
        let page: Int?
        let context: String?
        var id: String { key }
    }

    var body: some View {
        let pages = store.pages(for: language)
        let entries = entries(pages)
        let groups = Dictionary(grouping: entries) { Self.letter($0.headword) }
            .sorted { $0.key.compare($1.key, locale: Locale(identifier: language)) == .orderedAscending }
        let pageCount = Set(entries.compactMap(\.page)).count

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(NoteText.index)
                    .font(DS.Font.display(30, weight: .bold))
                    .foregroundStyle(DS.Colors.ink)
                    .padding(.top, 24)
                if !entries.isEmpty {
                    Text(NoteText.words(entries.count) + " · " + NoteText.fromPages(pageCount))
                        .font(.system(size: 15, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                        .padding(.top, 4)
                }
                Rectangle().fill(DS.Colors.rule).frame(height: 1).padding(.top, 16).padding(.bottom, 4)

                if entries.isEmpty {
                    Text(NoteText.indexEmpty)
                        .font(.system(size: 17, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                        .padding(.top, 12)
                }
                ForEach(groups, id: \.key) { letter, items in
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { entryRow($0) }
                    }
                    .overlay(alignment: .topLeading) {
                        // Harf başlığı kenar boşluğunda, ilk maddenin hizasında
                        Text(letter)
                            .font(DS.Font.display(30, weight: .bold))
                            .foregroundStyle(DS.Colors.accentText)
                            .frame(width: DS.Page.marginX - 8, alignment: .center)
                            .offset(x: -DS.Page.textX, y: 12)
                    }
                    .padding(.top, 10)
                }
                if !entries.isEmpty {
                    Text(NoteText.indexTip)
                        .font(DS.Font.ui(12))
                        .foregroundStyle(DS.Colors.muted)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)
                }
            }
            .padding(.leading, DS.Page.textX)
            .padding(.trailing, 24)
            .padding(.bottom, 48)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { MarginLine() }
        .background(DS.Colors.paperRaised)
    }

    private func entryRow(_ e: Entry) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                highlightedText(e.headword)
                    .font(DS.Font.display(19, weight: .semibold))
                    .foregroundStyle(DS.Colors.ink)
                    .layoutPriority(1)
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Colors.accentText)
                DottedLeader()
                    .frame(height: 8)
                    .frame(minWidth: 16)
                if let meaning = e.meaning {
                    Text(meaning)
                        .font(.system(size: 16, design: .serif).italic())
                        .foregroundStyle(DS.Colors.inkSoft)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .layoutPriority(1)
                } else {
                    // Anlamı bulunuyor
                    Text("···")
                        .font(.system(size: 16, design: .serif).italic())
                        .foregroundStyle(DS.Colors.muted)
                        .phaseAnimator([0.3, 1]) { v, o in v.opacity(o) } animation: { _ in .easeInOut(duration: 0.7) }
                }
            }
            if e.context != nil || e.page != nil {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if let context = e.context {
                        Self.snippet(context, around: e.key)
                            .font(.system(size: 13, design: .serif).italic())
                            .foregroundStyle(DS.Colors.muted)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    if let page = e.page {
                        Button { onOpenPage(page) } label: {
                            Text(PageText.page(page))
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundStyle(DS.Colors.accentText)
                                .padding(.vertical, 6).padding(.leading, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(DS.Colors.rule.opacity(0.7)).frame(height: 1) }
        .contentShape(Rectangle())
        .onTapGesture { TutorVoice.shared.speak(e.headword, langCode: language.uppercased()) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func entries(_ pages: [NotebookPage]) -> [Entry] {
        store.marks(for: language).map { key in
            let gloss = store.gloss(key, language: language)
            // Kelimenin ilk geçtiği sayfa ve satır
            var page: Int?
            var context: String?
            for (n, p) in pages.enumerated() where p.marks.contains(key) {
                if let line = p.lines.first(where: { l in l.text.split(separator: " ").contains { NotebookStore.key(String($0)) == key } }) {
                    page = n + 1
                    context = line.text
                    break
                }
            }
            return Entry(key: key, headword: gloss?.headword ?? key, meaning: gloss?.meaning, page: page, context: context)
        }
        .sorted { $0.headword.compare($1.headword, options: [.caseInsensitive, .diacriticInsensitive],
                                      locale: Locale(identifier: language)) == .orderedAscending }
    }

    private static func letter(_ word: String) -> String {
        guard let first = word.folding(options: [.diacriticInsensitive], locale: nil).first, first.isLetter else { return "#" }
        return String(first).uppercased()
    }

    /// Kelimenin geçtiği cümleden kısa bir parça, kelime koyu: "…I love reading books…"
    private static func snippet(_ line: String, around key: String) -> Text {
        let tokens = line.split(separator: " ").map(String.init)
        guard let i = tokens.firstIndex(where: { NotebookStore.key($0) == key }) else { return Text("“\(line)”") }
        let before = tokens[max(0, i - 3)..<i].joined(separator: " ")
        let after = tokens[(i + 1)..<min(tokens.count, i + 4)].joined(separator: " ")
        let lead = i > 3 ? "“…" : "“"
        let tail = i + 4 < tokens.count ? "…”" : "”"
        return Text(lead + (before.isEmpty ? "" : before + " "))
            + Text(tokens[i]).bold().foregroundColor(DS.Colors.inkSoft)
            + Text((after.isEmpty ? "" : " " + after) + tail)
    }
}

/// Kelimeleri soldan sağa dizer, satır yüksekliği sabit: her satır defter çizgisine oturur
private struct WordFlow: Layout {
    var rowHeight: CGFloat
    var spacing: CGFloat = 3

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let rows = arrange(width: width, subviews: subviews).rows
        return CGSize(width: width, height: CGFloat(max(rows, 1)) * rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placed = arrange(width: bounds.width, subviews: subviews).frames
        for (i, f) in placed.enumerated() {
            // Kelimenin altı satır çizgisinin hemen üstüne oturur
            subviews[i].place(at: CGPoint(x: bounds.minX + f.minX, y: bounds.minY + f.minY), proposal: ProposedViewSize(f.size))
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (frames: [CGRect], rows: Int) {
        var frames: [CGRect] = []
        var x: CGFloat = 0, row = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width { row += 1; x = 0 }
            // Yazının tabanı çizginin 4 pt üstünde: ders sayfasındaki RuledText ile birebir aynı
            let baseline = s.dimensions(in: .unspecified)[VerticalAlignment.lastTextBaseline]
            let y = CGFloat(row) * rowHeight + rowHeight - 5 - baseline
            frames.append(CGRect(x: x, y: y, width: min(size.width, width), height: size.height))
            x += size.width + spacing
        }
        return (frames, subviews.isEmpty ? 0 : row + 1)
    }
}

/// İşaretli kelimelerin karşılıklarını bulur (iOS 18: cihaz içi Apple Çeviri).
/// Öğrenilen dildeki kelime ana dile çevrilir; ana dildeki kelime ("kitap") öğrenilen dile çevrilip dizine
/// o karşılıkla ("book") girer. Dil tahmini şaşarsa (çeviri kelimeyi aynen döndürürse) öbür yön denenir.
/// Bulunamayan kelime için onResult(kelime, nil) gelir.
private struct GlossFiller: ViewModifier {
    let language: String
    let words: [String]
    var onResult: (String, NotebookGloss?) -> Void

    func body(content: Content) -> some View {
        #if canImport(Translation)
        if #available(iOS 18.0, *) {
            content.modifier(ModernGlossFiller(language: language, words: words, onResult: onResult))
        } else {
            content.onChange(of: words) { new in new.forEach { onResult($0, nil) } }
        }
        #else
        content.onChange(of: words) { new in new.forEach { onResult($0, nil) } }
        #endif
    }
}

enum NotebookLexicon {
    static func nlLanguage(_ code: String) -> NLLanguage {
        code.lowercased().hasPrefix("zh") ? .simplifiedChinese : NLLanguage(code.lowercased())
    }

    /// Tek kelimede iki dil arasında karar: ana dile mi benziyor?
    static func looksNative(_ word: String, native: String, target: String) -> Bool {
        let r = NLLanguageRecognizer()
        r.languageConstraints = [nlLanguage(native), nlLanguage(target)]
        r.processString(word)
        let h = r.languageHypotheses(withMaximum: 2)
        return (h[nlLanguage(native)] ?? 0) > (h[nlLanguage(target)] ?? 0)
    }

    /// Çeviri cümle başı gibi büyük harfle dönerse küçültülür (Almancada adlar büyük kalır)
    static func tidy(_ s: String, language: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".!?。！")))
        guard language.lowercased() != "de", let first = t.first, first.isUppercase,
              t.dropFirst().allSatisfy({ !$0.isUppercase }) else { return t }
        return first.lowercased() + t.dropFirst()
    }
}

#if canImport(Translation)
@available(iOS 18.0, *)
private struct ModernGlossFiller: ViewModifier {
    let language: String
    let words: [String]
    var onResult: (String, NotebookGloss?) -> Void

    @State private var toNative: TranslationSession.Configuration?
    @State private var fromNative: TranslationSession.Configuration?
    @State private var toNativeQueue: [String] = []
    @State private var fromNativeQueue: [String] = []
    /// Bu açılışta denenen yönler: aynı kelime bir yönde iki kez sorulmaz
    @State private var triedToNative: Set<String> = []
    @State private var triedFromNative: Set<String> = []

    private var native: String { OL.nativeLangCode.lowercased() }

    private static func lang(_ code: String) -> Locale.Language {
        Locale.Language(identifier: code.lowercased().hasPrefix("zh") ? "zh-Hans" : code.lowercased())
    }

    func body(content: Content) -> some View {
        content
            .onAppear { enqueue(words) }
            .onChange(of: words) { enqueue($0) }
            .translationTask(toNative) { session in
                let batch = toNativeQueue
                guard !batch.isEmpty else { return }
                let out = await translate(batch, with: session)
                var retry: [String] = []
                for w in batch {
                    guard let t = out[w] else { onResult(w, nil); continue }
                    if NotebookStore.key(t) == w {
                        // Kelime aynen döndü: muhtemelen ana dilde yazılmış
                        if triedFromNative.contains(w) { onResult(w, nil) } else { retry.append(w) }
                    } else {
                        onResult(w, NotebookGloss(headword: w, meaning: NotebookLexicon.tidy(t, language: native), fromNative: false))
                    }
                }
                toNativeQueue.removeAll { batch.contains($0) }
                if !retry.isEmpty { push(retry, toNative: false) }
            }
            .translationTask(fromNative) { session in
                let batch = fromNativeQueue
                guard !batch.isEmpty else { return }
                let out = await translate(batch, with: session)
                var retry: [String] = []
                for w in batch {
                    guard let t = out[w] else { onResult(w, nil); continue }
                    if NotebookStore.key(t) == w {
                        if triedToNative.contains(w) { onResult(w, nil) } else { retry.append(w) }
                    } else {
                        onResult(w, NotebookGloss(headword: NotebookLexicon.tidy(t, language: language), meaning: w, fromNative: true))
                    }
                }
                fromNativeQueue.removeAll { batch.contains($0) }
                if !retry.isEmpty { push(retry, toNative: true) }
            }
    }

    private func enqueue(_ list: [String]) {
        let new = list.filter { !triedToNative.contains($0) && !triedFromNative.contains($0) }
        guard !new.isEmpty else { return }
        let nativeWords = new.filter { NotebookLexicon.looksNative($0, native: native, target: language) }
        push(new.filter { !nativeWords.contains($0) }, toNative: true)
        push(nativeWords, toNative: false)
    }

    private func push(_ list: [String], toNative direction: Bool) {
        guard !list.isEmpty else { return }
        if direction {
            triedToNative.formUnion(list)
            toNativeQueue.append(contentsOf: list)
            if toNative == nil {
                toNative = .init(source: Self.lang(language), target: Self.lang(native))
            } else {
                toNative?.invalidate()
            }
        } else {
            triedFromNative.formUnion(list)
            fromNativeQueue.append(contentsOf: list)
            if fromNative == nil {
                fromNative = .init(source: Self.lang(native), target: Self.lang(language))
            } else {
                fromNative?.invalidate()
            }
        }
    }

    /// Toplu çeviri: kelime → karşılık (başarısızsa boş)
    private func translate(_ words: [String], with session: TranslationSession) async -> [String: String] {
        let requests = words.map { TranslationSession.Request(sourceText: $0, clientIdentifier: $0) }
        guard let responses = try? await session.translations(from: requests) else { return [:] }
        var out: [String: String] = [:]
        for r in responses {
            if let id = r.clientIdentifier, !r.targetText.isEmpty { out[id] = r.targetText }
        }
        return out
    }
}
#endif
