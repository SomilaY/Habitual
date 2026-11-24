import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var habits: [Habit]
    @Query private var unlocked: [UnlockedAchievement]
    @Environment(\.modelContext) private var context

    @State private var center = AchievementCenter()

    // A number that changes whenever habits are added/removed or anything is checked off.
    // When it changes, we re-check the achievement rules.
    private var activitySignature: Int {
        habits.count * 1_000_000 + habits.reduce(0) { $0 + $1.completions.count }
    }

    var body: some View {
        ZStack {
            TabView {
                DashboardView()
                    .tabItem { Label("Today", systemImage: "house.fill") }

                AnalyticsView()
                    .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

                HeatMapScreen()
                    .tabItem { Label("Calendar", systemImage: "calendar") }

                AchievementsView()
                    .tabItem { Label("Trophies", systemImage: "trophy.fill") }
            }
            .tint(Theme.cyan)

            // The unlock sequence floats above everything
            if let achievement = center.current {
                AchievementUnlockOverlay(
                    achievement: achievement,
                    remaining: center.remainingAfterCurrent,
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.3)) { center.dismissCurrent() }
                    },
                    onSkipAll: {
                        withAnimation(.easeInOut(duration: 0.3)) { center.skipAll() }
                    }
                )
                // .id makes SwiftUI treat each trophy as a brand-new screen,
                // so the animation script restarts for the next one in line
                .id(achievement.id)
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear { checkAchievements() }
        .onChange(of: activitySignature) { checkAchievements() }
    }

    // Look at every rule. If one is now met and not yet recorded, record it and queue the ceremony.
    private func checkAchievements() {
        let alreadyUnlocked = Set(unlocked.map { $0.achievementID })

        // Catalog order is gold -> platinum -> legendary, so the grand one comes last
        for achievement in AchievementCatalog.all {
            guard !alreadyUnlocked.contains(achievement.id) else { continue }

            if achievement.measure(habits) >= achievement.target {
                context.insert(UnlockedAchievement(achievementID: achievement.id))
                center.enqueue(achievement)
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, UnlockedAchievement.self], inMemory: true)
        .preferredColorScheme(.dark)
}
