import SwiftUI

struct CardsView: View {
    @EnvironmentObject private var app: AppState
    @State private var flipped = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let word = app.currentCard {
                    header(for: word)
                    progressBar
                    Card(word: word, flipped: $flipped)
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
                    grading
                    footer(for: word)
                } else {
                    EmptyStatePlaceholder(
                        title: "All caught up",
                        systemImage: "checkmark.circle",
                        message: "No cards are due right now. Build a fresh deck?",
                        theme: app.theme
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
        }
    }

    private func header(for word: VocabWord) -> some View {
        let box = app.progressFor(word).box
        return ScreenHeader(
            eyebrow: "Leitner box \(box) of 5 · card \(app.deckIndex + 1) of \(app.deck.count)",
            title: L10n.t("Flashcards", app.language),
            subtitle: "Recall the meaning first, then flip. Grade yourself honestly — the box you land in decides how soon the word comes back.",
            theme: app.theme
        )
    }

    private var progressBar: some View {
        let total = max(app.deck.count, 1)
        let ratio = Double(app.deckIndex + 1) / Double(total)
        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(app.theme.surface).frame(height: 3)
                Capsule()
                    .fill(LinearGradient(colors: [app.theme.accentAlt, app.theme.accent],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * ratio, height: 3)
            }
        }
        .frame(height: 3)
    }

    private var grading: some View {
        HStack(spacing: 12) {
            ForEach(Grade.allCases, id: \.rawValue) { grade in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        flipped = false
                    }
                    app.gradeCurrentCard(grade)
                } label: {
                    VStack(spacing: 4) {
                        Text(grade.label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(app.theme.ink)
                        Text(grade.subtitle)
                            .font(AppFont.mono(10))
                            .foregroundStyle(app.theme.ink3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glass(app.theme, .card, radius: 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func footer(for word: VocabWord) -> some View {
        HStack(spacing: 14) {
            Spacer()
            Button {
                Speech.say(word.word)
            } label: {
                Label("Hear it", systemImage: "speaker.wave.2")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(app.theme.ink2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glass(app.theme, .chip, radius: 11)
            }
            .buttonStyle(.plain)

            Button {
                app.toggleFavorite(word)
            } label: {
                let filled = app.progressFor(word).fav
                Label(
                    "Favorite",
                    systemImage: filled ? app.theme.favoriteFilled : app.theme.favoriteOutline
                )
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(filled ? app.theme.accent : app.theme.ink2)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glass(app.theme, .chip, radius: 11)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Card face

private struct Card: View {
    @EnvironmentObject private var app: AppState
    let word: VocabWord
    @Binding var flipped: Bool

    var body: some View {
        ZStack {
            if flipped { back } else { front }
        }
        .glass(app.theme, .panel, radius: 22)
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .onTapGesture {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                flipped.toggle()
            }
        }
    }

    private var front: some View {
        VStack {
            Spacer()
            Text(word.word)
                .font(AppFont.display(56, weight: .regular))
                .foregroundStyle(app.theme.ink)
            DifficultyDots(diff: word.diff, theme: app.theme)
                .padding(.top, 14)
                .scaleEffect(1.4)
            Text("CLICK TO REVEAL")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.8)
                .foregroundStyle(app.theme.ink3)
                .padding(.top, 22)
            Spacer()
            HStack {
                Spacer()
                Text("PRANAV PANDE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(app.theme.ink3.opacity(0.6))
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var back: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.word)
                        .font(AppFont.display(30, weight: .regular))
                        .foregroundStyle(app.theme.ink)
                    Text(word.ipa)
                        .font(AppFont.mono(12))
                        .foregroundStyle(app.theme.ink3)
                    Text("· \(word.pos)")
                        .font(.system(size: 12))
                        .italic()
                        .foregroundStyle(app.theme.ink3)
                }
                block("MEANING", word.meaning, strong: true)
                if !word.example.isEmpty { block("EXAMPLE", word.example) }
                if !word.syn.isEmpty     { block("SYNONYMS", word.syn) }
                if !word.ant.isEmpty     { block("ANTONYMS", word.ant) }
                if !word.tip.isEmpty     { block("MEMORY TRICK", word.tip) }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func block(_ label: String, _ text: String, strong: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(app.theme.ink3)
            Text(text)
                .font(.system(size: strong ? 15 : 13, weight: strong ? .semibold : .regular))
                .foregroundStyle(strong ? app.theme.ink : app.theme.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
