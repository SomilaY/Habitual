import SwiftUI

struct AchievementUnlockOverlay: View {
    let achievement: Achievement
    var remaining: Int = 0                 // trophies still waiting after this one
    let onContinue: () -> Void
    var onSkipAll: (() -> Void)? = nil

    @State private var stage = 0           // 0 = nothing yet ... 3 = everything visible
    @State private var showBurst = false

    private var tier: AchievementTier { achievement.tier }

    var body: some View {
        ZStack {
            // Dark backdrop with a colored glow that grows behind the medal
            Color.black.opacity(0.82).ignoresSafeArea()
            RadialGradient(colors: [tier.glow.opacity(stage >= 1 ? 0.45 : 0), .clear],
                           center: .center, startRadius: 10, endRadius: 340)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // The medal + particles
                ZStack {
                    if showBurst {
                        // Legendary gets a bigger explosion
                        CelebrationBurst(accent: tier.glow)
                            .scaleEffect(tier == .legendary ? 2.4 : 1.7)
                    }

                    MedalView(tier: tier, icon: achievement.icon, size: 190, shine: true)
                        .scaleEffect(stage >= 1 ? 1 : 0.1)
                        // Spins around like a flipped coin
                        .rotation3DEffect(.degrees(stage >= 1 ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                        .opacity(stage >= 1 ? 1 : 0)
                }
                .frame(height: 230)

                // The text
                VStack(spacing: 10) {
                    Text("\(tier.title.uppercased()) ACHIEVEMENT")
                        .font(.caption.weight(.heavy))
                        .tracking(3)                     // spaced-out letters feel premium
                        .foregroundStyle(tier.glow)

                    Text(achievement.title)
                        .font(.largeTitle.bold())

                    Text(achievement.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(stage >= 2 ? 1 : 0)
                .offset(y: stage >= 2 ? 0 : 20)

                Spacer()

                // Buttons appear last
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text(remaining > 0 ? "Next" : "Continue")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Theme.primaryGradient))
                    }

                    if remaining > 0, let onSkipAll {
                        Button("Skip all (\(remaining) more)", action: onSkipAll)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                .opacity(stage >= 3 ? 1 : 0)
            }
        }
        // Haptics: a heavy thump when the medal lands, a "success" buzz when the title appears
        .sensoryFeedback(trigger: stage) { _, newStage in
            switch newStage {
            case 1:  return .impact(weight: .heavy)
            case 2:  return .success
            default: return nil
            }
        }
        // .task runs once when the overlay appears: the stage show script
        .task {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.6)) { stage = 1 }
            try? await Task.sleep(for: .milliseconds(700))

            showBurst = true
            withAnimation(.easeOut(duration: 0.6)) { stage = 2 }
            try? await Task.sleep(for: .milliseconds(600))

            withAnimation(.easeOut(duration: 0.4)) { stage = 3 }
        }
    }
}
