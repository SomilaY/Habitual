import Foundation

// One day in the 7-day strip: the date, and whether the habit was done.
struct DayStatus: Identifiable {
    let date: Date
    let done: Bool
    var id: Date { date }
}

extension Habit {

    // The streak lengths that unlock a milestone badge.
    static let milestones = [3, 7, 14, 30, 60, 100]

    // The next milestone you haven't reached with your CURRENT streak (nil if you've passed them all).
    var nextMilestone: Int? {
        Habit.milestones.first { $0 > currentStreak }
    }

    // How many times the habit was done in a given month.
    // offset 0 = this month, -1 = last month, and so on.
    func completions(inMonthOffset offset: Int) -> Int {
        let calendar = Calendar.current
        guard let target = calendar.date(byAdding: .month, value: offset, to: Date()) else { return 0 }
        return completions.filter {
            calendar.isDate($0.date, equalTo: target, toGranularity: .month)
        }.count
    }

    // This month minus last month. Positive = you're improving.
    var monthlyTrend: Int {
        completions(inMonthOffset: 0) - completions(inMonthOffset: -1)
    }

    // Percentage of days done since the habit was created.
    // Example: created 10 days ago (including today), done 7 times -> 70%.
    var completionRate: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: Date())
        let daysSince = (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1
        guard daysSince > 0 else { return 0 }
        return min(100, Int(Double(completions.count) / Double(daysSince) * 100))
    }

    // The last `n` days (oldest first, today last), each marked done or not.
    func lastDays(_ n: Int) -> [DayStatus] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let doneDays = Set(completions.map { $0.date })   // fast lookup

        // (0..<n).reversed() gives n-1, n-2, ... 0 = "days ago", so the oldest comes first
        return (0..<n).reversed().compactMap { daysAgo in
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            return DayStatus(date: day, done: doneDays.contains(day))
        }
    }
}
