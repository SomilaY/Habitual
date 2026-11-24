import Foundation
import Observation

// The time windows the user can pick between.
// rawValue = how many days the window covers.
enum AnalyticsRange: Int, CaseIterable, Identifiable {
    case week = 7
    case month = 30
    case quarter = 90

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .week:    return "7D"
        case .month:   return "30D"
        case .quarter: return "90D"
        }
    }
}

// One dot on a line chart: a date and a number.
struct DayPoint: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

// One bar in the "completion rates" chart.
struct HabitRate: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let rate: Double          // 0...100
}

// The four headline numbers.
struct AnalyticsSummary {
    var perfectDays = 0       // days when EVERY habit was done
    var bestStreak = 0
    var totalCheckIns = 0
    var averageCompletion = 0.0
}

@Observable
final class AnalyticsViewModel {

    // The selected window (the screen binds a segmented picker to this)
    var range: AnalyticsRange = .month

    private let calendar = Calendar.current

    private var today: Date { calendar.startOfDay(for: Date()) }

    // First day of the window. A 7-day window = today and the 6 days before it.
    private var rangeStart: Date {
        calendar.date(byAdding: .day, value: -(range.rawValue - 1), to: today) ?? today
    }

    // Every day in the window, oldest first.
    private func days() -> [Date] {
        (0..<range.rawValue).compactMap { calendar.date(byAdding: .day, value: $0, to: rangeStart) }
    }

    // MARK: - Building blocks

    // Scoreboard: date -> how many habits were completed that day
    private func tally(_ habits: [Habit]) -> [Date: Int] {
        var result: [Date: Int] = [:]
        for habit in habits {
            for completion in habit.completions {
                result[completion.date, default: 0] += 1
            }
        }
        return result
    }

    // % of habits done on a given day (0...100)
    private func rate(on day: Date, counts: [Date: Int], habitCount: Int) -> Double {
        guard habitCount > 0 else { return 0 }
        return Double(counts[day] ?? 0) / Double(habitCount) * 100
    }

    // MARK: - Chart data

    // The raw ups and downs: one point per day.
    func dailyRates(_ habits: [Habit]) -> [DayPoint] {
        let counts = tally(habits)
        return days().map { day in
            DayPoint(date: day, value: rate(on: day, counts: counts, habitCount: habits.count))
        }
    }

    // The smoothed line: each point = average of that day and the 6 days before it.
    // Analogy: instead of judging yourself by one bad day, you look at the whole week.
    func trendPoints(_ habits: [Habit]) -> [DayPoint] {
        let counts = tally(habits)
        return days().map { day in
            // That day plus the six days before it (this can reach before the window start, which is fine)
            let window = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: day) }
            let total = window
                .map { rate(on: $0, counts: counts, habitCount: habits.count) }
                .reduce(0, +)
            return DayPoint(date: day, value: total / 7)
        }
    }

    // For each day: the longest running streak among all habits as of that day.
    func streakPoints(_ habits: [Habit]) -> [DayPoint] {
        let rangeDays = days()
        var best = Array(repeating: 0.0, count: rangeDays.count)

        for habit in habits {
            let done = Set(habit.completions.map { $0.date })

            // How long was the chain already running just before the window began?
            var running = 0
            var cursor = calendar.date(byAdding: .day, value: -1, to: rangeStart)
            while let day = cursor, done.contains(day) {
                running += 1
                cursor = calendar.date(byAdding: .day, value: -1, to: day)
            }

            // Walk forward through the window, growing or snapping the chain
            for (index, day) in rangeDays.enumerated() {
                if done.contains(day) {
                    running += 1
                } else if day != today {
                    running = 0           // missed a past day: chain snaps
                }
                // (if it's today and not done yet, the chain is still alive, so we keep it)
                best[index] = max(best[index], Double(running))
            }
        }

        return zip(rangeDays, best).map { DayPoint(date: $0, value: $1) }
    }

    // One bar per habit: % of days done within the window.
    // Habits created mid-window are only judged from the day they were created.
    func habitRates(_ habits: [Habit]) -> [HabitRate] {
        habits.map { habit in
            let start = max(calendar.startOfDay(for: habit.createdAt), rangeStart)
            let span = (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1
            let done = habit.completions.filter { $0.date >= start && $0.date <= today }.count
            let percent = span > 0 ? min(100, Double(done) / Double(span) * 100) : 0
            return HabitRate(id: habit.id, name: habit.name, colorHex: habit.colorHex, rate: percent)
        }
        .sorted { $0.rate > $1.rate }       // best habit on top
    }

    // The four headline numbers
    func summary(_ habits: [Habit]) -> AnalyticsSummary {
        guard !habits.isEmpty else { return AnalyticsSummary() }

        let counts = tally(habits)
        let rangeDays = days()

        var result = AnalyticsSummary()
        result.perfectDays = rangeDays.filter { counts[$0] == habits.count }.count
        result.totalCheckIns = rangeDays.reduce(0) { $0 + (counts[$1] ?? 0) }
        result.bestStreak = Int(streakPoints(habits).map(\.value).max() ?? 0)
        result.averageCompletion = dailyRates(habits).map(\.value).reduce(0, +) / Double(rangeDays.count)
        return result
    }
}
