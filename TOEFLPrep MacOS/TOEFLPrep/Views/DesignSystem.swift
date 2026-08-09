import SwiftUI

/// The web app builds every panel from three ingredients: a backdrop blur, a
/// translucent tint on top of it, and a hairline border. `.ultraThinMaterial`
/// alone supplies only the first, which is why themed surfaces looked grey and
/// identical across palettes — the material ignores the theme completely.
enum GlassStyle {
    case panel   // the main window surface, CSS .glass
    case card    // .card, .lrow, .pass, .q, .stat
    case chip    // .chip, .btn
    case input   // text fields and recessed wells, CSS --surface-2

    var radius: CGFloat {
        switch self {
        case .panel: return 24
        case .card:  return 16
        case .chip:  return 11
        case .input: return 13
        }
    }
}

struct GlassSurface: ViewModifier {
    let theme: AppTheme
    let style: GlassStyle
    var radius: CGFloat?

    private var shapeRadius: CGFloat { radius ?? style.radius }

    /// Tint over the blur. Light palettes use white translucency (CSS
    /// --surface / --panel-solid); dark palettes use --glass-alpha white.
    private var tint: Color {
        switch style {
        case .panel: return theme.panel
        case .card, .chip: return theme.surface
        case .input: return theme.surfaceAlt
        }
    }

    private var border: Color {
        style == .panel ? theme.hairline : theme.hairlineSoft
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: shapeRadius, style: .continuous)
        return content
            .background {
                shape
                    .fill(.ultraThinMaterial)     // the blur
                    .overlay(shape.fill(tint))    // the theme's own colour
            }
            .overlay {
                shape.strokeBorder(border, lineWidth: 1)
            }
            .clipShape(shape)
    }
}

extension View {
    /// Applies the themed frosted surface. Use this instead of
    /// `.background(.ultraThinMaterial)`, which cannot see the theme.
    func glass(_ theme: AppTheme, _ style: GlassStyle = .card, radius: CGFloat? = nil) -> some View {
        modifier(GlassSurface(theme: theme, style: style, radius: radius))
    }
}

/// Type styles matching the web app: a serif display face for words and
/// headings, the system face for body copy, monospace for labels and numbers.
enum AppFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// The small uppercase, wide-tracked label used above every section.
struct SectionLabel: View {
    let text: String
    let theme: AppTheme

    var body: some View {
        Text(text.uppercased())
            .font(AppFont.body(10, weight: .medium))
            .tracking(1.6)
            .foregroundStyle(theme.ink3)
    }
}

// Note: DifficultyDots is defined in SharedComponents.swift with a `diff:` label
// that matches the vocabulary model's own field name.
