import SwiftUI

/// Falling petals for the Sakura and Sunflower palettes (CSS #petals).
///
/// The previous version created one animated `View` per petal, each with its
/// own repeating animation, which meant twenty independent animation timers
/// driving layout every frame. Everything is now drawn in a single `Canvas`
/// whose positions are a pure function of time, so there is no layout work and
/// no per-petal state.
struct PetalsOverlay: View {
    let colors: [Color]

    private struct Petal {
        let x: CGFloat        // horizontal position, fraction of width
        let size: CGFloat
        let period: Double    // seconds to fall the full height
        let offset: Double    // staggers the start
        let sway: CGFloat
        let spin: Double
    }

    /// Fixed rather than random so the pattern is stable across redraws.
    private static let petals: [Petal] = (0..<20).map { i in
        let f = Double(i)
        return Petal(
            x: CGFloat((f * 0.137).truncatingRemainder(dividingBy: 1.0)),
            size: 10 + CGFloat((f * 0.31).truncatingRemainder(dividingBy: 1.0)) * 11,
            period: 11 + (f * 0.53).truncatingRemainder(dividingBy: 1.0) * 11,
            offset: (f * 0.71).truncatingRemainder(dividingBy: 1.0),
            sway: 18 + CGFloat((f * 0.19).truncatingRemainder(dividingBy: 1.0)) * 22,
            spin: 220 + (f * 0.41).truncatingRemainder(dividingBy: 1.0) * 300
        )
    }

    var body: some View {
        guard colors.count >= 3 else { return AnyView(EmptyView()) }
        return AnyView(
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for petal in Self.petals {
                        // progress from 0 (above the top) to 1 (past the bottom)
                        let p = ((t / petal.period) + petal.offset).truncatingRemainder(dividingBy: 1.0)
                        let y = -40 + p * (size.height + 80)
                        let x = petal.x * size.width + sin(p * .pi * 2) * petal.sway

                        // fade in at the top and out at the bottom
                        let fade: Double
                        if p < 0.12 { fade = p / 0.12 }
                        else if p > 0.88 { fade = (1 - p) / 0.12 }
                        else { fade = 1 }

                        var petalContext = context
                        petalContext.opacity = 0.85 * fade
                        petalContext.translateBy(x: x, y: y)
                        petalContext.rotate(by: .degrees(p * petal.spin))

                        let rect = CGRect(x: -petal.size / 2, y: -petal.size / 2,
                                          width: petal.size, height: petal.size)
                        // the lopsided corner radii give the petal its shape
                        let path = Path(roundedRect: rect,
                                        cornerSize: CGSize(width: petal.size * 0.5,
                                                           height: petal.size * 0.12))
                        petalContext.fill(path, with: .linearGradient(
                            Gradient(colors: [colors[0], colors[1], colors[2]]),
                            startPoint: CGPoint(x: rect.minX, y: rect.minY),
                            endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        )
    }
}
