import AppIntents
import SwiftData

// MARK: - Teaching Siri what a "habit" is
struct HabitEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    static let defaultQuery = HabitEntityQuery()

    var id: UUID
    var name: String

    // How this habit appears in Siri/Shortcuts pickers
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

// The "phone book" Siri uses to look habits up
struct HabitEntityQuery: EntityQuery {

    // "Find the habits with these ids"
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        let all = try AppDatabase.container.mainContext.fetch(FetchDescriptor<Habit>())
        return all
            .filter { identifiers.contains($0.id) }
            .map { HabitEntity(id: $0.id, name: $0.name) }
    }

    // "Which habits can I offer as choices?" Powers the picker and spoken suggestions.
    @MainActor
    func suggestedEntities() async throws -> [HabitEntity] {
        let all = try AppDatabase.container.mainContext.fetch(
            FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        )
        return all.map { HabitEntity(id: $0.id, name: $0.name) }
    }
}

// MARK: - Action 1: complete a habit
struct CompleteHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Habit"
    static let description = IntentDescription("Marks one of your habits as done for today.")

    // The "blank" Siri fills in: which habit?
    @Parameter(title: "Habit")
    var habit: HabitEntity

    // The sentence shown in the Shortcuts app
    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$habit)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppDatabase.container.mainContext

        guard let done = HabitService.complete(habitID: habit.id, in: context) else {
            return .result(dialog: "I couldn't find that habit.")
        }
        return .result(dialog: "Done! \(done.name) is checked off. That's a \(done.currentStreak) day streak.")
    }
}

// MARK: - Action 2: how am I doing today?
struct TodayProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Progress"
    static let description = IntentDescription("Tells you how many habits you've completed today.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let habits = try AppDatabase.container.mainContext.fetch(FetchDescriptor<Habit>())

        guard !habits.isEmpty else {
            return .result(dialog: "You haven't added any habits yet.")
        }

        let remaining = habits.filter { !$0.isCompleted() }

        if remaining.isEmpty {
            return .result(dialog: "All \(habits.count) habits are done today. Flawless.")
        }

        let names = remaining.map(\.name).joined(separator: ", ")
        let message = "\(habits.count - remaining.count) of \(habits.count) done today. Still to go: \(names)."
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - The spoken phrases
// Every phrase MUST include the app's name, so Siri knows which app you mean.
struct HabitualShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteHabitIntent(),
            phrases: [
                "Complete \(\.$habit) in \(.applicationName)",
                "Mark \(\.$habit) done in \(.applicationName)"
            ],
            shortTitle: "Complete Habit",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: TodayProgressIntent(),
            phrases: [
                "How am I doing in \(.applicationName)",
                "My progress in \(.applicationName)"
            ],
            shortTitle: "Today's Progress",
            systemImageName: "chart.pie.fill"
        )
    }
}
