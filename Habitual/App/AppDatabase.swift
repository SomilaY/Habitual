import SwiftData

enum AppDatabase {
    // `static let` = created once, then shared by everything (the app, Siri, notification buttons).
    static let container: ModelContainer = {
        // The list of "tables" in our database
        let schema = Schema([Habit.self, HabitCompletion.self, UnlockedAchievement.self])
        let configuration = ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // If the database can't open, the app can't work at all, so stop loudly.
            fatalError("Could not create the database: \(error)")
        }
    }()
}
