import SwiftUI

/// The drifting wallpaper behind every panel (CSS #wall and .blob).
///
/// Two things were wrong before: the blob colours were hard-coded, so every
/// palette produced the same blue-violet wash, and four separately animated
/// blurred circles were composited on each frame. This draws the whole
/// wallpaper in one `Canvas` pass using the theme's own aurora colours.
struct AuroraBackground: View {
    let theme: AppTheme

    private struct Blob {
        let color: Color
        let center: CGPoint     // fractions of the view
        let drift: CGPoint      // how far it travels, in fractions
        let scale: CGFloat      // relative to the shorter edge
        let period: Double      // seconds for a full cycle
    }

    private var blobs: [Blob] {
        [
            Blob(color: theme.aurora1, center: CGPoint(x: 0.08, y: 0.10),
                 drift: CGPoint(x: 0.06, y: 0.07), scale: 0.62, period: 34),
            Blob(color: theme.aurora2, center: CGPoint(x: 0.92, y: 0.18),
                 drift: CGPoint(x: -0.07, y: 0.05), scale: 0.54, period: 41),
            Blob(color: theme.aurora3, center: CGPoint(x: 0.40, y: 0.92),
                 drift: CGPoint(x: 0.05, y: -0.06), scale: 0.50, period: 47),
            Blob(color: theme.aurora4, center: CGPoint(x: 0.78, y: 0.86),
                 drift: CGPoint(x: -0.04, y: -0.05), scale: 0.34, period: 39)
        ]
    }

    var body: some View {
        // 20 fps is indistinguishable for a wash that takes 40 seconds to
        // cross the window, and costs a third of what 60 fps does.
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                context.fill(Path(CGRect(origin: .zero, size: size)),
                             with: .color(theme.background))

                context.addFilter(.blur(radius: min(size.width, size.height) * 0.16))
                context.opacity = theme.blobOpacity

                for blob in blobs {
                    let phase = sin(t * 2 * .pi / blob.period)
                    let x = (blob.center.x + blob.drift.x * phase) * size.width
                    let y = (blob.center.y + blob.drift.y * phase) * size.height
                    let d = min(size.width, size.height) * blob.scale
                    let rect = CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d)
                    context.fill(Path(ellipseIn: rect), with: .color(blob.color))
                }
            }
        }
        .overlay {
            if theme.scrimOpacity > 0 {
                Color.black.opacity(theme.scrimOpacity)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
