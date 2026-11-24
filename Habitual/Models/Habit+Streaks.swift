import Foundation

extension Habit {

    // Is the habit done on a given day?
    func isCompleted(on day: Date = Date()) -> Bool {
        let target = Calendar.current.startOfDay(for: day)
        return completions.contains { $0.date == target }
    }

    // Current streak = how many days in a row, ending today (or yesterday).
    // Analogy: a chain of paper clips. Miss a day and the chain snaps.
    var currentStreak: Int {
        let calendar = Calendar.current
        let completedDays = Set(completions.map { $0.date })   // Set = fast lookup
        var day = calendar.startOfDay(for: Date())

        // If today isn't done yet, the streak is still alive from yesterday.
        if !completedDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        // Walk backwards one day at a time until we hit a gap
        var streak = 0
        while completedDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    // Longest streak ever, used later for achievements and analytics
    var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDays = completions.map { $0.date }.sorted()
        guard !sortedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1..<sortedDays.count {
            // Was this day exactly 1 day after the previous one?
            let expectedNext = calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1])
            if sortedDays[i] == expectedNext {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1   // chain snapped, restart
            }
        }
        return longest
    }
}
