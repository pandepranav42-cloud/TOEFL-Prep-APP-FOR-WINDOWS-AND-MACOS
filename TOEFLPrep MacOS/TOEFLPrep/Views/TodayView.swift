import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var app: AppState

    private var dateEyebrow: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date()).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(
                    eyebrow: dateEyebrow,
                    title: L10n.t("Word of the moment", app.language),
                    subtitle: "A word from your list, chosen fresh each time. It changes every 30 seconds.",
                    theme: app.theme
                )

                if let quote = app.todayQuote {
                    QuoteCard(quote: quote, theme: app.theme) { app.pickTodayQuote() }
                }

                HStack(alignment: .top, spacing: 18) {
                    if let word = app.todayWord {
                        HeroWordCard(word: word)
                            .frame(maxWidth: .infinity)
                    }
                    ProgressRingCard()
                        .frame(width: 320)
                }

                RecentlyShownSection()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
        }
        .background(Color.clear)
    }
}

// MARK: - Quote card

private struct QuoteCard: View {
    let quote: Quote
    let theme: AppTheme
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text("\u{201C}")
                    .font(AppFont.display(48, weight: .regular))
                    .foregroundStyle(theme.ink3)
                    .offset(y: -4)
                Text(quote.text)
                    .font(AppFont.display(22, weight: .regular))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            HStack {
                Text("— \(quote.author.uppercased())")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(theme.ink3)
                Spacer()
                Button(action: onNext) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.ink2)
                        .padding(8)
                        .glass(theme, .chip, radius: 999)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .glass(theme, .card, radius: 18)
    }
}

// MARK: - Hero word card (big word, meaning, buttons)

private struct HeroWordCard: View {
    @EnvironmentObject private var app: AppState
    let word: VocabWord

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(word.word)
                    .font(AppFont.display(52, weight: .regular))
                    .foregroundStyle(app.theme.ink)
                Button {
                    Speech.say(word.word)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(app.theme.ink2)
                        .padding(8)
                        .glass(app.theme, .chip, radius: 999)
                }
                .buttonStyle(.plain)
                Spacer()
            }

            HStack(spacing: 12) {
                metaChip(word.pos)
                metaSeparator
                metaChip(word.cat)
                metaSeparator
                metaChip("\(word.sec) section")
            }

            Text(word.meaning)
                .font(.system(size: 15))
                .foregroundStyle(app.theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if !word.syn.isEmpty || !word.ant.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Rectangle().fill(app.theme.ink3.opacity(0.4))
                        .frame(width: 2, height: 20)
                    (Text("Synonyms: ").italic().foregroundColor(app.theme.ink2)
                        + Text(word.syn).italic().foregroundColor(app.theme.ink)
                        + Text("  ·  ").foregroundColor(app.theme.ink3)
                        + Text("Antonyms: ").italic().foregroundColor(app.theme.ink2)
                        + Text(word.ant).italic().foregroundColor(app.theme.ink))
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                PrimaryButton(title: L10n.t("Continue learning", app.language), theme: app.theme) {
                    // Nothing to navigate to from here; the sidebar handles that.
                }
                SecondaryButton(title: L10n.t("Quick quiz", app.language), theme: app.theme) {}
                SecondaryButton(title: L10n.t("Next word", app.language), theme: app.theme) {
                    app.nextTodayWord()
                }
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(28)
        .glass(app.theme, .panel, radius: 20)
    }

    private func metaChip(_ text: String) -> some View {
        Text(text)
            .font(AppFont.mono(11, weight: .regular))
            .foregroundStyle(app.theme.ink3)
    }
    private var metaSeparator: some View {
        Circle().fill(app.theme.ink3.opacity(0.6)).frame(width: 3, height: 3)
    }
}

// MARK: - Progress ring (right side of Today)

private struct ProgressRingCard: View {
    @EnvironmentObject private var app: AppState

    private var masteredFraction: Double {
        let total = DataStore.vocab.count
        return total == 0 ? 0 : Double(app.learnedCount) / Double(total)
    }

    private var masteredPercent: Int {
        Int((masteredFraction * 100).rounded())
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(app.theme.ink3.opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: masteredFraction)
                    .stroke(app.theme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 3) {
                    Text("\(masteredPercent)%")
                        .font(AppFont.mono(28, weight: .semibold))
                        .foregroundStyle(app.theme.ink)
                    Text("MASTERED")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(app.theme.ink3)
                }
            }
            .frame(width: 150, height: 150)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                miniStat(value: "\(app.learnedCount)", label: "LEARNED")
                miniStat(value: "\(app.remainingCount)", label: "REMAINING")
                miniStat(value: "\(app.currentStreak)", label: "STREAK")
                miniStat(value: "\(app.accuracyPercent)%", label: "ACCURACY")
            }
        }
        .padding(22)
        .glass(app.theme, .panel, radius: 20)
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.mono(17, weight: .semibold))
                .foregroundStyle(app.theme.ink)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(app.theme.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glass(app.theme, .card, radius: 13)
    }
}

// MARK: - Recently shown row

private struct RecentlyShownSection: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        if !app.recentlyShown.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text("RECENTLY SHOWN")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.6)
                        .foregroundStyle(app.theme.ink3)
                    Rectangle().fill(app.theme.hairlineSoft).frame(height: 1)
                }
                HStack(spacing: 10) {
                    ForEach(app.recentlyShown, id: \.self) { name in
                        Text(name)
                            .font(AppFont.display(15, weight: .regular))
                            .foregroundStyle(app.theme.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .glass(app.theme, .card, radius: 12)
                            .onTapGesture {
                                if let match = DataStore.vocab.first(where: { $0.word == name }) {
                                    app.todayWord = match
                                }
                            }
                    }
                }
            }
            .padding(.top, 6)
        }
    }
}
