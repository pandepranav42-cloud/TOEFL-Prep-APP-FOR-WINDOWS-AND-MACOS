import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var app: AppState

    @State private var query: String = ""
    @State private var difficultyFilter: Int = 0
    @State private var statusFilter: Status = .all
    @State private var categoryFilter: String = "All"
    @State private var selected: VocabWord? = nil

    enum Status: String, CaseIterable {
        case all = "All"
        case learned = "Learned"
        case notLearned = "Not learned"
        case favorites = "★ Favorites"
    }

    private var filtered: [VocabWord] {
        DataStore.vocab.filter { w in
            (difficultyFilter == 0 || w.diff == difficultyFilter) &&
            (query.isEmpty
                || w.word.localizedCaseInsensitiveContains(query)
                || w.meaning.localizedCaseInsensitiveContains(query)
                || w.syn.localizedCaseInsensitiveContains(query)) &&
            (categoryFilter == "All" || w.cat == categoryFilter) &&
            statusMatches(w)
        }
    }

    private func statusMatches(_ w: VocabWord) -> Bool {
        switch statusFilter {
        case .all: return true
        case .learned: return app.isLearned(w)
        case .notLearned: return !app.isLearned(w)
        case .favorites: return app.progressFor(w).fav
        }
    }

    var body: some View {
        if let w = selected {
            LibraryDetail(word: w) { selected = nil }
        } else {
            grid
        }
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "\(DataStore.vocab.count) words · \(app.learnedCount) mastered · \(filtered.count) shown",
                    title: L10n.t("Library", app.language),
                    theme: app.theme
                )

                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(app.theme.ink3)
                    TextField("Search word, meaning, or synonym", text: $query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundStyle(app.theme.ink)
                }
                .padding(14)
                .glass(app.theme, .input, radius: 14)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Chip("Any level", selected: difficultyFilter == 0, theme: app.theme) { difficultyFilter = 0 }
                        ForEach(1...5, id: \.self) { d in
                            Chip(String(repeating: "★", count: d),
                                 selected: difficultyFilter == d,
                                 theme: app.theme) { difficultyFilter = d }
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(Status.allCases, id: \.self) { s in
                            Chip(s.rawValue, selected: statusFilter == s, theme: app.theme) {
                                statusFilter = s
                            }
                        }
                        Menu {
                            Button("All") { categoryFilter = "All" }
                            Divider()
                            ForEach(DataStore.categories, id: \.self) { c in
                                Button(c) { categoryFilter = c }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(categoryFilter)
                                Image(systemName: "chevron.down").font(.system(size: 9))
                            }
                            .font(AppFont.mono(11, weight: .medium))
                            .foregroundStyle(app.theme.ink)
                            .padding(.horizontal, 11).padding(.vertical, 6)
                            .glass(app.theme, .chip, radius: 999)
                        }
                        .buttonStyle(.plain)
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)],
                          spacing: 12) {
                    ForEach(filtered) { word in
                        WordCard(word: word) { selected = word }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
        }
    }
}

// MARK: - Word card

private struct WordCard: View {
    @EnvironmentObject private var app: AppState
    let word: VocabWord
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 0) {
                DifficultyAccentBar(diff: word.diff, theme: app.theme)
                    .padding(.trailing, 12)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(word.word)
                            .font(AppFont.display(19, weight: .regular))
                            .foregroundStyle(app.theme.ink)
                        Text(word.pos)
                            .font(.system(size: 12))
                            .italic()
                            .foregroundStyle(app.theme.ink3)
                        Spacer(minLength: 0)
                    }
                    Text(word.meaning)
                        .font(.system(size: 12.5))
                        .foregroundStyle(app.theme.ink2)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        DifficultyDots(diff: word.diff, theme: app.theme)
                        Spacer()
                        BoxChip(box: app.progressFor(word).box, theme: app.theme)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(app.theme, .card, radius: 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library detail

private struct LibraryDetail: View {
    @EnvironmentObject private var app: AppState
    let word: VocabWord
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Button {
                    onBack()
                } label: {
                    Label("All words", systemImage: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(app.theme.ink2)
                }
                .buttonStyle(.plain)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(word.word)
                        .font(AppFont.display(46, weight: .regular))
                        .foregroundStyle(app.theme.ink)
                    Button { Speech.say(word.word) } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(app.theme.ink2)
                            .padding(8)
                            .glass(app.theme, .chip, radius: 999)
                    }
                    .buttonStyle(.plain)
                    Button { app.toggleFavorite(word) } label: {
                        let filled = app.progressFor(word).fav
                        Image(systemName: filled ? app.theme.favoriteFilled : app.theme.favoriteOutline)
                            .font(.system(size: 12))
                            .foregroundStyle(filled ? app.theme.accent : app.theme.ink2)
                            .padding(8)
                            .glass(app.theme, .chip, radius: 999)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    DifficultyDots(diff: word.diff, theme: app.theme).scaleEffect(1.5)
                }

                Text("\(word.ipa)  ·  \(word.pos)  ·  \(word.cat)")
                    .font(AppFont.mono(12))
                    .foregroundStyle(app.theme.ink3)

                detailBlock("MEANING", word.meaning, strong: true)
                if !word.example.isEmpty { detailBlock("EXAMPLE", word.example) }
                if !word.syn.isEmpty     { detailBlock("SYNONYMS", word.syn) }
                if !word.ant.isEmpty     { detailBlock("ANTONYMS", word.ant) }
                if !word.tip.isEmpty     { detailBlock("MEMORY TRICK", word.tip) }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
        }
    }

    private func detailBlock(_ label: String, _ text: String, strong: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium)).tracking(1.4)
                .foregroundStyle(app.theme.ink3)
            Text(text)
                .font(.system(size: strong ? 16 : 13, weight: strong ? .semibold : .regular))
                .foregroundStyle(strong ? app.theme.ink : app.theme.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(app.theme, .card, radius: 13)
    }
}
