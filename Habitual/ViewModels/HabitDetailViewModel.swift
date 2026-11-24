import Foundation
import SwiftData
import Observation

@Observable
final class HabitDetailViewModel {
    let habit: Habit

    // When true, the screen shows the confetti-style burst.
    var showCelebration = false

    init(habit: Habit) {
        self.habit = habit
    }

    // Tap the big button: mark done, or undo.
    // Only the "mark done" direction triggers the celebration.
    func toggleToday(context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())

        if let existing = habit.completions.first(where: { $0.date == today }) {
            context.delete(existing)               // undo
        } else {
            context.insert(HabitCompletion(date: today, habit: habit))
            celebrate()                            // done!
        }
    }

    // Show the burst for ~1.2 seconds, then remove it.
    private func celebrate() {
        showCelebration = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            showCelebration = false
        }
    }
}
