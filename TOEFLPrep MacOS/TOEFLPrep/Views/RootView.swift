import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Sections

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case today, cards, quiz, reading, library, progress, settings
    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .today:    return "Today"
        case .cards:    return "Flashcards"
        case .quiz:     return "Quiz"
        case .reading:  return "Reading"
        case .library:  return "Library"
        case .progress: return "Progress"
        case .settings: return "Settings"
        }
    }

    var group: SectionGroup {
        switch self {
        case .today, .cards, .quiz, .reading, .library: return .study
        case .progress, .settings: return .setup
        }
    }

    var symbol: String {
        switch self {
        case .today:    return "plus.square"
        case .cards:    return "rectangle.on.rectangle"
        case .quiz:     return "questionmark.circle"
        case .reading:  return "text.book.closed"
        case .library:  return "books.vertical"
        case .progress: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

enum SectionGroup: String {
    case study = "Study"
    case setup = "Setup"
}

// MARK: - Root

struct RootView: View {
    @EnvironmentObject private var app: AppState
    @State private var selection: AppSection = .today

    var body: some View {
        ZStack {
            // Wallpaper reaches every window edge, including under the titlebar
            // on macOS and under the status bar on iPad. Content, however,
            // stays inside the safe area so nothing sits under the iPad's
            // status bar or home indicator.
            AuroraBackground(theme: app.theme)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                Sidebar(selection: $selection)
                    .frame(width: 232)

                Divider()
                    .overlay(app.theme.hairlineSoft)

                ContentHost(section: selection)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Falling petals for Sakura & Sunflower — also cover the whole window
            if app.theme.hasPetals {
                PetalsOverlay(colors: app.theme.petalColors)
                    .ignoresSafeArea()
            }
        }
        .tint(app.theme.accent)
        .preferredColorScheme(app.theme.isLight ? .light : .dark)
        #if os(macOS)
        .background(WindowChrome())
        #endif
    }
}

// MARK: - Sidebar (matches the HTML .side nav exactly)

private struct Sidebar: View {
    @EnvironmentObject private var app: AppState
    @Binding var selection: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            #if os(macOS)
            // Room for the real macOS traffic lights that float over the sidebar.
            Spacer().frame(height: 44)
            #endif

            eyebrow("Study")
            item(.today)
            item(.cards, badge: app.deck.count)
            item(.quiz)
            item(.reading, badge: DataStore.passages.count)
            item(.library, badge: DataStore.vocab.count)

            eyebrow("Setup").padding(.top, 12)
            item(.progress)
            item(.settings)

            Spacer()

            streakFooter
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
    }

    private func eyebrow(_ text: String) -> some View {
        Text(L10n.t(text, app.language).uppercased())
            .font(.system(size: 10, weight: .medium))
            .tracking(1.6)
            .foregroundStyle(app.theme.ink3)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
    }

    private func item(_ section: AppSection, badge: Int? = nil) -> some View {
        let isSelected = selection == section
        return Button {
            withAnimation(.easeOut(duration: 0.18)) { selection = section }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: section.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)
                Text(L10n.t(section.localizationKey, app.language))
                    .font(.system(size: 13.5, weight: isSelected ? .semibold : .medium))
                Spacer(minLength: 0)
                if let badge, badge > 0 {
                    Text("\(badge)")
                        .font(AppFont.mono(10.5, weight: .regular))
                        .foregroundStyle(app.theme.ink3)
                }
            }
            .foregroundStyle(isSelected ? app.theme.ink : app.theme.ink2)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(app.theme.isLight ? 0.55 : 0.13) : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(isSelected ? app.theme.hairline : Color.clear, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private var streakFooter: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill").foregroundStyle(.orange)
            Text("\(app.currentStreak)")
                .font(AppFont.mono(16, weight: .medium))
                .foregroundStyle(app.theme.ink)
            Text(L10n.t("day streak", app.language))
                .font(.system(size: 12))
                .foregroundStyle(app.theme.ink2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            Rectangle().fill(app.theme.hairlineSoft).frame(height: 1)
        }
    }
}

// MARK: - Content host

private struct ContentHost: View {
    let section: AppSection

    var body: some View {
        Group {
            switch section {
            case .today:    TodayView()
            case .cards:    CardsView()
            case .quiz:     QuizView()
            case .reading:  ReadingView()
            case .library:  LibraryView()
            case .progress: ProgressPageView()
            case .settings: SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Transparent titlebar (macOS only)

#if os(macOS)
/// Removes the opaque top strip so the frosted window reaches to the top edge.
/// Keeps macOS's own traffic lights in place — they're painted by the system.
private struct WindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { configure(v.window) }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }
    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.toolbar = nil
    }
}
#endif
