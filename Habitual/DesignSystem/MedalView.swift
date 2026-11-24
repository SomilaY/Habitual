import SwiftUI

// A round, metallic medal. Used in the gallery (small) and the unlock screen (huge).
struct MedalView: View {
    let tier: AchievementTier
    let icon: String
    var size: CGFloat = 80
    var locked: Bool = false          // locked = grey silhouette with a padlock
    var progress: Double = 0          // 0...1, shown as a ring around locked medals
    var shine: Bool = false           // moving light sweep across the surface

    // -1 = the shine band starts off the left edge. Animates to +1 (off the right edge).
    @State private var shineOffset: CGFloat = -1

    var body: some View {
        ZStack {
            if locked {
                lockedFace
            } else {
                metalFace
            }
        }
        .frame(width: size, height: size)
        // The sweeping highlight, clipped so it stays inside the circle
        .overlay {
            if shine && !locked {
                LinearGradient(colors: [.clear, .white.opacity(0.55), .clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: size * 0.45)
                    .rotationEffect(.degrees(25))
                    .offset(x: shineOffset * size)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(Circle())
        // The glow goes AFTER clipping, otherwise the clip would cut it off
        .shadow(color: locked ? .clear : tier.glow.opacity(0.55), radius: size * 0.16)
        .onAppear {
            guard shine else { return }
            withAnimation(.linear(duration: 2.4).delay(0.6).repeatForever(autoreverses: false)) {
                shineOffset = 1
            }
        }
    }

    // MARK: Unlocked: layered metal
    // Analogy: a real coin. A shiny rim, a slightly darker face inside, an engraved symbol.
    private var metalFace: some View {
        ZStack {
            // 1) The rim: conic gradient that looks like light wrapping round metal
            Circle()
                .fill(AngularGradient(colors: tier.metalColors, center: .center))

            // 2) The face
            Circle()
                .fill(LinearGradient(colors: [tier.metalColors[1], tier.metalColors[2]],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(size * 0.09)

            // 3) A thin bright edge on the face for a beveled look
            Circle()
                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                .padding(size * 0.09)

            // 4) The symbol, with a tiny light shadow underneath so it looks engraved
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(tier.iconColor)
                .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 1)
        }
    }

    // MARK: Locked: dim, with a progress ring
    private var lockedFace: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.06))
            Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)

            if progress > 0 {
                ProgressRing(progress: progress,
                             lineWidth: max(3, size * 0.05),
                             colors: [tier.glow.opacity(0.6), tier.glow])
                    .padding(size * 0.06)
            }

            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.28))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        MedalView(tier: .gold, icon: "flame.fill", size: 90, shine: true)
        MedalView(tier: .platinum, icon: "bolt.fill", size: 90, shine: true)
        MedalView(tier: .legendary, icon: "crown.fill", size: 90, shine: true)
        MedalView(tier: .gold, icon: "flame.fill", size: 90, locked: true, progress: 0.6)
    }
    .padding()
    .background(AppBackground())
}
