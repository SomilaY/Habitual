import SwiftUI

// Tilts and shrinks while pressed (same as Step 2)
struct TiltPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 4 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct HabitCardView: View {
    let habit: Habit
    let onToggle: () -> Void

    private var accent: Color { Color(hex: habit.colorHex) }
    private var isDone: Bool { habit.isCompleted() }

    var body: some View {
        // Tapping the card opens the detail screen for this habit
        NavigationLink(value: habit) {
            GlassCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: habit.iconName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .strikethrough(isDone, color: .secondary)
                        Label("\(habit.currentStreak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // The check circle is its own button, separate from the card
                    Button(action: onToggle) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                .frame(width: 36, height: 36)

                            if isDone {
                                Circle()
                                    .fill(Theme.successGradient)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Theme.emerald.opacity(0.6), radius: 8)
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.black)
                            }
                        }
                        // Bigger invisible tap area so it's easy to hit
                        .contentShape(Circle().inset(by: -8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(TiltPressStyle())
        .sensoryFeedback(.success, trigger: isDone) { _, newValue in newValue }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDone)
    }
}
