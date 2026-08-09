import Foundation

/// Loads the bundled word list, quotes and reading passages once at launch.
/// The three JSON files (vocab.json, quotes.json, passages.json) must be
/// added to the app target as bundle resources.
enum DataStore {
    static let vocab: [VocabWord] = load("vocab.json")
    static let quotes: [Quote] = load("quotes.json")
    static let passages: [Passage] = load("passages.json")

    static let categories: [String] = {
        Array(Set(vocab.map(\.cat))).sorted()
    }()

    static let passageCategories: [String] = {
        Array(Set(passages.map(\.cat))).sorted()
    }()

    private static func load<T: Decodable>(_ filename: String) -> [T] {
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            assertionFailure("Missing bundled resource \(filename). In Xcode, select the file in the navigator and check the target's box in the File Inspector.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            assertionFailure("Failed to decode \(filename): \(error)")
            return []
        }
    }
}
