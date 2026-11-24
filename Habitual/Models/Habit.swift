import Foundation
import SwiftData

// A Habit is one thing the user wants to do regularly (e.g. "Read 20 minutes").
// @Model tells SwiftData to save this automatically.
// Analogy: each Habit is a row in a spreadsheet that the app keeps for you.
@Model
final class Habit {
    var id: UUID
    var name: String
    var iconName: String          // SF Symbol name, e.g. "book.fill"
    var colorHex: String          // Each habit gets its own accent color
    var createdAt: Date
    var reminderTime: Date?       // Optional: nil means no reminder

    // One habit has many completion records.
    // cascade = if you delete the habit, its completions are deleted too.
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(name: String,
         iconName: String = "star.fill",
         colorHex: String = "#6E6BFF",
         reminderTime: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = Date()
        self.reminderTime = reminderTime
    }
}
