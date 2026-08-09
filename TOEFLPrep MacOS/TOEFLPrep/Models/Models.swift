import Foundation

// MARK: - Vocabulary

struct VocabWord: Codable, Identifiable, Hashable {
    var word: String
    var pos: String
    var ipa: String
    var meaning: String
    var example: String
    var syn: String
    var ant: String
    var diff: Int
    var cat: String
    var sec: String
    var tip: String
    var tier: String

    var id: String { word }
}

// MARK: - Quotes

struct Quote: Codable, Identifiable, Hashable {
    var text: String
    var author: String

    var id: String { text }
}

// MARK: - Reading passages

struct PassageQuestion: Codable, Hashable {
    var question: String
    var options: [String]
    var answerIndex: Int
    var explanation: String
}

struct Passage: Codable, Identifiable, Hashable {
    var title: String
    var cat: String
    var diff: Int
    var text: String
    var questions: [PassageQuestion]

    var id: String { title }
}

// MARK: - Per-word progress (spaced repetition)

struct WordProgress: Codable, Hashable {
    var box: Int = 1          // 1...5 to match the HTML (Box 1 is the start)
    var due: Date? = nil
    var seen: Int = 0
    var correct: Int = 0
    var fav: Bool = false
}

// MARK: - Passage progress

struct PassageProgress: Codable, Hashable {
    var answers: [Int: Int] = [:]
    var correct: Int = 0
    var done: Bool = false
    var notes: String = ""
}

// MARK: - Daily stats

struct DailyStat: Codable, Hashable {
    var date: String
    var reviewed: Int = 0
    var quizzesTaken: Int = 0
    var quizCorrect: Int = 0
    var quizTotal: Int = 0
    var studySeconds: Int = 0
}

// MARK: - Grading (flashcards)

enum Grade: Int, CaseIterable {
    case again = 0, hard, good, easy

    var label: String {
        switch self {
        case .again: return "Again"
        case .hard:  return "Hard"
        case .good:  return "Good"
        case .easy:  return "Easy"
        }
    }

    /// Subtitle shown under the label — matches the flashcard screenshot.
    var subtitle: String {
        switch self {
        case .again: return "box 1"
        case .hard:  return "box -1"
        case .good:  return "box +1"
        case .easy:  return "box +2"
        }
    }
}

// Interval ramp in days per Leitner box level, mirroring the web app's INTERVALS.
let reviewIntervalsDays: [Int] = [0, 1, 2, 4, 8, 16]

// MARK: - Quiz

enum QuizMode: String, CaseIterable, Identifiable, Codable {
    case wordToMeaning = "word_to_meaning"
    case meaningToWord = "meaning_to_word"
    case fillBlank     = "fill_blank"
    case pronunciation = "pronunciation"
    case typing        = "typing"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wordToMeaning: return "Word → meaning"
        case .meaningToWord: return "Meaning → word"
        case .fillBlank:     return "Fill in the blank"
        case .pronunciation: return "Pronunciation recognition"
        case .typing:        return "Typing mode"
        }
    }
}

struct QuizItem: Identifiable {
    let id = UUID()
    var mode: QuizMode
    var word: VocabWord
    var options: [String]   // empty for .typing
    var answerIndex: Int
    var prompt: String
}
