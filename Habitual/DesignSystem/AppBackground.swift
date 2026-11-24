import SwiftUI

// A dark charcoal canvas with soft glowing orbs of color behind everything.
// Analogy: stage lighting. The glass cards sit on top and pick up the glow.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Base color changes with dark/light mode
            (colorScheme == .dark ? Theme.charcoal : Color(hex: "#F4F4FA"))
                .ignoresSafeArea()

            // Indigo glow, top left
            Circle()
                .fill(Theme.indigo.opacity(colorScheme == .dark ? 0.35 : 0.2))
                .frame(width: 320, height: 320)
                .blur(radius: 90)            // Blur turns the circle into a soft glow
                .offset(x: -120, y: -260)

            // Cyan glow, bottom right
            Circle()
                .fill(Theme.cyan.opacity(colorScheme == .dark ? 0.18 : 0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: 140, y: 300)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
