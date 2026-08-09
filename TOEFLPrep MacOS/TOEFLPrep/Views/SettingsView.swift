import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// A tiny FileDocument used by .fileExporter so exports work identically
// on macOS and iPad. The bytes to write are set at construction time.
private struct BlobDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    var data: Data
    var typeHint: UTType

    init(data: Data, type: UTType) {
        self.data = data
        self.typeHint = type
    }
    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
        self.typeHint = .data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @State private var importStatus: String = ""
    @State private var showResetConfirm = false
    @State private var emailCopied: Bool = false

    // File import
    @State private var showImporter: Bool = false

    // File export — one flag per format, and the payload we're about to write.
    @State private var showExporter: Bool = false
    @State private var exportDocument: BlobDocument = BlobDocument(data: Data(), type: .json)
    @State private var exportFilename: String = "toefl.json"
    @State private var exportType: UTType = .json

    private var coreThemes: [AppTheme] {
        AppTheme.allCases.filter { !$0.isSpecial }
    }
    private var specialThemes: [AppTheme] {
        AppTheme.allCases.filter(\.isSpecial)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header

                languageSection
                appColourSection
                importExportSection
                notificationsSection
                developerSection

                aboutFooter
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .alert("Reset all progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { app.resetProgress() }
        } message: {
            Text("This clears streaks, favorites and review history. The vocabulary itself stays in place.")
        }
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.json, .commaSeparatedText, .plainText]) { result in
            if case .success(let url) = result {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                importStatus = app.importFile(url: url)
            }
        }
        .fileExporter(isPresented: $showExporter,
                      document: exportDocument,
                      contentType: exportType,
                      defaultFilename: exportFilename) { _ in }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t("Settings", app.language))
                .font(AppFont.display(34, weight: .regular))
                .foregroundStyle(app.theme.ink)
            Text("Everything runs offline. Progress is stored on this device.")
                .font(.system(size: 13))
                .foregroundStyle(app.theme.ink2)
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Language")
            HStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { lang in
                    Chip(lang.label, selected: app.language == lang, theme: app.theme) {
                        app.language = lang
                        app.save()
                    }
                }
            }
            Text("The vocabulary stays in English — that is what you are studying. This changes the interface.")
                .font(.system(size: 12))
                .foregroundStyle(app.theme.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Colour

    private var appColourSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("App colour")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8),
                      alignment: .leading, spacing: 14) {
                ForEach(coreThemes) { t in
                    Swatch(theme: t)
                }
            }

            HStack(spacing: 6) {
                Text("SPECIAL")
                    .font(.system(size: 10, weight: .semibold)).tracking(1.6)
                    .foregroundStyle(app.theme.accent)
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundStyle(app.theme.accent)
            }
            .padding(.top, 6)

            // Same 8-column grid the core themes use, so Sakura and Sunflower
            // render at the same tile size instead of stretching to fill the
            // whole row as huge pills.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8),
                      alignment: .leading, spacing: 14) {
                ForEach(specialThemes) { t in
                    Swatch(theme: t, isSpecial: true)
                }
            }
        }
    }

    // MARK: - Import / export

    private var importExportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Import and export")

            Text("IMPORT")
                .font(.system(size: 10, weight: .medium)).tracking(1.4)
                .foregroundStyle(app.theme.ink3)

            VStack(spacing: 8) {
                Text("Drop a CSV, JSON, or TXT file here")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(app.theme.ink)
                Text("Words or reading passages — the app works out which from the file.")
                    .font(.system(size: 12))
                    .foregroundStyle(app.theme.ink2)
                Text("Words, CSV header: word, meaning, ipa, pos, example, syn, ant, diff, cat, sec, tip. TXT: one “word — meaning” pair per line.")
                    .font(.system(size: 11))
                    .foregroundStyle(app.theme.ink3)
                Text("Passages, JSON: title, category, difficulty, text, and questions with four options, the index of the correct one, and an explanation.")
                    .font(.system(size: 11))
                    .foregroundStyle(app.theme.ink3)
                if !importStatus.isEmpty {
                    Text(importStatus)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(app.theme.accent)
                }
            }
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(app.theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            }
            .glass(app.theme, .card, radius: 16)
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
                handleDrop(providers)
                return true
            }

            HStack(spacing: 10) {
                SecondaryButton(title: "Choose file", theme: app.theme) { chooseFile() }
                SecondaryButton(title: "Export words + progress", theme: app.theme) { exportProgress() }
                SecondaryButton(title: "Export CSV", theme: app.theme) { exportCSV() }
                SecondaryButton(title: "Export passages", theme: app.theme) { exportPassages() }
                Spacer()
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Notifications")
            HStack {
                Text("Daily study reminder")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(app.theme.ink)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { app.dailyReminder },
                    set: { app.dailyReminder = $0; app.save() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }
            .padding(16)
            .glass(app.theme, .card, radius: 13)
        }
    }

    // MARK: - Developer

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Developer")
            DeveloperCard(copied: $emailCopied)
        }
    }

    // MARK: - Footer

    private var aboutFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(DataStore.vocab.count) words · \(DataStore.passages.count) passages · \(DataStore.quotes.count) quotes")
                        .font(AppFont.mono(11))
                        .foregroundStyle(app.theme.ink3)
                    Text("TOEFL Preparation · your learning data remains on this Mac.")
                        .font(.system(size: 11))
                        .foregroundStyle(app.theme.ink3)
                }
                Spacer()
                Button("Reset all progress…", role: .destructive) { showResetConfirm = true }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "FB7185"))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .glass(app.theme, .chip, radius: 10)
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(L10n.t(text, app.language).uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(app.theme.ink3)
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for p in providers {
            p.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                guard let data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    importStatus = app.importFile(url: url)
                }
            }
        }
    }

    private func chooseFile() {
        showImporter = true
    }

    private func exportProgress() {
        guard let data = app.exportStateJSON() else { return }
        beginExport(data: data, name: "toefl-progress.json", type: .json)
    }
    private func exportCSV() {
        let s = app.exportVocabCSV()
        beginExport(data: Data(s.utf8), name: "toefl-vocab.csv", type: .commaSeparatedText)
    }
    private func exportPassages() {
        guard let data = app.exportPassagesJSON() else { return }
        beginExport(data: data, name: "toefl-passages.json", type: .json)
    }

    private func beginExport(data: Data, name: String, type: UTType) {
        exportDocument = BlobDocument(data: data, type: type)
        exportFilename = name
        exportType = type
        showExporter = true
    }
}

// MARK: - Colour swatch button

private struct Swatch: View {
    @EnvironmentObject private var app: AppState
    let theme: AppTheme
    var isSpecial: Bool = false

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) { app.theme = theme }
            app.save()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: theme.swatch,
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(height: 62)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(app.theme == theme
                                              ? Color.white
                                              : Color.black.opacity(0.15),
                                              lineWidth: app.theme == theme ? 2 : 1)
                        }
                    if isSpecial {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                }
                Text(theme.label)
                    .font(.system(size: 11, weight: app.theme == theme ? .semibold : .regular))
                    .foregroundStyle(app.theme == theme ? app.theme.ink : app.theme.ink2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Developer card
//
// Restores the "Built by Pranav Pande" panel from the HTML — a monogram
// avatar tinted with the current palette, name and email, and the three
// action buttons (Contact opens Mail, Copy email uses NSPasteboard, GitHub
// opens the repo). The e-mail and repo URL live here rather than in the
// state store since they don't change per user.

private struct DeveloperCard: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.openURL) private var openURL
    @Binding var copied: Bool

    private let name  = "Pranav Pande"
    private let email = "pandepranav42@hotmail.com"

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            monogram

            VStack(alignment: .leading, spacing: 3) {
                Text("BUILT BY")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(app.theme.ink3)
                Text(name)
                    .font(AppFont.display(20, weight: .regular))
                    .foregroundStyle(app.theme.ink)
                Text(email)
                    .font(AppFont.mono(11, weight: .medium))
                    .foregroundStyle(app.theme.accent)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                Button("Contact") { openMail() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(app.theme.isLight ? .white : Color(hex: "0A0E1C"))
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(LinearGradient(colors: [app.theme.accent, app.theme.accentAlt],
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing))
                    }
                Button(copied ? "Copied" : "Copy email") { copyEmail() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(app.theme.accent)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .glass(app.theme, .chip, radius: 8)
            }
        }
        .padding(18)
        .glass(app.theme, .card, radius: 18)
    }

    private var monogram: some View {
        Text("PP")
            .font(AppFont.display(22, weight: .regular))
            .foregroundStyle(.white)
            .frame(width: 58, height: 58)
            .background {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(LinearGradient(
                        colors: [app.theme.accent, app.theme.accentAlt.opacity(0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: 0.8)
            }
    }

    private func openMail() {
        guard let url = URL(string: "mailto:\(email)?subject=TOEFL%20Preparation") else { return }
        openURL(url)
    }

    private func copyEmail() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(email, forType: .string)
        #else
        UIPasteboard.general.string = email
        #endif
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { copied = false }
    }
}
