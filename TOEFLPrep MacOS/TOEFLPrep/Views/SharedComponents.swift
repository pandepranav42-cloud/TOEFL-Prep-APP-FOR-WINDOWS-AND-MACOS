import SwiftUI

// MARK: - Chip (pill button used across filters and quiz selectors)

struct Chip: View {
    let text: String
    let selected: Bool
    let theme: AppTheme
    let action: () -> Void

    init(_ text: String, selected: Bool = false, theme: AppTheme, action: @escaping () -> Void = {}) {
        self.text = text
        self.selected = selected
        self.theme = theme
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppFont.mono(11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(selected ? theme.ink : theme.ink2)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(selected ? Color.white.opacity(theme.isLight ? 0.55 : 0.20)
                                       : theme.surface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .strokeBorder(selected ? theme.hairline : theme.hairlineSoft, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Primary and secondary buttons matching the HTML

struct PrimaryButton: View {
    let title: String
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.isLight ? .white : Color(hex: "0A0E1C"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(
                            colors: [theme.accent, theme.accentAlt],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glass(theme, .chip, radius: 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Difficulty dots (five colored dots to match the HTML .dot ramp)

struct DifficultyDots: View {
    let diff: Int
    let theme: AppTheme

    private var color: Color {
        switch diff {
        case 1: return Color(hex: "4ADE80")   // green
        case 2: return Color(hex: "22D3EE")   // cyan
        case 3: return Color(hex: "FBBF24")   // yellow
        case 4: return Color(hex: "FB923C")   // orange
        default: return Color(hex: "FB7185")  // red / hardest
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= diff ? color : theme.ink3.opacity(0.28))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

// MARK: - The little vertical accent bar down the left of Library word cards
//
// The bar's colour used to follow the Leitner box, which meant every fresh
// word — all sitting in box 1 — got the same red bar, and the whole grid
// looked flat. It now follows the word's inherent difficulty (1..5),
// matching the coloured dot ramp so a glance at the grid tells you the
// spread of hard vs easy words.

struct DifficultyAccentBar: View {
    let diff: Int
    let theme: AppTheme

    private var color: Color {
        switch diff {
        case 1: return Color(hex: "4ADE80")   // green   — easiest
        case 2: return Color(hex: "22D3EE")   // cyan
        case 3: return Color(hex: "FBBF24")   // yellow
        case 4: return Color(hex: "FB923C")   // orange
        default: return Color(hex: "FB7185")  // red     — hardest
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: 3)
    }
}

// MARK: - Little "box N" chip used on library cards

struct BoxChip: View {
    let box: Int
    let theme: AppTheme
    var body: some View {
        Text("box \(box)")
            .font(AppFont.mono(10, weight: .medium))
            .foregroundStyle(theme.ink2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule().fill(theme.surface)
            }
            .overlay {
                Capsule().strokeBorder(theme.hairlineSoft, lineWidth: 1)
            }
    }
}

// MARK: - Big stat card (Progress screen and Today's mini stats)

struct StatCard: View {
    let value: String
    let label: String
    let theme: AppTheme
    var valueColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(AppFont.mono(28, weight: .semibold))
                .foregroundStyle(valueColor ?? theme.ink)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(theme.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glass(theme, .card)
    }
}

// MARK: - Empty placeholder used when a section has nothing to show

struct EmptyStatePlaceholder: View {
    let title: String
    let systemImage: String
    var message: String? = nil
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(theme.ink3)
            Text(title)
                .font(AppFont.body(15, weight: .semibold))
                .foregroundStyle(theme.ink)
            if let message {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(theme.ink2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Section header used on top of every screen ("EYEBROW · TITLE · subtitle")

struct ScreenHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?
    let theme: AppTheme

    init(eyebrow: String, title: String, subtitle: String? = nil, theme: AppTheme) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.theme = theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(theme.ink3)
            Text(title)
                .font(AppFont.display(30, weight: .regular))
                .foregroundStyle(theme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
