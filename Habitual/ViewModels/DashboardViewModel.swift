import Foundation
import SwiftData
import Observation
import AppIntents

// @Observable means: whenever something in here changes,
// any screen using it refreshes automatically.
@Observable
final class DashboardViewModel {

    // MARK: - Greeting
    // Changes with the time of day.
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Night owl mode"
        }
    }

    // MARK: - Today's progress
    // How many habits are done today, as a number from 0.0 to 1.0.
    func todayProgress(for habits: [Habit]) -> Double {
        guard !habits.isEmpty else { return 0 }   // avoid dividing by zero
        let done = habits.filter { $0.isCompleted() }.count
        return Double(done) / Double(habits.count)
    }

    // How many are done, e.g. 3 (used for "3 of 5 done")
    func completedCount(for habits: [Habit]) -> Int {
        habits.filter { $0.isCompleted() }.count
    }

    // MARK: - Streak summary
    // The best running streak among all habits. Shown in the hero card.
    func bestCurrentStreak(for habits: [Habit]) -> Int {
        habits.map { $0.currentStreak }.max() ?? 0
    }

    // MARK: - Weekly consistency
    // Out of the last 7 days, what % of possible check-ins did you complete?
    // Example: 2 habits x 7 days = 14 possible. You did 10 -> 71%.
    func weeklyConsistency(for habits: [Habit]) -> Int {
        guard !habits.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // The start of the 7-day window (6 days back + today = 7 days)
        guard let windowStart = calendar.date(byAdding: .day, value: -6, to: today) else { return 0 }

        var done = 0
        for habit in habits {
            // Count this habit's completions that fall inside the window
            done += habit.completions.filter { $0.date >= windowStart && $0.date <= today }.count
        }

        let possible = habits.count * 7
        return Int((Double(done) / Double(possible)) * 100)
    }

    // MARK: - Actions
    // Tap a habit: if it's done today, un-do it. If not, mark it done.
    // Analogy: tapping a light switch.
    func toggleToday(_ habit: Habit, context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())

        if let existing = habit.completions.first(where: { $0.date == today }) {
            context.delete(existing)                       // switch off
        } else {
            let completion = HabitCompletion(date: today, habit: habit)
            context.insert(completion)                     // switch on
        }
    }

    // Delete a habit (its completions go too, thanks to cascade from Step 1)
    func delete(_ habit: Habit, context: ModelContext) {
        NotificationManager.cancel(habitID: habit.id)   // no reminders for a habit that no longer exists
        context.delete(habit)
        try? context.save()
        HabitualShortcuts.updateAppShortcutParameters()
    }
}
