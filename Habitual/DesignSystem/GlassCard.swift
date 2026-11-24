import SwiftUI

// A reusable frosted-glass container. Wrap any content in it.
// Analogy: a frosted shower door. You can see light and color through it,
// but the details are soft, and it has a thin bright edge.
struct GlassCard<Content: View>: View {
    // The content placed inside the card (passed in when you use it)
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(Theme.padding)
            .background(
                // .ultraThinMaterial is Apple's built-in blur effect
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                // A thin gradient border that fades, like light catching glass edges
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            // Soft shadow lifts the card off the background
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GlassCard {
            Text("Hello, glass")
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
