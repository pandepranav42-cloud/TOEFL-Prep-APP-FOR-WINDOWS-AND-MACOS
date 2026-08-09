import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var app: AppState

    @State private var selectedModes: Set<QuizMode> = [.wordToMeaning, .meaningToWord]
    @State private var length: Int = 10
    @State private var chosenIndex: Int? = nil
    @State private var typingText: String = ""
    @State private var showResult: Bool = false
    @State private var wasCorrect: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if app.quizItems.isEmpty {
                    setup
                } else if app.quizFinished {
                    result
                } else if let item = app.currentQuizItem {
                    question(item)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
        }
    }

    // MARK: - Setup

    private var setup: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeader(
                eyebrow: "\(DataStore.vocab.count) words available",
                title: L10n.t("Quiz", app.language),
                subtitle: "Pick the question types you want. Wrong answers drop that word back to Leitner box 1, so it returns sooner in flashcards.",
                theme: app.theme
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("QUESTION TYPES")
                    .font(.system(size: 10, weight: .medium)).tracking(1.6)
                    .foregroundStyle(app.theme.ink3)
                HStack(spacing: 8) {
                    ForEach(QuizMode.allCases) { mode in
                        Chip(mode.label,
                             selected: selectedModes.contains(mode),
                             theme: app.theme) {
                            if selectedModes.contains(mode) {
                                if selectedModes.count > 1 { selectedModes.remove(mode) }
                            } else { selectedModes.insert(mode) }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("LENGTH")
                    .font(.system(size: 10, weight: .medium)).tracking(1.6)
                    .foregroundStyle(app.theme.ink3)
                HStack(spacing: 8) {
                    ForEach([5, 10, 20], id: \.self) { n in
                        Chip("\(n) questions", selected: length == n, theme: app.theme) {
                            length = n
                        }
                    }
                }
            }

            PrimaryButton(title: "Start quiz", theme: app.theme) {
                app.makeQuiz(modes: Array(selectedModes), length: length)
                chosenIndex = nil
                typingText = ""
                showResult = false
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Question

    @ViewBuilder
    private func question(_ item: QuizItem) -> some View {
        let count = app.quizItems.count
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("QUESTION \(app.quizIndex + 1) OF \(count)")
                    .font(.system(size: 10, weight: .medium)).tracking(1.6)
                    .foregroundStyle(app.theme.ink3)
                Spacer()
                Text("Score \(app.quizScore)")
                    .font(AppFont.mono(11))
                    .foregroundStyle(app.theme.ink2)
            }
            questionBar

            VStack(alignment: .leading, spacing: 8) {
                Text(promptLabel(for: item.mode))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(app.theme.ink3)
                Text(item.prompt)
                    .font(item.mode == .wordToMeaning
                          ? AppFont.display(28, weight: .regular)
                          : .system(size: 18))
                    .foregroundStyle(app.theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .glass(app.theme, .panel, radius: 16)

            if item.mode == .typing {
                typingArea(for: item)
            } else {
                optionsList(for: item)
            }

            if showResult {
                whyBlock(for: item)
            }

            HStack {
                Spacer()
                SecondaryButton(title: "End quiz", theme: app.theme) { app.resetQuiz() }
                if showResult {
                    PrimaryButton(title: app.quizIndex + 1 >= count ? "See results" : "Next question", theme: app.theme) {
                        app.advanceQuiz()
                        chosenIndex = nil
                        typingText = ""
                        showResult = false
                    }
                }
            }
        }
    }

    private var questionBar: some View {
        GeometryReader { proxy in
            let ratio = Double(app.quizIndex) / Double(max(app.quizItems.count, 1))
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

    private func promptLabel(for mode: QuizMode) -> String {
        switch mode {
        case .wordToMeaning: return "What does this word mean?"
        case .meaningToWord: return "Which word matches this meaning?"
        case .fillBlank:     return "Fill in the blank"
        case .pronunciation: return "Which word has this pronunciation?"
        case .typing:        return "Type the word for this meaning"
        }
    }

    private func optionsList(for item: QuizItem) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(item.options.enumerated()), id: \.offset) { idx, option in
                Button {
                    guard !showResult else { return }
                    chosenIndex = idx
                    wasCorrect = idx == item.answerIndex
                    app.answerQuiz(correct: wasCorrect)
                    showResult = true
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(UnicodeScalar(65 + idx)!))
                            .font(AppFont.mono(11, weight: .semibold))
                            .frame(width: 22, height: 22)
                            .glass(app.theme, .chip, radius: 999)
                            .foregroundStyle(app.theme.ink2)
                        Text(option)
                            .font(.system(size: 14))
                            .foregroundStyle(app.theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        if showResult && idx == item.answerIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "4ADE80"))
                        }
                        if showResult && idx == chosenIndex && idx != item.answerIndex {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(hex: "FB7185"))
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glass(app.theme, .card, radius: 13)
                    .overlay {
                        if showResult && idx == item.answerIndex {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(Color(hex: "4ADE80"), lineWidth: 1.4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func typingArea(for item: QuizItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Type the word…", text: $typingText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .padding(14)
                .glass(app.theme, .input, radius: 12)
                .disabled(showResult)

            if !showResult {
                PrimaryButton(title: "Check", theme: app.theme) {
                    let ok = typingText.trimmingCharacters(in: .whitespaces).lowercased()
                        == item.word.word.lowercased()
                    wasCorrect = ok
                    app.answerQuiz(correct: ok)
                    showResult = true
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(wasCorrect ? Color(hex: "4ADE80") : Color(hex: "FB7185"))
                    Text(wasCorrect ? "Correct — \(item.word.word)"
                                    : "Answer: \(item.word.word)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(app.theme.ink)
                }
            }
        }
    }

    private func whyBlock(for item: QuizItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EXPLANATION")
                .font(.system(size: 9, weight: .medium)).tracking(1.4)
                .foregroundStyle(app.theme.ink3)
            (Text(item.word.word).font(.system(size: 13, weight: .semibold))
             + Text(" — ") + Text(item.word.meaning))
                .foregroundStyle(app.theme.ink2)
                .fixedSize(horizontal: false, vertical: true)
            if !item.word.example.isEmpty {
                Text(item.word.example)
                    .font(.system(size: 12))
                    .italic()
                    .foregroundStyle(app.theme.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(app.theme, .card, radius: 12)
    }

    // MARK: - Result

    private var result: some View {
        let total = app.quizItems.count
        let percent = total == 0 ? 0 : Int(round(Double(app.quizScore) / Double(total) * 100))
        return VStack(alignment: .leading, spacing: 20) {
            ScreenHeader(eyebrow: "QUIZ COMPLETE", title: "Nicely done", theme: app.theme)
            VStack(alignment: .leading, spacing: 12) {
                Text("You scored")
                    .font(.system(size: 12)).foregroundStyle(app.theme.ink3)
                Text("\(app.quizScore) / \(total)")
                    .font(AppFont.display(48, weight: .regular))
                    .foregroundStyle(app.theme.ink)
                Text("\(percent)% accuracy")
                    .font(AppFont.mono(13))
                    .foregroundStyle(app.theme.ink2)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(app.theme, .panel, radius: 18)

            HStack {
                PrimaryButton(title: "New quiz", theme: app.theme) { app.resetQuiz() }
                Spacer()
            }
        }
    }
}
