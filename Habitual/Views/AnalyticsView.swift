import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var viewModel = AnalyticsViewModel()

    // 0 = charts hidden, 1 = fully drawn. Animating this from 0 to 1 plays the whole intro.
    @State private var drawProgress: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // 7D / 30D / 90D switch
                        Picker("Range", selection: $viewModel.range) {
                            ForEach(AnalyticsRange.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        if habits.isEmpty {
                            GlassCard {
                                Text("Add a few habits and your analytics will appear here.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            content
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { replay() }
            // Switching the range replays the draw-on animation
            .onChange(of: viewModel.range) { replay() }
        }
    }

    // All the cards. Each one is computed fresh from the habits.
    private var content: some View {
        let summary = viewModel.summary(habits)

        return VStack(spacing: 20) {
            // Four headline numbers in a 2x2 grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                MetricTile(title: "Perfect days",
                           value: Double(summary.perfectDays) * drawProgress,
                           icon: "sparkles", tint: Theme.gold)
                MetricTile(title: "Best streak",
                           value: Double(summary.bestStreak) * drawProgress,
                           suffix: "days", icon: "flame.fill", tint: Theme.emerald)
                MetricTile(title: "Check-ins",
                           value: Double(summary.totalCheckIns) * drawProgress,
                           icon: "checkmark.seal.fill", tint: Theme.cyan)
                MetricTile(title: "Avg completion",
                           value: summary.averageCompletion * drawProgress,
                           suffix: "%", icon: "chart.bar.fill", tint: Theme.indigo)
            }

            ConsistencyCard(daily: viewModel.dailyRates(habits),
                            trend: viewModel.trendPoints(habits),
                            progress: drawProgress)

            StreakCard(points: viewModel.streakPoints(habits),
                       progress: drawProgress)

            RatesCard(rates: viewModel.habitRates(habits),
                      progress: drawProgress)
        }
    }

    // Reset to 0, wait a beat, then animate to 1.
    // (The tiny wait matters: without it SwiftUI merges both changes and nothing animates.)
    private func replay() {
        drawProgress = 0
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.easeInOut(duration: 1.2)) {
                drawProgress = 1
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
        .preferredColorScheme(.dark)
}
