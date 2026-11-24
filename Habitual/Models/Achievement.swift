import SwiftUI

// MARK: - Tiers
// Rarer tier = fancier medal.
enum AchievementTier: Int, CaseIterable, Comparable {
    case gold, platinum, legendary

    static func < (lhs: AchievementTier, rhs: AchievementTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .gold:      return "Gold"
        case .platinum:  return "Platinum"
        case .legendary: return "Legendary"
        }
    }

    // The colors of the metal. The first and last are identical so the circular
    // (angular) gradient joins up seamlessly, like a real metal rim catching light.
    var metalColors: [Color] {
        switch self {
        case .gold:
            return [Color(hex: "#FFF1A8"), Color(hex: "#FFD700"), Color(hex: "#B8860B"),
                    Color(hex: "#FFD700"), Color(hex: "#FFF1A8")]
        case .platinum:
            return [Color(hex: "#F5F7FA"), Color(hex: "#C9D1DB"), Color(hex: "#8E9AAB"),
                    Color(hex: "#C9D1DB"), Color(hex: "#F5F7FA")]
        case .legendary:
            // Iridescent: shifts through the whole brand palette
            return [Theme.cyan, Theme.indigo, Theme.violet, Color(hex: "#FF6BD6"),
                    Theme.gold, Theme.emerald, Theme.cyan]
        }
    }

    // Soft glow color around the medal
    var glow: Color {
        switch self {
        case .gold:      return Theme.gold
        case .platinum:  return Color(hex: "#BFD4FF")
        case .legendary: return Theme.violet
        }
    }

    // Icon color on the medal face (dark "engraved" on metal, white on the legendary one)
    var iconColor: Color {
        self == .legendary ? .white : Color.black.opacity(0.55)
    }
}

// MARK: - One achievement
struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String                  // SF Symbol name
    let tier: AchievementTier
    let target: Int                   // the number you need to reach
    let measure: ([Habit]) -> Int     // how to measure your current number from your habits
}

// MARK: - The catalog (the rulebook)
// Each rule = "measure something, unlock when it reaches the target".
// Analogy: a loyalty scheme. "Buy 10 coffees, get a free one": measure = coffees bought, target = 10.
enum AchievementCatalog {

    static let all: [Achievement] = [
        // ---- Gold ----
        Achievement(id: "first_step", title: "First Step",
                    detail: "Complete a habit for the first time.",
                    icon: "figure.walk", tier: .gold, target: 1, measure: totalCompletions),
        Achievement(id: "week_warrior", title: "Week Warrior",
                    detail: "Reach a 7-day streak.",
                    icon: "flame.fill", tier: .gold, target: 7, measure: bestStreak),
        Achievement(id: "habit_builder", title: "Habit Builder",
                    detail: "Create 3 habits.",
                    icon: "square.stack.3d.up.fill", tier: .gold, target: 3, measure: habitCount),
        Achievement(id: "flawless_day", title: "Flawless Day",
                    detail: "Complete every habit in one day (needs 2+ habits).",
                    icon: "sparkles", tier: .gold, target: 1, measure: perfectDays),

        // ---- Platinum ----
        Achievement(id: "fortnight_focus", title: "Fortnight Focus",
                    detail: "Reach a 14-day streak.",
                    icon: "bolt.fill", tier: .platinum, target: 14, measure: bestStreak),
        Achievement(id: "monthly_master", title: "Monthly Master",
                    detail: "Reach a 30-day streak.",
                    icon: "calendar.badge.checkmark", tier: .platinum, target: 30, measure: bestStreak),
        Achievement(id: "century_club", title: "Century Club",
                    detail: "Log 100 completions.",
                    icon: "rosette", tier: .platinum, target: 100, measure: totalCompletions),

        // ---- Legendary ----
        Achievement(id: "unstoppable", title: "Unstoppable",
                    detail: "Reach a 60-day streak.",
                    icon: "crown.fill", tier: .legendary, target: 60, measure: bestStreak),
        Achievement(id: "centurion", title: "Centurion",
                    detail: "Reach a 100-day streak.",
                    icon: "trophy.fill", tier: .legendary, target: 100, measure: bestStreak),
        Achievement(id: "renaissance", title: "Renaissance",
                    detail: "Keep 3 habits on 7+ day streaks at the same time.",
                    icon: "infinity", tier: .legendary, target: 3, measure: habitsOnFire)
    ]

    // MARK: Measuring functions

    private static func totalCompletions(_ habits: [Habit]) -> Int {
        habits.reduce(0) { $0 + $1.completions.count }
    }

    private static func bestStreak(_ habits: [Habit]) -> Int {
        habits.map { $0.longestStreak }.max() ?? 0
    }

    private static func habitCount(_ habits: [Habit]) -> Int {
        habits.count
    }

    // How many days did you complete EVERY habit? (Only counts if you have 2+ habits.)
    private static func perfectDays(_ habits: [Habit]) -> Int {
        guard habits.count >= 2 else { return 0 }
        var counts: [Date: Int] = [:]
        for habit in habits {
            for completion in habit.completions {
                counts[completion.date, default: 0] += 1
            }
        }
        return counts.values.filter { $0 == habits.count }.count
    }

    // How many habits currently have a 7+ day streak?
    private static func habitsOnFire(_ habits: [Habit]) -> Int {
        habits.filter { $0.currentStreak >= 7 }.count
    }
}
