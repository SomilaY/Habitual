import Foundation
import SwiftData

#if DEBUG   // This whole file is compiled out of release builds
enum SampleData {

    // For each habit, randomly mark ~65% of the last `days` days as done.
    static func fillHistory(for habits: [Habit], days: Int = 90, context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for habit in habits {
            // Pretend the habit was created `days` ago, so "success rate" stays sensible
            if let oldest = calendar.date(byAdding: .day, value: -days, to: today), oldest < habit.createdAt {
                habit.createdAt = oldest
            }

            // daysAgo starts at 1 so today stays untouched (you can still test completing it)
            for daysAgo in 1...days {
                guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

                // Roll the dice, and skip days that already have a record
                if Double.random(in: 0...1) < 0.65 && !habit.isCompleted(on: day) {
                    context.insert(HabitCompletion(date: day, habit: habit))
                }
            }
        }
    }
}
#endif
