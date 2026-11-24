import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Good evening")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Your growth, visualized")
                            .font(.title2.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GlassCard {
                    Label("12 day streak", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.primaryGradient)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
