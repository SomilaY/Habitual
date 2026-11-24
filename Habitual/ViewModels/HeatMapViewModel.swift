import Foundation
import Observation

@Observable
final class HeatMapViewModel {

    // Any date inside the month currently being shown
    var displayedMonth = Date()
    // The day the user tapped (nil = nothing selected)
    var selectedDate: Date?

    private let calendar = Calendar.current

    // MARK: - Month info

    // The first moment of the displayed month. Also used as an "identity" for the grid,
    // so SwiftUI knows when it's a brand-new month and replays the pop-in animation.
    var monthStart: Date {
        calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
    }

    // e.g. "November 2026"
    var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    // Don't let the user browse into the future
    var canGoForward: Bool {
        let thisMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return monthStart < thisMonth
    }

    // Go back (-1) or forward (+1) one month
    func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
            selectedDate = nil      // a selection from another month makes no sense
        }
    }

    // MARK: - Grid layout

    // Weekday letters in the user's local order (Sunday-first or Monday-first)
    var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    // One entry per grid box. `nil` = empty box before the 1st of the month.
    // Example: if the 1st lands on a Wednesday (Sunday-first), we add 3 empty boxes first.
    var gridDays: [Date?] {
        let start = monthStart
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let weekdayOfFirst = calendar.component(.weekday, from: start)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        var result: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            result.append(calendar.date(byAdding: .day, value: offset, to: start))
        }
        return result
    }

    // MARK: - Data

    // Tally: for each day, how many habits were completed.
    // Analogy: a scoreboard keyed by date.
    func counts(for habits: [Habit]) -> [Date: Int] {
        var result: [Date: Int] = [:]
        for habit in habits {
            for completion in habit.completions {
                result[completion.date, default: 0] += 1
            }
        }
        return result
    }

    // 0.0 = nothing done, 1.0 = every habit done
    func intensity(on day: Date, counts: [Date: Int], habitCount: Int) -> Double {
        guard habitCount > 0 else { return 0 }
        let done = counts[day] ?? 0
        return min(1, Double(done) / Double(habitCount))
    }

    func isFuture(_ day: Date) -> Bool {
        day > calendar.startOfDay(for: Date())
    }

    func isToday(_ day: Date) -> Bool {
        calendar.isDateInToday(day)
    }
}
