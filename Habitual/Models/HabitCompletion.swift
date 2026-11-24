import Foundation
import SwiftData

// One "I did it" tick for a habit on a specific day.
// Analogy: a stamp on a loyalty card. Each stamp has a date.
@Model
final class HabitCompletion {
    var date: Date          // Stored as the START of the day, so one stamp per day
    var habit: Habit?       // Which habit this stamp belongs to

    init(date: Date, habit: Habit? = nil) {
        // startOfDay strips the time, so 9am and 9pm count as the same day
        self.date = Calendar.current.startOfDay(for: date)
        self.habit = habit
    }
}
