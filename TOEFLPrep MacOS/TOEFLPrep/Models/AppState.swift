import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {

    // MARK: - Persisted state

    @Published var progress: [String: WordProgress] = [:]
    @Published var passageProgress: [String: PassageProgress] = [:]
    @Published var dailyStats: [String: DailyStat] = [:]
    @Published var lastActiveDay: String = ""
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var favorites: Set<String> = []

    // MARK: - Settings

    @Published var speakOnReveal: Bool = true
    @Published var dailyReminder: Bool = true
    @Published var theme: AppTheme = .midnight
    @Published var language: AppLanguage = .en

    // MARK: - Recently shown chips on Today
    @Published var recentlyShown: [String] = []

    // MARK: - Session (not persisted)

    @Published var todayWord: VocabWord?
    @Published var todayQuote: Quote?
    @Published var deck: [VocabWord] = []
    @Published var deckIndex: Int = 0
    @Published var quizItems: [QuizItem] = []
    @Published var quizIndex: Int = 0
    @Published var quizScore: Int = 0

    private var bag: [VocabWord] = []
    private let saveURL: URL
    private var quoteTimer: Timer?
    private var isLoading: Bool = false

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        saveURL = dir.appendingPathComponent("toefl-prep-state.json")
        load()
        // Streak is earned by grading a card or completing a quiz — not by
        // just opening the app. So the init path only touches session state.
        refillBagIfNeeded()
        nextTodayWord()
        pickTodayQuote()
        buildDeck()
        startQuoteTimer()
    }

    // MARK: - Persistence

    private struct SaveBlob: Codable {
        var progress: [String: WordProgress]
        var passageProgress: [String: PassageProgress]
        var dailyStats: [String: DailyStat]
        var lastActiveDay: String
        var currentStreak: Int
        var bestStreak: Int
        var favorites: Set<String>
        var speakOnReveal: Bool
        var dailyReminder: Bool
        var theme: AppTheme
        var language: AppLanguage
        var recentlyShown: [String]
    }

    func save() {
        // Never write while load() is still assigning properties — otherwise a
        // @Published assignment could fire an incomplete save that clobbers
        // fields the loader hasn't reached yet.
        guard !isLoading else { return }

        let blob = SaveBlob(
            progress: progress,
            passageProgress: passageProgress,
            dailyStats: dailyStats,
            lastActiveDay: lastActiveDay,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            favorites: favorites,
            speakOnReveal: speakOnReveal,
            dailyReminder: dailyReminder,
            theme: theme,
            language: language,
            recentlyShown: recentlyShown
        )
        do {
            let data = try JSONEncoder().encode(blob)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? Data(contentsOf: saveURL) else { return }
        guard let blob = try? JSONDecoder().decode(SaveBlob.self, from: data) else { return }
        progress = blob.progress
        passageProgress = blob.passageProgress
        dailyStats = blob.dailyStats
        lastActiveDay = blob.lastActiveDay
        currentStreak = blob.currentStreak
        bestStreak = blob.bestStreak
        favorites = blob.favorites
        speakOnReveal = blob.speakOnReveal
        dailyReminder = blob.dailyReminder
        theme = blob.theme
        language = blob.language
        recentlyShown = blob.recentlyShown
    }

    // MARK: - Streak / activity

    static var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Called by every activity that should count toward the daily streak
    /// (grading a flashcard, answering a quiz question, finishing a passage).
    /// Just opening the app does not count — that was the bug that made the
    /// streak "reset" whenever the app was reopened.
    private func registerActivity() {
        let today = Self.todayKey
        if lastActiveDay == today {
            return    // already counted today; nothing changes
        }
        if !lastActiveDay.isEmpty,
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           dayKey(yesterday) == lastActiveDay {
            currentStreak += 1              // consecutive day → extend
        } else {
            currentStreak = 1               // first day, or gap → start fresh
        }
        bestStreak = max(bestStreak, currentStreak)
        lastActiveDay = today
        if dailyStats[today] == nil {
            dailyStats[today] = DailyStat(date: today)
        }
    }

    private func touchToday(_ mutate: (inout DailyStat) -> Void) {
        let key = Self.todayKey
        var stat = dailyStats[key] ?? DailyStat(date: key)
        mutate(&stat)
        dailyStats[key] = stat
    }

    // MARK: - Progress helpers

    func progressFor(_ word: VocabWord) -> WordProgress {
        progress[word.word] ?? WordProgress()
    }

    /// A word is "mastered" once it reaches Leitner box 4 or 5 (matches HTML).
    func isLearned(_ word: VocabWord) -> Bool {
        progressFor(word).box >= 4
    }

    var learnedCount: Int {
        DataStore.vocab.filter { isLearned($0) }.count
    }

    var remainingCount: Int { DataStore.vocab.count - learnedCount }

    func toggleFavorite(_ word: VocabWord) {
        var p = progressFor(word)
        p.fav.toggle()
        progress[word.word] = p
        if p.fav { favorites.insert(word.word) } else { favorites.remove(word.word) }
        save()
    }

    // MARK: - Today word rotation

    private func refillBagIfNeeded() {
        if bag.isEmpty { bag = DataStore.vocab.shuffled() }
    }

    func nextTodayWord() {
        refillBagIfNeeded()
        let word = bag.removeFirst()
        todayWord = word
        // "Recently shown" carries up to eight of the most recent words.
        recentlyShown.removeAll { $0 == word.word }
        recentlyShown.insert(word.word, at: 0)
        if recentlyShown.count > 8 { recentlyShown = Array(recentlyShown.prefix(8)) }
        save()
    }

    func pickTodayQuote() {
        todayQuote = DataStore.quotes.randomElement()
    }

    /// The header quote rotates every 30 seconds to match the HTML behaviour.
    private func startQuoteTimer() {
        quoteTimer?.invalidate()
        quoteTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pickTodayQuote() }
        }
    }

    // MARK: - Flashcard deck (Leitner)

    func buildDeck(limit: Int = 24) {
        let now = Date()
        let due = DataStore.vocab.filter { w in
            let p = progressFor(w)
            return p.seen > 0 && (p.due ?? .distantPast) <= now
        }
        let unseen = DataStore.vocab.filter { progressFor($0).seen == 0 }
        var pool = due.shuffled() + unseen.shuffled()
        if pool.isEmpty { pool = DataStore.vocab.shuffled() }
        deck = Array(pool.prefix(limit))
        deckIndex = 0
    }

    var currentCard: VocabWord? {
        guard deckIndex >= 0, deckIndex < deck.count else { return nil }
        return deck[deckIndex]
    }

    func gradeCurrentCard(_ grade: Grade) {
        guard let word = currentCard else { return }
        var p = progressFor(word)
        p.seen += 1
        if grade != .again { p.correct += 1 }
        switch grade {
        case .again: p.box = 1
        case .hard:  p.box = max(1, p.box - 1)
        case .good:  p.box = min(5, p.box + 1)
        case .easy:  p.box = min(5, p.box + 2)
        }
        let days = reviewIntervalsDays[min(p.box, reviewIntervalsDays.count - 1)]
        p.due = Calendar.current.date(byAdding: .day, value: days, to: Date())
        progress[word.word] = p
        registerActivity()                         // <-- streak advances here
        touchToday { $0.reviewed += 1 }
        save()
        advanceDeck()
    }

    func advanceDeck() {
        if deckIndex + 1 < deck.count { deckIndex += 1 }
        else { buildDeck() }
    }

    // MARK: - Quiz

    func makeQuiz(modes: [QuizMode], length: Int) {
        guard !modes.isEmpty else { quizItems = []; return }
        let pool = DataStore.vocab.shuffled().prefix(length)
        var items: [QuizItem] = []
        for word in pool {
            let mode = modes.randomElement()!
            switch mode {
            case .wordToMeaning:
                let distractors = DataStore.vocab.filter { $0.word != word.word }
                    .shuffled().prefix(3).map(\.meaning)
                let options = (Array(distractors) + [word.meaning]).shuffled()
                let idx = options.firstIndex(of: word.meaning) ?? 0
                items.append(QuizItem(mode: mode, word: word, options: options,
                                      answerIndex: idx, prompt: word.word))
            case .meaningToWord:
                let distractors = DataStore.vocab.filter { $0.word != word.word }
                    .shuffled().prefix(3).map(\.word)
                let options = (Array(distractors) + [word.word]).shuffled()
                let idx = options.firstIndex(of: word.word) ?? 0
                items.append(QuizItem(mode: mode, word: word, options: options,
                                      answerIndex: idx, prompt: word.meaning))
            case .fillBlank:
                let blanked = word.example.replacingOccurrences(
                    of: word.word,
                    with: "_____",
                    options: [.caseInsensitive]
                )
                let distractors = DataStore.vocab.filter { $0.word != word.word }
                    .shuffled().prefix(3).map(\.word)
                let options = (Array(distractors) + [word.word]).shuffled()
                let idx = options.firstIndex(of: word.word) ?? 0
                items.append(QuizItem(mode: mode, word: word, options: options,
                                      answerIndex: idx, prompt: blanked))
            case .pronunciation:
                let distractors = DataStore.vocab.filter { $0.word != word.word }
                    .shuffled().prefix(3).map(\.word)
                let options = (Array(distractors) + [word.word]).shuffled()
                let idx = options.firstIndex(of: word.word) ?? 0
                items.append(QuizItem(mode: mode, word: word, options: options,
                                      answerIndex: idx, prompt: word.ipa))
            case .typing:
                items.append(QuizItem(mode: mode, word: word, options: [],
                                      answerIndex: 0, prompt: word.meaning))
            }
        }
        quizItems = items
        quizIndex = 0
        quizScore = 0
        touchToday { $0.quizzesTaken += 1 }
        save()
    }

    var currentQuizItem: QuizItem? {
        guard quizIndex >= 0, quizIndex < quizItems.count else { return nil }
        return quizItems[quizIndex]
    }

    @discardableResult
    func answerQuiz(correct: Bool) -> Bool {
        if correct { quizScore += 1 }
        touchToday { s in
            s.quizTotal += 1
            if correct { s.quizCorrect += 1 }
        }
        // A wrong answer knocks the word back to box 1, per the HTML.
        if !correct, let item = currentQuizItem {
            var p = progressFor(item.word)
            p.box = 1
            progress[item.word.word] = p
        }
        registerActivity()                         // quiz counts as study
        save()
        return correct
    }

    func advanceQuiz() { quizIndex += 1 }
    func resetQuiz()   { quizItems = []; quizIndex = 0; quizScore = 0 }
    var quizFinished: Bool { !quizItems.isEmpty && quizIndex >= quizItems.count }

    // MARK: - Reading

    func progressFor(_ passage: Passage) -> PassageProgress {
        passageProgress[passage.title] ?? PassageProgress()
    }

    func isPassageDone(_ passage: Passage) -> Bool { progressFor(passage).done }

    func answerPassageQuestion(_ passage: Passage, questionIndex: Int, optionIndex: Int) {
        var p = progressFor(passage)
        p.answers[questionIndex] = optionIndex
        p.correct = p.answers.reduce(0) { total, pair in
            let (qi, oi) = pair
            return total + (passage.questions[qi].answerIndex == oi ? 1 : 0)
        }
        p.done = p.answers.count >= passage.questions.count
        passageProgress[passage.title] = p
        if p.done { registerActivity() }           // finishing a passage counts
        save()
    }

    func updatePassageNotes(_ passage: Passage, notes: String) {
        var p = progressFor(passage)
        p.notes = notes
        passageProgress[passage.title] = p
        save()
    }

    func resetPassage(_ passage: Passage) {
        passageProgress[passage.title] = PassageProgress()
        save()
    }

    // MARK: - Aggregate metrics used by Progress screen

    var totalReviews: Int { dailyStats.values.reduce(0) { $0 + $1.reviewed } }
    var totalQuizCorrect: Int { dailyStats.values.reduce(0) { $0 + $1.quizCorrect } }
    var totalQuizTotal: Int   { dailyStats.values.reduce(0) { $0 + $1.quizTotal } }
    var accuracyPercent: Int {
        totalQuizTotal == 0 ? 0 : Int(round(Double(totalQuizCorrect) / Double(totalQuizTotal) * 100))
    }
    var studyMinutes: Int {
        dailyStats.values.reduce(0) { $0 + $1.studySeconds } / 60
    }
    var reviewsThisWeek: Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        return dailyStats.filter { entry in
            guard let d = date(fromKey: entry.key) else { return false }
            return d >= start
        }.reduce(0) { $0 + $1.value.reviewed }
    }
    var reviewsThisMonth: Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -29, to: Date()) ?? Date()
        return dailyStats.filter { entry in
            guard let d = date(fromKey: entry.key) else { return false }
            return d >= start
        }.reduce(0) { $0 + $1.value.reviewed }
    }

    /// The current calendar week's review counts, one entry per weekday.
    /// Used by the Progress screen's Daily Reviews chart. The week's start
    /// respects the user's Calendar (`firstWeekday`) so US users see Sun→Sat
    /// and most other locales see Mon→Sun.
    var weekReviews: [(day: String, count: Int)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEEE"           // one-letter weekday (S M T W T F S)
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        var result: [(String, Int)] = []
        for offset in 0..<7 {
            guard let d = cal.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let key = dayKey(d)
            let count = dailyStats[key]?.reviewed ?? 0
            result.append((fmt.string(from: d), count))
        }
        return result
    }

    private func date(fromKey key: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }

    /// How many words are currently sitting in each Leitner box.
    var leitnerDistribution: [Int] {
        var counts = [0, 0, 0, 0, 0]           // boxes 1...5
        for word in DataStore.vocab {
            let box = min(max(progressFor(word).box, 1), 5)
            counts[box - 1] += 1
        }
        return counts
    }

    // MARK: - Reset

    func resetProgress() {
        progress = [:]
        passageProgress = [:]
        dailyStats = [:]
        currentStreak = 0
        bestStreak = 0
        favorites = []
        recentlyShown = []
        buildDeck()
        save()
    }

    // MARK: - Import / export

    /// Exports the whole state (progress + favorites + streak) as JSON.
    func exportStateJSON() -> Data? {
        try? JSONEncoder().encode(SaveBlob(
            progress: progress,
            passageProgress: passageProgress,
            dailyStats: dailyStats,
            lastActiveDay: lastActiveDay,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            favorites: favorites,
            speakOnReveal: speakOnReveal,
            dailyReminder: dailyReminder,
            theme: theme,
            language: language,
            recentlyShown: recentlyShown
        ))
    }

    /// Exports the vocabulary as CSV (word, pos, ipa, meaning, ...).
    func exportVocabCSV() -> String {
        var out = "word,pos,ipa,meaning,example,syn,ant,diff,cat,sec,tip\n"
        for w in DataStore.vocab {
            let cells = [w.word, w.pos, w.ipa, w.meaning, w.example, w.syn, w.ant,
                         "\(w.diff)", w.cat, w.sec, w.tip].map(csvEscape)
            out.append(cells.joined(separator: ","))
            out.append("\n")
        }
        return out
    }

    /// Exports reading passages as JSON.
    func exportPassagesJSON() -> Data? {
        try? JSONEncoder().encode(DataStore.passages)
    }

    private func csvEscape(_ s: String) -> String {
        let needsQuote = s.contains(",") || s.contains("\"") || s.contains("\n")
        let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuote ? "\"\(escaped)\"" : escaped
    }

    /// Import: called when the user drops a file on the settings dropzone.
    /// Returns a short human-readable summary of what happened.
    func importFile(url: URL) -> String {
        guard let data = try? Data(contentsOf: url) else { return "Could not read file." }
        let name = url.pathExtension.lowercased()
        if name == "json" {
            if let blob = try? JSONDecoder().decode(SaveBlob.self, from: data) {
                progress = blob.progress
                passageProgress = blob.passageProgress
                dailyStats = blob.dailyStats
                lastActiveDay = blob.lastActiveDay
                currentStreak = blob.currentStreak
                bestStreak = blob.bestStreak
                favorites = blob.favorites
                save()
                return "Progress restored."
            }
            if (try? JSONDecoder().decode([Passage].self, from: data)) != nil {
                return "Passage import recognised (bundled data cannot be replaced at runtime)."
            }
        }
        return "Unrecognised file — expected JSON progress export."
    }
}
