import SwiftUI

// Generated from the web app's stylesheet so the two cannot drift apart.
// Every value below is the CSS custom property of the same name, converted
// literally. If a colour looks wrong here, it is wrong in the CSS too.

enum AppTheme: String, CaseIterable, Identifiable, Codable, Hashable {
    case graphite, midnight, ocean, forest, ember, aurora, mono, light, sakura, sunflower

    var id: String { rawValue }

    /// Only Sakura and Sunflower appear under the "Special" heading in Settings.
    var isSpecial: Bool { self == .sakura || self == .sunflower }

    /// Light palettes invert the ink and use white translucent surfaces.
    var isLight: Bool { [.light, .sakura, .sunflower].contains(self) }

    /// Falling petals are drawn only for these two.
    var hasPetals: Bool { [.sakura, .sunflower].contains(self) }

    var label: String {
        switch self {
        case .graphite: return "Graphite"
        case .midnight: return "Midnight"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .ember: return "Ember"
        case .aurora: return "Aurora"
        case .mono: return "Minimal black"
        case .light: return "Light"
        case .sakura: return "Sakura"
        case .sunflower: return "Sunflower"
        }
    }

    /// The two-stop gradient on the Settings swatch.
    var swatch: [Color] {
        switch self {
        case .graphite: return [Color(hex: "7C8AA0"), Color(hex: "3A4557")]
        case .midnight: return [Color(hex: "3B5BA5"), Color(hex: "14224A")]
        case .ocean: return [Color(hex: "3AA8B8"), Color(hex: "0E4A60")]
        case .forest: return [Color(hex: "4FA97B"), Color(hex: "12402F")]
        case .ember: return [Color(hex: "D2795C"), Color(hex: "5E2436")]
        case .aurora: return [Color(hex: "7C6BE0"), Color(hex: "4C6FFF")]
        case .mono: return [Color(hex: "2A2E34"), Color(hex: "08090B")]
        case .light: return [Color(hex: "FFFFFF"), Color(hex: "D5DBE4")]
        case .sakura: return [Color(hex: "FFFFFF"), Color(hex: "FFB6D5")]
        case .sunflower: return [Color(hex: "FFFDF2"), Color(hex: "FFD84D")]
        }
    }

    /// Buttons, ring, chart fills. CSS --accent.
    var accent: Color {
        switch self {
        case .graphite: return Color(hex: "B9C6D6")
        case .midnight: return Color(hex: "9CC0FF")
        case .ocean: return Color(hex: "7FE3DA")
        case .forest: return Color(hex: "9BE3B4")
        case .ember: return Color(hex: "F6C08A")
        case .aurora: return Color(hex: "B9A8FF")
        case .mono: return Color(hex: "D6DAE0")
        case .light: return Color(hex: "6B7C93")
        case .sakura: return Color(hex: "F77FB4")
        case .sunflower: return Color(hex: "E9A81E")
        }
    }

    /// Gradient partner for the accent. CSS --accent-2.
    var accentAlt: Color {
        switch self {
        case .graphite: return Color(hex: "8496AD")
        case .midnight: return Color(hex: "5B84D6")
        case .ocean: return Color(hex: "3AA8B8")
        case .forest: return Color(hex: "4FA97B")
        case .ember: return Color(hex: "D2795C")
        case .aurora: return Color(hex: "7C6BE0")
        case .mono: return Color(hex: "9AA1AA")
        case .light: return Color(hex: "4E5D72")
        case .sakura: return Color(hex: "F0619B")
        case .sunflower: return Color(hex: "D18F0C")
        }
    }

    /// Primary text. CSS --ink.
    var ink: Color {
        switch self {
        case .light: return Color(hex: "2C333D")
        case .sakura: return Color(hex: "43303A")
        case .sunflower: return Color(hex: "43371F")
        default: return Color(hex: "F6F8FF")
        }
    }

    /// Secondary text. CSS --ink-2.
    var ink2: Color {
        switch self {
        case .light: return Color(hex: "2C333D", opacity: 0.70)
        case .sakura: return Color(hex: "43303A", opacity: 0.70)
        case .sunflower: return Color(hex: "43371F", opacity: 0.70)
        default: return Color(hex: "F6F8FF", opacity: 0.66)
        }
    }

    /// Tertiary text and labels. CSS --ink-3.
    var ink3: Color {
        switch self {
        case .light: return Color(hex: "2C333D", opacity: 0.44)
        case .sakura: return Color(hex: "43303A", opacity: 0.44)
        case .sunflower: return Color(hex: "43371F", opacity: 0.44)
        default: return Color(hex: "F6F8FF", opacity: 0.40)
        }
    }

    /// Panel borders. CSS --hairline.
    var hairline: Color {
        switch self {
        case .mono: return Color(hex: "FFFFFF", opacity: 0.13)
        case .light: return Color(hex: "5A697D", opacity: 0.20)
        case .sakura: return Color(hex: "F096C3", opacity: 0.34)
        case .sunflower: return Color(hex: "D6A028", opacity: 0.30)
        default: return Color(hex: "FFFFFF", opacity: 0.16)
        }
    }

    /// Inner dividers. CSS --hairline-soft.
    var hairlineSoft: Color {
        switch self {
        case .mono: return Color(hex: "FFFFFF", opacity: 0.07)
        case .light: return Color(hex: "5A697D", opacity: 0.12)
        case .sakura: return Color(hex: "F096C3", opacity: 0.20)
        case .sunflower: return Color(hex: "D6A028", opacity: 0.18)
        default: return Color(hex: "FFFFFF", opacity: 0.09)
        }
    }

    /// Window background behind the wallpaper. CSS --void.
    var background: Color {
        switch self {
        case .mono: return Color(hex: "08090B")
        case .light: return Color(hex: "F4F5F8")
        case .sakura: return Color(hex: "FFF4F9")
        case .sunflower: return Color(hex: "FFFBEC")
        default: return Color(hex: "05070F")
        }
    }

    /// Wallpaper blob 1. CSS --aurora-1.
    var aurora1: Color {
        switch self {
        case .graphite: return Color(hex: "5B6B82")
        case .midnight: return Color(hex: "2C4A8F")
        case .ocean: return Color(hex: "12707E")
        case .forest: return Color(hex: "1F6B4A")
        case .ember: return Color(hex: "8A3B2E")
        case .aurora: return Color(hex: "4C6FFF")
        case .mono: return Color(hex: "2A2E34")
        case .light: return Color(hex: "C9D2E0")
        case .sakura: return Color(hex: "FFC3DF")
        case .sunflower: return Color(hex: "FFE08A")
        }
    }

    /// Wallpaper blob 2. CSS --aurora-2.
    var aurora2: Color {
        switch self {
        case .graphite: return Color(hex: "6E7C91")
        case .midnight: return Color(hex: "1E3A73")
        case .ocean: return Color(hex: "0E5A76")
        case .forest: return Color(hex: "14543C")
        case .ember: return Color(hex: "6E2A3F")
        case .aurora: return Color(hex: "A855F7")
        case .mono: return Color(hex: "1C1F24")
        case .light: return Color(hex: "DDE3EC")
        case .sakura: return Color(hex: "FFD8EC")
        case .sunflower: return Color(hex: "FFEDB8")
        }
    }

    /// Wallpaper blob 3. CSS --aurora-3.
    var aurora3: Color {
        switch self {
        case .graphite: return Color(hex: "46536A")
        case .midnight: return Color(hex: "22D3EE")
        case .ocean: return Color(hex: "22D3EE")
        case .forest: return Color(hex: "4ADE80")
        case .ember: return Color(hex: "FBBF24")
        case .aurora: return Color(hex: "22D3EE")
        case .mono: return Color(hex: "33383F")
        case .light: return Color(hex: "E6EAF1")
        case .sakura: return Color(hex: "FFE3F2")
        case .sunflower: return Color(hex: "FFF3D2")
        }
    }

    /// Wallpaper blob 4. CSS --aurora-4.
    var aurora4: Color {
        switch self {
        case .graphite: return Color(hex: "39445A")
        case .midnight: return Color(hex: "3B5BA5")
        case .ocean: return Color(hex: "1C8F86")
        case .forest: return Color(hex: "276B57")
        case .ember: return Color(hex: "A34A33")
        case .aurora: return Color(hex: "F472B6")
        case .mono: return Color(hex: "15171B")
        case .light: return Color(hex: "D2D9E4")
        case .sakura: return Color(hex: "FFCEE7")
        case .sunflower: return Color(hex: "FFE4A0")
        }
    }

    /// Card fill. CSS --surface on light palettes, --glass-alpha white on dark.
    var surface: Color {
        switch self {
        case .mono: return Color.white.opacity(0.055)
        case .light: return Color(hex: "FFFFFF", opacity: 0.64)
        case .sakura: return Color(hex: "FFFFFF", opacity: 0.62)
        case .sunflower: return Color(hex: "FFFFFF", opacity: 0.62)
        default: return Color.white.opacity(0.075)
        }
    }

    /// Recessed fill for options and inputs. CSS --surface-2.
    var surfaceAlt: Color {
        switch self {
        case .mono: return Color.white.opacity(0.0385)
        case .light: return Color(hex: "FFFFFF", opacity: 0.46)
        case .sakura: return Color(hex: "FFFFFF", opacity: 0.44)
        case .sunflower: return Color(hex: "FFFFFF", opacity: 0.44)
        default: return Color.white.opacity(0.0525)
        }
    }

    /// The main window panel. CSS --panel-solid.
    var panel: Color {
        switch self {
        case .mono: return Color.white.opacity(0.055)
        case .light: return Color(hex: "FFFFFF", opacity: 0.48)
        case .sakura: return Color(hex: "FFFFFF", opacity: 0.46)
        case .sunflower: return Color(hex: "FFFFFF", opacity: 0.46)
        default: return Color.white.opacity(0.075)
        }
    }

    /// Petal gradient stops. CSS --petal-1/2/3.
    var petalColors: [Color] {
        switch self {
        case .sakura: return [Color(hex: "FFC4DF"), Color(hex: "FF9CC6"), Color(hex: "F77FB4")]
        case .sunflower: return [Color(hex: "FFE49B"), Color(hex: "FFCE55"), Color(hex: "F5B916")]
        default: return []
        }
    }

    /// Wallpaper blob opacity. The light palettes need a brighter wash for the
    /// frosting to read as glass; Minimal black needs more than the other darks.
    var blobOpacity: Double {
        if isLight { return 0.66 }
        return self == .mono ? 0.60 : 0.30
    }

    /// The scrim over the wallpaper. CSS #wall::after.
    var scrimOpacity: Double {
        if isLight { return 0.0 }
        return self == .mono ? 0.18 : 0.42
    }

    /// Favorite symbol for the two special themes (heart/star variants).
    var favoriteFilled: String {
        switch self {
        case .sakura: return "heart.fill"
        case .sunflower: return "star.fill"
        default: return "heart.fill"
        }
    }

    var favoriteOutline: String {
        switch self {
        case .sakura: return "heart"
        case .sunflower: return "star"
        default: return "heart"
        }
    }
}

extension Color {
    /// Accepts "RRGGBB". Invalid input falls back to clear rather than crashing.
    init(hex: String, opacity: Double = 1.0) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value), cleaned.count == 6 else {
            self = .clear
            return
        }
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
