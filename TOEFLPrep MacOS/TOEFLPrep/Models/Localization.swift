import Foundation

/// The five interface languages the settings screen offers. Vocabulary itself
/// stays English — this only affects UI chrome.
enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case en, hi, ko, zh, ja
    var id: String { rawValue }

    var label: String {
        switch self {
        case .en: return "English"
        case .hi: return "हिन्दी"
        case .ko: return "한국어"
        case .zh: return "中文"
        case .ja: return "日本語"
        }
    }
}

/// A tiny key/value bag. Falls back to the English string when a translation
/// is missing so a partly-translated language never renders a raw key.
enum L10n {
    static func t(_ key: String, _ lang: AppLanguage) -> String {
        table[lang]?[key] ?? english[key] ?? key
    }

    private static let english: [String: String] = [
        "Today": "Today",
        "Flashcards": "Flashcards",
        "Quiz": "Quiz",
        "Reading": "Reading",
        "Library": "Library",
        "Progress": "Progress",
        "Settings": "Settings",
        "Study": "Study",
        "Setup": "Setup",
        "day streak": "day streak",
        "Word of the moment": "Word of the moment",
        "Continue learning": "Continue learning",
        "Quick quiz": "Quick quiz",
        "Next word": "Next word",
        "Mastered": "Mastered",
        "Learned": "Learned",
        "Remaining": "Remaining",
        "Streak": "Streak",
        "Accuracy": "Accuracy",
        "Recently shown": "Recently shown",
        "Language": "Language",
        "App colour": "App colour",
        "Special": "Special",
        "Import and export": "Import and export",
        "Notifications": "Notifications",
        "Daily study reminder": "Daily study reminder"
    ]

    private static let table: [AppLanguage: [String: String]] = [
        .hi: [
            "Today": "आज",
            "Flashcards": "फ़्लैशकार्ड",
            "Quiz": "प्रश्नोत्तरी",
            "Reading": "पठन",
            "Library": "पुस्तकालय",
            "Progress": "प्रगति",
            "Settings": "सेटिंग्स",
            "Study": "अध्ययन",
            "Setup": "सेटअप",
            "day streak": "दिन की श्रृंखला",
            "Word of the moment": "पल का शब्द",
            "Continue learning": "सीखना जारी रखें",
            "Quick quiz": "त्वरित परीक्षा",
            "Next word": "अगला शब्द",
            "Language": "भाषा",
            "App colour": "ऐप रंग",
            "Special": "विशेष"
        ],
        .ko: [
            "Today": "오늘",
            "Flashcards": "플래시카드",
            "Quiz": "퀴즈",
            "Reading": "독해",
            "Library": "단어장",
            "Progress": "진행 상황",
            "Settings": "설정",
            "Study": "학습",
            "Setup": "설정",
            "day streak": "일 연속",
            "Word of the moment": "지금의 단어",
            "Continue learning": "학습 계속하기",
            "Quick quiz": "빠른 퀴즈",
            "Next word": "다음 단어",
            "Language": "언어",
            "App colour": "앱 색상",
            "Special": "특별"
        ],
        .zh: [
            "Today": "今天",
            "Flashcards": "抽认卡",
            "Quiz": "测验",
            "Reading": "阅读",
            "Library": "词库",
            "Progress": "进度",
            "Settings": "设置",
            "Study": "学习",
            "Setup": "设置",
            "day streak": "天连续",
            "Word of the moment": "此刻的单词",
            "Continue learning": "继续学习",
            "Quick quiz": "快速测验",
            "Next word": "下一个单词",
            "Language": "语言",
            "App colour": "应用颜色",
            "Special": "特别"
        ],
        .ja: [
            "Today": "今日",
            "Flashcards": "フラッシュカード",
            "Quiz": "クイズ",
            "Reading": "リーディング",
            "Library": "ライブラリ",
            "Progress": "進捗",
            "Settings": "設定",
            "Study": "学習",
            "Setup": "セットアップ",
            "day streak": "日連続",
            "Word of the moment": "今の単語",
            "Continue learning": "学習を続ける",
            "Quick quiz": "クイックテスト",
            "Next word": "次の単語",
            "Language": "言語",
            "App colour": "アプリの色",
            "Special": "特別"
        ]
    ]
}
