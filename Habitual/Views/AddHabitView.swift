import SwiftUI
import SwiftData
import AppIntents

struct AddHabitView: View {
    // Lets us close this screen, and reach the database
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // What the user is typing / choosing right now
    @State private var name = ""
    @State private var selectedIcon = "book.fill"
    @State private var selectedColor = "#6E6BFF"
    @State private var remindMe = false
    @State private var reminderTime = NotificationManager.defaultTime()

    // The choices on offer
    private let icons = ["book.fill", "figure.run", "drop.fill", "moon.fill",
                         "dumbbell.fill", "brain.head.profile", "leaf.fill", "pencil"]
    private let colors = ["#6E6BFF", "#00E5FF", "#00D68F", "#FFD700", "#FF6B9D", "#9B6BFF"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Name field
                        GlassCard {
                            TextField("Habit name (e.g. Read 20 minutes)", text: $name)
                                .font(.headline)
                        }

                        // Icon picker
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Icon").font(.subheadline).foregroundStyle(.secondary)
                                // A grid that fits 4 per row
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                                    ForEach(icons, id: \.self) { icon in
                                        Button {
                                            selectedIcon = icon
                                        } label: {
                                            Image(systemName: icon)
                                                .font(.title2)
                                                .frame(width: 54, height: 54)
                                                .background(
                                                    Circle().fill(selectedIcon == icon
                                                                  ? Color(hex: selectedColor).opacity(0.3)
                                                                  : Color.white.opacity(0.06))
                                                )
                                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                        }
                                    }
                                }
                            }
                        }

                        // Color picker
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Color").font(.subheadline).foregroundStyle(.secondary)
                                HStack(spacing: 14) {
                                    ForEach(colors, id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 36, height: 36)
                                            // A white ring marks the chosen color
                                            .overlay(Circle().stroke(.white, lineWidth: selectedColor == hex ? 3 : 0))
                                            .onTapGesture { selectedColor = hex }
                                    }
                                }
                            }
                        }

                        // Reminder
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $remindMe.animation()) {
                                    Label("Daily reminder", systemImage: "bell.fill")
                                }
                                .tint(Theme.cyan)

                                if remindMe {
                                    DatePicker("Remind me at", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        // Can't save a habit with no name
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // Create the habit and put it in the database
    private func save() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            iconName: selectedIcon,
            colorHex: selectedColor,
            reminderTime: remindMe ? reminderTime : nil
        )
        context.insert(habit)
        try? context.save()   // save now so Siri's list of habits is up to date

        // Ask permission and schedule (if the user says no, the habit is still created, just without a reminder)
        if remindMe {
            let id = habit.id, name = habit.name, time = reminderTime
            Task {
                if await NotificationManager.requestPermission() {
                    await NotificationManager.schedule(habitID: id, name: name, time: time)
                }
            }
        }

        // Tell Siri the list of habit names has changed
        HabitualShortcuts.updateAppShortcutParameters()
        dismiss()
    }
}
