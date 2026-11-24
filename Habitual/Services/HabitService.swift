import Foundation
import SwiftData

// The single place that knows how to complete a habit.
// Analogy: the "ring up the sale" button on a till. The shop floor, the phone orders
// and the drive-through all use the same one, so the books always agree.
@MainActor
enum HabitService {

    // Find a habit by its id
    static func fetch(_ id: UUID, in context: ModelContext) -> Habit? {
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    // Mark a habit done for today. If it's already done, nothing happens (safe to call twice).
    // Returns the habit so callers can say something friendly like "5 day streak!"
    @discardableResult
    static func complete(habitID: UUID, in context: ModelContext) -> Habit? {
        guard let habit = fetch(habitID, in: context) else { return nil }

        if !habit.isCompleted() {
            context.insert(HabitCompletion(date: Date(), habit: habit))
            try? context.save()      // save right away, since the app may not be open to autosave
        }
        return habit
    }
}
