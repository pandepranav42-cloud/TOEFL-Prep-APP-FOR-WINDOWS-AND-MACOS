import SwiftUI
import Combine

struct ReadingView: View {
    @EnvironmentObject private var app: AppState

    @State private var difficultyFilter: Int = 0    // 0 = any level
    @State private var statusFilter: Status = .all
    @State private var categoryFilter: String = "All"
    @State private var openPassage: Passage? = nil

    enum Status: String, CaseIterable { case all = "All", notRead = "Not read", completed = "Completed" }

    private var filtered: [Passage] {
        DataStore.passages.filter { p in
            (difficultyFilter == 0 || p.diff == difficultyFilter) &&
            (statusFilter == .all
                || (statusFilter == .notRead   && !app.isPassageDone(p))
                || (statusFilter == .completed &&  app.isPassageDone(p))) &&
            (categoryFilter == "All" || p.cat == categoryFilter)
        }
    }

    private var completedCount: Int { DataStore.passages.filter { app.isPassageDone($0) }.count }

    var body: some View {
        Group {
            if let p = openPassage {
                ReaderView(passage: p) { openPassage = nil }
            } else {
                grid
            }
        }
    }

    // MARK: - Grid

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(
                    eyebrow: "\(DataStore.passages.count) passages · \(completedCount) completed",
                    title: L10n.t("Reading", app.language),
                    subtitle: "Academic passages in the style of the TOEFL reading section. Read, then answer the questions underneath. Explanations appear as you go.",
                    theme: app.theme
                )

                filterRow

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14)],
                          spacing: 14) {
                    ForEach(filtered) { p in
                        PassageCard(passage: p) { openPassage = p }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
        }
    }

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    Chip(s.rawValue, selected: statusFilter == s, theme: app.theme) { statusFilter = s }
                }
                Menu {
                    Button("All") { categoryFilter = "All" }
                    Divider()
                    ForEach(DataStore.passageCategories, id: \.self) { c in
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
    }
}

// MARK: - Passage card

private struct PassageCard: View {
    @EnvironmentObject private var app: AppState
    let passage: Passage
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(passage.title)
                        .font(AppFont.display(19, weight: .regular))
                        .foregroundStyle(app.theme.ink)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Text(passage.cat.uppercased())
                            .font(.system(size: 10, weight: .medium)).tracking(1.4)
                            .foregroundStyle(app.theme.ink3)
                        Circle().fill(app.theme.ink3.opacity(0.6)).frame(width: 3, height: 3)
                        Text("\(passage.questions.count) QUESTIONS")
                            .font(.system(size: 10, weight: .medium)).tracking(1.4)
                            .foregroundStyle(app.theme.ink3)
                    }
                }
                Spacer(minLength: 0)
                DifficultyDots(diff: passage.diff, theme: app.theme)
                    .padding(.top, 4)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(app.theme, .card, radius: 14)
            .overlay(alignment: .topTrailing) {
                if app.isPassageDone(passage) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(app.theme.accent)
                        .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reader

private struct ReaderView: View {
    @EnvironmentObject private var app: AppState
    let passage: Passage
    let onBack: () -> Void

    @State private var notes: String = ""
    @State private var seconds: Int = 0
    @State private var timerRunning: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Button {
                        onBack()
                    } label: {
                        Label("All passages", systemImage: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(app.theme.ink2)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(passage.cat.uppercased())
                        .font(.system(size: 10, weight: .medium)).tracking(1.6)
                        .foregroundStyle(app.theme.ink3)
                    Text(passage.title)
                        .font(AppFont.display(30, weight: .regular))
                        .foregroundStyle(app.theme.ink)
                    HStack(spacing: 10) {
                        DifficultyDots(diff: passage.diff, theme: app.theme)
                        Text("\(wordCount) words")
                            .font(AppFont.mono(11))
                            .foregroundStyle(app.theme.ink3)
                        Text("· \(timerText)")
                            .font(AppFont.mono(11))
                            .foregroundStyle(app.theme.ink3)
                        Button(timerRunning ? "Pause" : "Start timer") {
                            timerRunning.toggle()
                        }
                        .buttonStyle(.plain)
                        .font(AppFont.mono(11, weight: .medium))
                        .foregroundStyle(app.theme.accent)
                    }
                }

                Text(passage.text)
                    .font(AppFont.display(16, weight: .regular))
                    .foregroundStyle(app.theme.ink2)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glass(app.theme, .panel, radius: 16)

                ForEach(Array(passage.questions.enumerated()), id: \.offset) { idx, q in
                    QuestionCard(passage: passage, questionIndex: idx, question: q)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTES").font(.system(size: 10, weight: .medium)).tracking(1.4)
                        .foregroundStyle(app.theme.ink3)
                    TextEditor(text: $notes)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(app.theme.ink)
                        .padding(10)
                        .frame(minHeight: 90)
                        .glass(app.theme, .input, radius: 12)
                        .onChange(of: notes) { _, newValue in
                            app.updatePassageNotes(passage, notes: newValue)
                        }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
        }
        .onAppear { notes = app.progressFor(passage).notes }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timerRunning { seconds += 1 }
        }
    }

    private var wordCount: Int {
        passage.text.split { $0.isWhitespace }.count
    }
    private var timerText: String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct QuestionCard: View {
    @EnvironmentObject private var app: AppState
    let passage: Passage
    let questionIndex: Int
    let question: PassageQuestion

    var body: some View {
        let chosen = app.progressFor(passage).answers[questionIndex]
        VStack(alignment: .leading, spacing: 12) {
            Text("QUESTION \(questionIndex + 1)")
                .font(.system(size: 10, weight: .medium)).tracking(1.4)
                .foregroundStyle(app.theme.ink3)
            Text(question.question)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(app.theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 6) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                    Button {
                        app.answerPassageQuestion(passage, questionIndex: questionIndex, optionIndex: idx)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text(String(UnicodeScalar(65 + idx)!))
                                .font(AppFont.mono(11, weight: .semibold))
                                .frame(width: 20, height: 20)
                                .foregroundStyle(app.theme.ink2)
                                .glass(app.theme, .chip, radius: 999)
                            Text(option)
                                .font(.system(size: 13))
                                .foregroundStyle(app.theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            if let c = chosen, c == idx, c == question.answerIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "4ADE80"))
                            } else if let c = chosen, c == idx {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(hex: "FB7185"))
                            } else if chosen != nil, idx == question.answerIndex {
                                Image(systemName: "checkmark").foregroundStyle(Color(hex: "4ADE80"))
                            }
                        }
                        .padding(11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glass(app.theme, .card, radius: 11)
                    }
                    .buttonStyle(.plain)
                    .disabled(chosen != nil)
                }
            }
            if chosen != nil {
                Text(question.explanation)
                    .font(.system(size: 12))
                    .foregroundStyle(app.theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glass(app.theme, .card, radius: 10)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(app.theme, .panel, radius: 14)
    }
}
