import SwiftUI
import SwiftData

struct ReminderCard: View {
    // @Bindable lets us change the habit's properties directly, and the database saves them
    @Bindable var habit: Habit

    @State private var showDeniedAlert = false
    @Environment(\.openURL) private var openURL

    // Toggle: ON when the habit has a reminder time
    private var isOn: Binding<Bool> {
        Binding(
            get: { habit.reminderTime != nil },
            set: { setReminder(enabled: $0) }
        )
    }

    // Time picker: reads/writes the habit's reminder time
    private var time: Binding<Date> {
        Binding(
            get: { habit.reminderTime ?? NotificationManager.defaultTime() },
            set: { newTime in
                habit.reminderTime = newTime
                reschedule()
            }
        )
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: isOn) {
                    Label("Daily reminder", systemImage: "bell.fill")
                        .font(.headline)
                }
                .tint(Theme.cyan)

                if habit.reminderTime != nil {
                    DatePicker("Remind me at", selection: time, displayedComponents: .hourAndMinute)

                    #if DEBUG
                    // Fires a notification in 5 seconds. Background the app to see it on the lock screen.
                    Button("Send test notification (5s)") {
                        let id = habit.id, name = habit.name
                        Task { await NotificationManager.scheduleTest(habitID: id, name: name) }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    #endif
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: habit.reminderTime != nil)
        // If the user previously said "Don't Allow", iOS never asks again. Point them to Settings.
        .alert("Notifications are off", isPresented: $showDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Turn on notifications for Habitual in Settings to get reminders.")
        }
    }

    private func setReminder(enabled: Bool) {
        if enabled {
            Task { @MainActor in
                if await NotificationManager.requestPermission() {
                    habit.reminderTime = NotificationManager.defaultTime()
                    reschedule()
                } else {
                    showDeniedAlert = true
                }
            }
        } else {
            habit.reminderTime = nil
            NotificationManager.cancel(habitID: habit.id)
        }
    }

    private func reschedule() {
        guard let time = habit.reminderTime else { return }
        let id = habit.id, name = habit.name
        Task { await NotificationManager.schedule(habitID: id, name: name, time: time) }
    }
}
