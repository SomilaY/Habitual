import SwiftUI

struct ProgressRing: View {
    var progress: Double              // 0.0 (empty) to 1.0 (full)
    var lineWidth: CGFloat = 14
    var colors: [Color] = [Theme.indigo, Theme.violet, Theme.cyan]

    var body: some View {
        ZStack {
            // The "track": a faint full circle behind the colored arc
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            // The colored arc. trim(from:to:) draws only part of the circle.
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: colors, center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round) // round ends look premium
                )
                .rotationEffect(.degrees(-90))   // start at 12 o'clock, not 3 o'clock
                .shadow(color: colors.last?.opacity(0.5) ?? .clear, radius: 8) // soft glow
        }
        // A spring makes the ring bounce slightly as it settles, rather than sliding linearly.
        .animation(.spring(response: 0.8, dampingFraction: 0.75), value: progress)
    }
}

#Preview {
    ZStack {
        AppBackground()
        ProgressRing(progress: 0.7)
            .frame(width: 160, height: 160)
    }
}
